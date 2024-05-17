/**
 * Created by peterfriberg on 2024-05-15.
 */

import { LightningElement, track, api } from 'lwc';
import apexGetAllApplications from '@salesforce/apex/ApplicationFormsController.getAllApplications';
import AcceptMultipleApplicationsModal from 'c/acceptMultipleApplicationsModal';

export default class MultiApplicationTree extends LightningElement {
    @api flowApiName = '';
    @api pageSize = 15

    @track selectedRows = [];
    @track applications = [];
    @track isLoading = true;

    @track data = [];
    @track dataById = {};
    @track recordById = {};

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

    handleRowSelection(event) {
        const eventAction = event.detail.config.action;
        const selectedRowId = event.detail.config.value;
        //console.log(JSON.stringify(this.selectedRows));
        //console.log(JSON.stringify(event.detail.config.action));

        if (eventAction === 'rowSelect') {
            let selectedRow = this.findSelectedRow(event, selectedRowId);
            if (selectedRow.level > 1) {
                this.selectedRows = this.filterSelection(event, selectedRowId)
                alert('Du kan bara välja ansökningsrad(er)');
            } else if (selectedRow.level === 1) {
                if (!this.validateApp(selectedRow)) {
                    this.selectedRows = this.keepSelection(event);
                    alert('Du kan bara välja färdigbehandlade ansökningar');
                }
                else{
                    this.selectedRows = this.keepSelection(event);
                    this.disabledButton = this.selectedRows.length === 0;
                }
            }
        } else if (eventAction === 'selectAllRows') {
            this.selectedRows = this.keepSelection(event);
            this.disabledButton = this.selectedRows.length === 0;
        }
        else if(eventAction === 'rowDeselect' || eventAction === 'deselectAllRows'){
            this.selectedRows = [];
            this.disabledButton = true;
        }
        //console.log(JSON.stringify(this.selectedRows));
    }

    validateApp(row) {
        return (row.level === 1) && (row.grantedTotalCount === row.grantedDefinedCount);
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
        const result = await AcceptMultipleApplicationsModal.open({
            size: 'medium',
            description: 'Approve',
        });

        if (result === 'ok') {
            window.location.reload();
        } else if (result === 'error') {
            this.showNotification('Error', 'Error occurred when updating the form.', 'error');
        }
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

    openScreeenFlowModal(recId) {
        this.childRecordId = recId;
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
            console.log('Updated record: ', JSON.stringify(rec, null, 2));
            if (!event.detail.data.fields.Kontanter_Presentkort__c.value) {
                this.selectedRows = this.selectedRows.filter(row => row !== rec.Id);
            }
            this.data = this.buildTree();
        }
        this.isModalOpen = false;
    }

    loadApplications() {
        debugger;
        apexGetAllApplications()
            .then(result => {
                this.isLoading = false;
                this.applications = result;
                console.log('Loaded applications: ', this.applications?.length);
                this.data = this.buildTree();
            })
            .catch(error => {
                this.isLoading = false;
                console.error('Error loading applications', error);
            });
    }

    buildTree() {
        let treeData = [];
        this.apps = {};
        this.barn = {};
        this._totalRequested = 0;
        this._totalGranted = 0;

        debugger;

        if (this.applications === undefined || this.applications === null) {
            return treeData;
        }

        this.applications.forEach(app => {
            let appNode = {
                id: app.Id,
                name: app.Name,
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
                    name: child.Name,
                    url: "/application/s/detail/" + child.Id,
                    firstName: child.XC_Fornamn__c,
                    lastName: child.XC_Efternamn__c,
                    birthYear: child.XC_Fodelsear__c,
                    request: 0,
                    granted: 0,
                    grantedTotalCount: 0,
                    grantedDefinedCount: 0,
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
                    child.request += reqNode.request || 0;
                    child.granted += reqNode.granted || 0;
                    child.grantedDefinedCount += (reqNode.granted) ? 1 : 0;
                    child.grantedTotalCount += 1;
                    this._totalRequested += reqNode.request || 0;
                    this._totalGranted += reqNode.granted || 0;
                    this.dataById[request.Id] = reqNode;
                    this.recordById[request.Id] = request;
                    let appNode = this.apps[request.Application__c];
                    appNode.request += reqNode.request || 0;
                    appNode.granted += reqNode.granted || 0;
                    appNode.grantedDefinedCount += (reqNode.granted) ? 1 : 0;
                    appNode.grantedTotalCount += 1;
                });
            }

            let appNode = this.apps[app.Id];
            appNode.name = appNode.name + ' (' + appNode._children.length + ') ' + appNode.grantedDefinedCount + '/' + appNode.grantedTotalCount;

            app.Barnen__r.forEach(child => {
                let childNode = this.barn[child.Id];
                childNode.name = childNode.name + ' ' + childNode.grantedDefinedCount + '/' + childNode.grantedTotalCount;
            });
        });

        Object.entries(this.apps).forEach(([key, app]) => {
            console.log('App: Total grant count=', app.grantedTotalCount, ' Defined grant count=', app.grantedDefinedCount);
            app.statusIcon = (app.grantedTotalCount === app.grantedDefinedCount) ? 'action:approval' : 'action:new_note';
            console.log('App: Total grant count=', app.grantedTotalCount, ' Defined grant count=', app.grantedDefinedCount, ' Status icon=', app.statusIcon);
        });

        const formatter = new Intl.NumberFormat('sv-SE', { style: 'currency', currency: 'SEK' });
        this.totalRequested = formatter.format(this._totalRequested);
        this.totalGranted = formatter.format(this._totalGranted);

        return treeData;
    }
}