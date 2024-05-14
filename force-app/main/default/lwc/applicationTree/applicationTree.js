/**
 * Created by peterfriberg on 2024-04-17.
 */

import { LightningElement, api, track } from 'lwc';
import apexGetApplication from '@salesforce/apex/ApplicationFormsController.getApplication';
import apexGetLatestApplications from '@salesforce/apex/ApplicationFormsController.getLatesApplications';

export default class ApplicationTree extends LightningElement {

    @api recordId;
    @api flowApiName = '';
    @api monthsOld = 12;

    @track data = [];
    @track dataById = {};
    @track barn = {};
    @track recordById = {};

    @track isModalOpen = false; // Used to control the visibility of modal
    @track selectedItem = { id: '' }; // Used to store the clicked row data handleRowClick(event) {
    @track content;

    @track record;
    @track recId = '';
    @track totalRequested = 0;
    @track totalGranted = 0;
    @track _totalRequested = 0;
    @track _totalGranted = 0;

    @track childRecordId = '';
    @track childRecordObjectApiName = '';
    @track childRecordFlowApiName = this.flowApiName;

    @track latestApplications = [];
    @track urls = [];

    COLUMNS = [
        {
            type: 'url',
            fieldName: 'url',
            label: 'Datapost',
            typeAttributes: {
                label: { fieldName: 'name' }
            }
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
        }
    ];

    get cardTitle() {
        return 'Ansökan: ' + (this.record ? '' + this.record.Name : '');
    }

    // Method to handle the row action
    handleRowClick(event) {
        this.selectedItem = event.detail.row;
        const action = event.detail.action;
        console.log('Action: ', action.label);
        console.log('Selected Row: ', this.selectedItem, JSON.stringify(this.selectedItem, null, 2));
        this.content = JSON.stringify(this.selectedItem, null, 2);

        if (this.selectedItem.level === 2) {
            // Open Bidragsrader__c record modal
            this.openModal(this.selectedItem.id);
        } else if (this.selectedItem.level === 1) {
            // Open New_Child_Request screen flow
            this.openScreeenFlowModal(this.selectedItem.id);
        }
    }

    // Method to open the modal
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
            console.log('Record was saved: ', JSON.stringify(event.detail.data, null, 2));
            let rec = this.recordById[event.detail.data.id];
            rec.Annat_Beskrivning__c = event.detail.data.fields.Annat_Beskrivning__c.value;
            rec.Ans_kt_V_rde_Kontanter_Presentkort__c = event.detail.data.fields.Ans_kt_V_rde_Kontanter_Presentkort__c.value;
            rec.Beviljat_V_rde_Presentkort_Kontanter__c = event.detail.data.fields.Beviljat_V_rde_Presentkort_Kontanter__c.value;
            rec.Kontanter_Presentkort__c = event.detail.data.fields.Kontanter_Presentkort__c.value;
            rec.Kategori__c = event.detail.data.fields.Kategori__c.value;
            rec.Underkategori__c = event.detail.data.fields.Underkategori__c.value;
            console.log('Updated record: ', JSON.stringify(rec, null, 2));
            this.data = this.buildTree();
        }
        this.isModalOpen = false;
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
                    if (item.dataType === 'SOBJECT' && item.name === 'New_Request_Record' && item.objectType === 'Bidragsrader__c') {
                        return true;
                    }
                });
                if (child) {
                    console.log('Found record: ', child.value);
                    if (this.record.Bidragsrader__r === undefined || this.record.Bidragsrader__r === null) {
                        this.record.Bidragsrader__r = [];
                    }
                    this.record.Bidragsrader__r.push(child.value);
                    this.data = this.buildTree();
                }
            }
        }
    }

    connectedCallback() {
        this.getApplication(this.recordId);
        this.getLatestApplications(this.recordId);
    }

    async getApplication(applicationId) {
        this.record = await apexGetApplication({ formId: applicationId });
        console.log('Application: ', this.record, JSON.stringify(this.record, null, 2));
        this.data = this.buildTree();
    }

    async getLatestApplications(applicationId) {
        this.latestApplications = await apexGetLatestApplications( {
            appId: applicationId,
            monthsOld: this.monthsOld
        });
        console.log(this.latestApplications, JSON.stringify(this.latestApplications, null, 2));
        this.urls = this.latestApplications.map(app => {
            return {
                label: app.Name,
                url: '/application/s/application/' + app.Id
            }
        });
        console.log(this.urls, JSON.stringify(this.urls, null, 2));
    }

    buildTree() {
        let treeData = [];
        this.barn = {};
        this._totalRequested = 0;
        this._totalGranted = 0;

        debugger;

        console.log(JSON.stringify(this.record, null, 2));

        if (this.record === undefined || this.record === null || this.record.Barnen__r === undefined || this.record.Barnen__r === null) {
            return treeData;
        }

        this.record.Barnen__r.forEach(child => {
            let childNode = {
                id: child.Id,
                name: child.Name,
                url: "/application/s/detail/" + child.Id,
                firstName: child.XC_Fornamn__c,
                lastName: child.XC_Efternamn__c,
                birthYear: child.XC_Fodelsear__c,
                request: 0,
                granted: 0,
                action: 'Nytt Bidrag',
                icon: 'utility:add',
                _children: []
            };
            this.barn[child.Id] = childNode;
            treeData.push(childNode);
        });

        if (this.record.Bidragsrader__r === undefined || this.record.Bidragsrader__r === null) {
            return treeData;
        }

        this.record.Bidragsrader__r.forEach(child => {
            let childNode = {
                id: child.Id,
                name: child.Name,
                // url: "/application/s/detail/" + child.Id,
                category: child.Kategori__c,
                subCategory: child.Underkategori__c,
                request: child.Ans_kt_V_rde_Kontanter_Presentkort__c,
                granted: child.Beviljat_V_rde_Presentkort_Kontanter__c,
                paymentType: child.Kontanter_Presentkort__c,
                description: child.Annat_Beskrivning__c,
                action: 'Redigera',
                icon: 'utility:edit',
            };
            this.barn[child.Barnet_ApplicationEntry__c]._children.push(childNode);
            this.barn[child.Barnet_ApplicationEntry__c].request += childNode.request || 0;
            this.barn[child.Barnet_ApplicationEntry__c].granted += childNode.granted || 0;
            this._totalRequested += childNode.request || 0;
            this._totalGranted += childNode.granted || 0;
            this.dataById[child.Id] = childNode;
            this.recordById[child.Id] = child;
        });

        const formatter = new Intl.NumberFormat('sv-SE', { style: 'currency', currency: 'SEK' });
        this.totalRequested = formatter.format(this._totalRequested);
        this.totalGranted = formatter.format(this._totalGranted);

        return treeData;
    }
}