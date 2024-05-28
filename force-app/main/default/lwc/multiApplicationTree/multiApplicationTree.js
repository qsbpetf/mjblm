/**
 * Created by peterfriberg on 2024-05-15.
 */

import { LightningElement, track, api } from 'lwc';
import apexGetAllApplications from '@salesforce/apex/ApplicationFormsController.getAllApplications';
import AcceptMultipleApplicationsModal from 'c/acceptMultipleApplicationsModal';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class MultiApplicationTree extends LightningElement {
    @api flowApiName = '';
    @api pageSize = 15;

    @track selectedRows = [];
    @track pageSelectedRows = [];
    @track selectedRowsCount = 0;
    @track applications = [];
    @track isLoading = true;

    @track data = [];
    @track recordById = {};
    @track pageData = [];
    @track currentExpandedRows = [];

    @track totalRequested = 0;
    @track totalGranted = 0;
    @track _totalRequested = 0;
    @track _totalGranted = 0;

    @track recId;
    @track childRecordId = '';
    @track childRecordObjectApiName = '';
    @track childRecordFlowApiName = this.flowApiName;
    @track isModalOpen = false; // Used to control the visibility of modal
    @track disabledButton = true;

    @track currentPage = 1;
    @track totalPages = 1;
    @track isFirstPage = true;
    @track isLastPage = true;
    @track recordCount = 0;
    @track skip = 0;

    COLUMNS = [
        {
            type: 'url',
            fieldName: 'url',
            label: 'Ansökan',
            typeAttributes: {
                label: { fieldName: 'name' }
            },
            initialWidth: 180
        },
        {
            type: 'text',
            fieldName: 'firstName',
            label: 'Förnamn',
        },
        {
            type: 'text',
            fieldName: 'lastName',
            label: 'Efternamn',
        },
        {
            type: 'text',
            fieldName: 'birthYear',
            label: 'Födelseår',
        },
        {
            type: 'text',
            fieldName: 'category',
            label: 'Kategori',
        },
        {
            type: 'text',
            fieldName: 'subCategory',
            label: 'Underkategori',
        },
        {
            type: 'currency',
            fieldName: 'request',
            label: 'Begärt',
        },
        {
            type: 'currency',
            fieldName: 'granted',
            label: 'Beviljat',
        },
        {
            type: 'text',
            fieldName: 'paymentType',
            label: 'Betalningstyp',
        },
        {
            type: 'text',
            fieldName: 'description',
            label: 'Beskrivning'
        },
        {
            type: 'button',
            label: 'Detaljer',
            typeAttributes: {
                iconName: { fieldName: 'icon' },
                name: 'edit_details',
                label: { fieldName: 'action' },
                title: { fieldName: 'action' },
                variant: 'base'
            },
            initialWidth: 120
        },
        {
            type: 'icon',
            label: 'Färdigbeh.',
            cellAttributes: {
                alternativeText: { fieldName: 'statusIcon' },
                iconName: { fieldName: 'statusIcon' },
                size: 'x-small'
            },
        }
    ];

    connectedCallback() {
        this.loadApplications();
    }

    get cardTitle() {
        return 'Ansökningar: ' + this.applications.length;
    }

    get approveButtonLabel() {
        return 'Godkänn ' + this.selectedRowsCount + ' ansökningar';
    }

    handleRowSelection(event) {
        const eventAction = event.detail.config.action;
        const selectedRowId = event.detail.config.value;

        if (eventAction === 'rowSelect') {
            let selectedRow = this.findSelectedRow(event, selectedRowId);
            if (selectedRow.level > 1) {
                this.selectedRows = this.filterSelection(event, selectedRowId)
                alert('Du kan bara välja ansökningsrad(er)');
            } else if (selectedRow.level === 1) {
                if (!this.validateApp(selectedRow)) {
                    this.selectedRows = [
                        ...new Set([
                            ...this.selectedRows,
                            ...this.keepSelection(event)
                        ])
                    ];
                    alert('Du kan bara välja färdigbehandlade ansökningar');
                }
                else {
                    this.selectedRows = [
                        ...new Set([
                            ...this.selectedRows,
                            ...this.keepSelection(event)
                        ])
                    ];
                }
            }
        } else if (eventAction === 'selectAllRows') {
            this.selectedRows = [
                ...new Set([
                    ...this.selectedRows,
                    ...this.keepSelection(event)
                ])
            ];
        }
        else if (eventAction === 'deselectAllRows') {
            // Get IDs from pageData
            const pageDataIds = this.pageData.map(data => data.id);
            // Remove IDs found in pageData from selectedRows
            this.selectedRows = this.selectedRows.filter(id => !pageDataIds.includes(id));
            // Clear pageSelectedRows
            this.pageSelectedRows = [];
        }
        else if (eventAction === 'rowDeselect') {
            // Get the id of the deselected row
            const deselectedRowId = event.detail.config.value;

            // Remove the deselected row from this.selectedRows
            this.selectedRows = this.selectedRows.filter(id => id !== deselectedRowId);
        }
        this.pageSelectedRows = this.selectedRows.filter(row => this.pageData.find(data => data.id === row));
        this.disabledButton = (this.selectedRows.length === 0);
        this.selectedRowsCount = this.selectedRows.length;
    }

    validateApp(row) {
        console.log(JSON.stringify(row))
        return (row.level === 1) && (row.grantedTotalCount === row.grantedDefinedCount) && row.allChildrenValidated;
    }

    findSelectedRow(event, selectedRowId) {
        return event.detail.selectedRows.find(row => row.id === selectedRowId);
    }

    filterSelection(event, selectedRowId) {
        return event.detail.selectedRows
            .filter(row => row.id !== selectedRowId)
            .map(row => row.id);
    }

    keepSelection(event) {
        return event.detail.selectedRows
            .filter(row => this.validateApp(row))
            .map(row => row.id);
    }

    // open accept multiple applications modal
    async handleApproveClick(){

        let grantToApprove = 0;
        let requestedAmount = 0;
        this.selectedRows.forEach(appId => {
            const selectedApp = this.data.find(app => app.id === appId);
            requestedAmount += selectedApp.request;
            grantToApprove += selectedApp.granted;
        });

        console.log(grantToApprove);
        console.log(requestedAmount);

        const result = await AcceptMultipleApplicationsModal.open({
            size: 'medium',
            description: 'Approve',
            recordIds: `${this.selectedRows}`,
            grantToApprove: grantToApprove,
            requestedAmount: requestedAmount
        });

        if (result === 'ok') {
            window.location.reload();
        } else if (result === 'error') {
            this.showNotification('Error', 'Error occurred when updating the form.', 'error');
        }
    }

    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    handleRowClick(event) {
        this.selectedItem = event.detail.row;
        const action = event.detail.action;
        console.log('Action: ', action.label);
        console.log('Selected Row: ', this.selectedItem, JSON.stringify(this.selectedItem, null, 2));
        this.content = JSON.stringify(this.selectedItem, null, 2);

        if (this.selectedItem.level === 3) {
            // Open Bidragsrader__c record modal
            this.openModal(this.selectedItem.id);
        } else if (this.selectedItem.level === 2) {
            // Open New_Child_Request screen flow
            this.openScreeenFlowModal(this.selectedItem.id);
        }
    }

    openModal(recId) {
        this.recId = recId;
        this.isModalOpen = true;
        console.log('openModal() calling for record id: ' + this.recId);
    }

    // Method to close the modal
    closeModal(event) {
        this.isModalOpen = false;
        // check event for closed modal and saved pressed
        if (event.detail && event.detail.saved) {
            console.log('Record was saved');
            // You can perform additional actions here if needed, such as refreshing data
            console.log('Record was saved: ', event.detail.data.apiName, event.detail.data.id);
            let rec = this.recordById[event.detail.data.id];
            rec.Annat_Beskrivning__c = event.detail.data.fields.Annat_Beskrivning__c.value;
            rec.Ans_kt_V_rde_Kontanter_Presentkort__c = event.detail.data.fields.Ans_kt_V_rde_Kontanter_Presentkort__c.value;
            rec.Beviljat_V_rde_Presentkort_Kontanter__c = event.detail.data.fields.Beviljat_V_rde_Presentkort_Kontanter__c.value;
            rec.Kontanter_Presentkort__c = event.detail.data.fields.Kontanter_Presentkort__c.value;
            rec.Kategori__c = event.detail.data.fields.Kategori__c.value;
            rec.Underkategori__c = event.detail.data.fields.Underkategori__c.value;
            rec.Kostnad_majblomman_kr__c = event.detail.data.fields.Kostnad_majblomman_kr__c.value;
            rec.Kommentar__c = event.detail.data.fields.Kommentar__c.value;
            console.log('Updated record: ', JSON.stringify(rec, null, 2));
            // if (this.asCount(event.detail.data.fields.Beviljat_V_rde_Presentkort_Kontanter__c.value) === 0) {
            //     this.selectedRows = this.selectedRows.filter(row => row !== rec.Application__c);
            // }
            let child = this.barn[rec.Barnet_ApplicationEntry__c];
            let request = child._children.find(item => item.id === rec.Id);
            request.request = rec.Ans_kt_V_rde_Kontanter_Presentkort__c;
            let app = this.data.find(item => item.id === rec.Application__c);
            console.log('Found app: ', app);
            let pageChild = app._children.find(item => item.id === rec.Barnet_ApplicationEntry__c);
            console.log('Found pageChild: ', pageChild);
            let pageRequest = pageChild._children.find(item => item.id === rec.Id);
            if (pageRequest) {
                console.log('Found page request: ', pageRequest);
                pageRequest.request = rec.Ans_kt_V_rde_Kontanter_Presentkort__c;
                pageRequest.granted = rec.Beviljat_V_rde_Presentkort_Kontanter__c;
                pageRequest.category = rec.Kategori__c;
                pageRequest.subCategory = rec.Underkategori__c;
                pageRequest.paymentType = rec.Kontanter_Presentkort__c;
                pageRequest.description = rec.Annat_Beskrivning__c;
            }
            this.recalculateTree();
            this.paginate();
        }
        this.isModalOpen = false;
    }

    openScreeenFlowModal(childRecId) {
        this.childRecordId = childRecId;
        this.childRecordObjectApiName = 'XC_ApplicationEntryChild__c';
        this.childRecordFlowApiName = this.flowApiName;
        debugger;
        // find c-screen-flow component and call startFlow() method
        const flowComponent = this.template.querySelector('c-screen-flow');
        flowComponent.handleStartFlow({
            recordId: this.childRecordId,
            objectApiName: this.childRecordObjectApiName
        });
    }

    handleFlowSubmit(event) {
        console.log('handleSubmit() called');
        console.log(event.detail)
        // check event for closed modal and saved pressed
        if (event.detail && event.detail.saved) {
            console.log('Record was saved', event.detail);
            console.log('Errors: ', event.detail.errors);
            console.log('Output Variables: ', event.detail.data.outputVariables);
            if (event.detail.data.outputVariables) {
                let child = event.detail.data.outputVariables.find(item => {
                    return (item.dataType === 'SOBJECT' && item.name === 'New_Request_Record' && item.objectType === 'Bidragsrader__c');
                });
                if (child) {
                    console.log('Found record: ', child.value);
                    let app = this.apps[child.value.Application__c];
                    console.log('Found app: ', app);

                    if (app.Bidragsrader__r === undefined || app.Bidragsrader__r === null) {
                        app.Bidragsrader__r = [];
                    }
                    app.Bidragsrader__r.push(child.value);
                    this.updateTree(app, child.value);
                    let currentExpandedRows = this.getExpandedRows();
                    currentExpandedRows.push(child.value.Barnet_ApplicationEntry__c);
                    this.currentExpandedRows = currentExpandedRows;
                }
            }
        }
    }

    getExpandedRows(e) {
        const grid = this.template.querySelector('lightning-tree-grid');
        return grid.getCurrentExpandedRows();
    }

    loadApplications() {
        debugger;
        apexGetAllApplications()
            .then(result => {
                this.isLoading = false;
                this.applications = result;
                console.log('Loaded applications: ', this.applications?.length);
                this.data = this.buildTree();
                this.paginate();

            })
            .catch(error => {
                this.isLoading = false;
                console.error('Error loading applications', error);
            });
    }

    paginate() {
        debugger;
        this.pageData = this.data.slice(this.skip, this.pageSize + this.skip);
        this.isFirstPage = this.currentPage === 1;
        this.isLastPage = this.currentPage === this.totalPages;
        this.pageSelectedRows = this.selectedRows.filter(row => this.pageData.find(data => data.id === row));
    }

    handleNextPage() {
        console.log('Nästa...');
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.skip = (this.currentPage - 1) * this.pageSize;
            this.paginate();
        }
    }

    handleLastPage() {
        console.log('Sista...');
        if (this.currentPage < this.totalPages) {
            this.currentPage = this.totalPages;
            this.skip = (this.currentPage - 1) * this.pageSize;
            this.paginate();
        }
    }

    handlePreviousPage() {
        console.log('Föregående...');
        if (this.currentPage > 1) {
            this.currentPage--;
            this.skip = (this.currentPage - 1) * this.pageSize;
            this.paginate();
        }
    }

    handleFirstPage() {
        console.log('Första...');
        if (this.currentPage > 1) {
            this.currentPage = 1;
            this.skip = (this.currentPage - 1) * this.pageSize;
            this.paginate();
        }
    }

    buildTree() {
        let treeData = [];
        this.apps = {};
        this.barn = {};

        if (this.applications === undefined || this.applications === null) {
            return treeData;
        }

        this.recordCount = this.applications.length;
        this.totalPages = Math.ceil(this.recordCount / this.pageSize);
        this.isFirstPage = this.currentPage === 1;
        this.isLastPage = this.currentPage === this.totalPages;
        this.skip = (this.currentPage - 1) * this.pageSize;

        this.applications.forEach(app => {
            let appNode = {
                id: app.Id,
                name: app.Name,
                originalName: app.Name,
                url: "/application/s/detail/" + app.Id,
                request: 0,
                granted: 0,
                grantedTotalCount: 0,
                grantedDefinedCount: 0,
                status: app.XC_Status__c,
                showCheckbox: true,
                _children: []
            };
            this.apps[app.Id] = appNode;
            treeData.push(appNode);
        });

        this.applications.forEach(app => {
            app.Barnen__r.forEach(child => {
                let childNode = {
                    id: child.Id,
                    appId: app.Id,
                    name: child.Name,
                    originalName: child.Name,
                    url: "/application/s/detail/" + child.Id,
                    firstName: child.XC_Fornamn__c,
                    lastName: child.XC_Efternamn__c,
                    birthYear: child.XC_Fodelsear__c,
                    request: 0,
                    granted: 0,
                    grantedTotalCount: 0,
                    grantedDefinedCount: 0,
                    allChildrenValidated: true,
                    action: 'Nytt Bidrag',
                    icon: 'utility:add',
                    _children: []
                };
                this.barn[child.Id] = childNode;
                let appNode = this.apps[child.XC_Application__c];
                appNode._children.push(childNode);
            });

            if (app.Bidragsrader__r) {
                app.Bidragsrader__r.forEach(request => {
                    let reqNode = {
                        id: request.Id,
                        name: request.Name,
                        // url: "/application/s/detail/" + child.Id,
                        category: request.Kategori__c,
                        subCategory: request.Underkategori__c,
                        request: request.Ans_kt_V_rde_Kontanter_Presentkort__c,
                        granted: request.Beviljat_V_rde_Presentkort_Kontanter__c,
                        paymentType: request.Kontanter_Presentkort__c,
                        description: request.Annat_Beskrivning__c,
                        action: 'Redigera',
                        icon: 'utility:edit',
                    };
                    let child = this.barn[request.Barnet_ApplicationEntry__c];
                    child._children.push(reqNode);
                    this.recordById[request.Id] = request;
                });
            }
            this.recalculateTree();
        });

        // Object.entries(this.apps).forEach(([key, app]) => {
        //     app.statusIcon = (app.grantedTotalCount === app.grantedDefinedCount) ? 'action:approval' : 'action:new_note';
        // });

        // const formatter = new Intl.NumberFormat('sv-SE', { style: 'currency', currency: 'SEK' });
        // this.totalRequested = formatter.format(this._totalRequested);
        // this.totalGranted = formatter.format(this._totalGranted);

        return treeData;
    }

    updateTree(app, request) {
        let childNode = this.barn[request.Barnet_ApplicationEntry__c];
        let reqNode = {
            id: request.Id,
            name: request.Name,
            category: request.Kategori__c,
            subCategory: request.Underkategori__c,
            request: request.Ans_kt_V_rde_Kontanter_Presentkort__c,
            granted: request.Beviljat_V_rde_Presentkort_Kontanter__c,
            paymentType: request.Kontanter_Presentkort__c,
            description: request.Annat_Beskrivning__c,
            action: 'Redigera',
            icon: 'utility:edit',
        };
        childNode._children.push(reqNode);
        this.recalculateTree();
        this.paginate();
    }

    // Method for recalculating the total requested and granted amounts for the total tree
    recalculateTree() {
        this._totalRequested = 0;
        this._totalGranted = 0;
        Object.entries(this.apps).forEach(([key, app]) => {
            app.request = 0;
            app.granted = 0;
            app.grantedDefinedCount = 0;
            app.grantedTotalCount = 0;
            app.allChildrenValidated = true;
            app._children.forEach(child => {
                child.request = 0;
                child.granted = 0;
                child.grantedDefinedCount = 0;
                child.grantedTotalCount = 0;
                const isValid = this.validateApplication(child._children);
                app.allChildrenValidated &= isValid;
                child._children.forEach(request => {
                    child.request += this.asData(request.request);
                    child.granted += this.asData(request.granted);
                    child.grantedDefinedCount += this.asCount(request.granted);
                    child.grantedTotalCount += 1;
                    this._totalRequested += this.asData(request.request);
                    this._totalGranted += this.asData(request.granted);
                    app.request += this.asData(request.request);
                    app.granted += this.asData(request.granted);
                    app.grantedDefinedCount += this.asCount(request.granted);
                    app.grantedTotalCount += 1;
                });
                child.name = child.originalName + ' ' + child.grantedDefinedCount + '/' + child.grantedTotalCount;
            });
            app.name = app.originalName + ' (' + app._children.length + ') ' + app.grantedDefinedCount + '/' + app.grantedTotalCount;
        });

        Object.entries(this.apps).forEach(([key, app]) => {
            app.statusIcon = (app.grantedTotalCount === app.grantedDefinedCount && app.allChildrenValidated) ? 'action:approval' : 'action:new_note';
        });

        const formatter = new Intl.NumberFormat('sv-SE', { style: 'currency', currency: 'SEK' });
        this.totalRequested = formatter.format(this._totalRequested);
        this.totalGranted = formatter.format(this._totalGranted);
    }

    asData(param) {
        let digitRegExp = /^\d+$/;
        return (digitRegExp.test(param)) ? param : 0;
    }

    asCount(param) {
        let digitRegExp = /^\d+$/;
        return (digitRegExp.test(param)) ? 1 : 0;
    }

    hasText(param) {
        return !(param === undefined || param === null || param.length === 0)
    }

    

    validateApplication(rows){
        if (rows.length === 0){
            return false;
        }
        let validatedRow = 0;
        rows.forEach(row => {
            if (this.hasText((row.category)) && this.hasText((row.paymentType)) && this.hasText(row.subCategory)) {
                validatedRow += 1;
            }
        });
        return rows.length === validatedRow;
    }
}