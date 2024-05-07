/**
 * Created by peterfriberg on 2024-04-17.
 */

import { LightningElement, api, wire, track } from 'lwc';
import apexGetApplication from '@salesforce/apex/ApplicationFormsController.getApplication';

const actions = [
    {
        label: 'Redigera',
        name: 'edit_details',
        iconName: 'utility:view_details'
    }
];

export default class ApplicationTree extends LightningElement {

    @api recordId;
    @track data = [];
    @track dataById = {};
    @track recordById = {};

    @track isModalOpen = false; // Used to control the visibility of modal
    @track selectedItem = { id: '' }; // Used to store the clicked row data handleRowClick(event) {
    @track content;

    actions = actions;
    @track record;
    @track recId = '';
    @track totalRequested = 0;
    @track totalGranted = 0;

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
                iconName: 'utility:edit',
                name: 'edit_details',
                label: 'Redigera',
                title: 'Redigera',
                variant: 'base'
            },
            initialWidth: 100
        }
    ];

    get cardTitle() {
        return 'Ansökan: ' + (this.record ? '' + this.record.Name : '');
    }

    // Method to handle the row action
    handleRowClick(event) {
        this.selectedItem = event.detail.row;
        const action = event.detail.action;
        console.log('Action: ', action.name);
        console.log('Selected Row: ', this.selectedItem, JSON.stringify(this.selectedItem, null, 2));
        this.content = JSON.stringify(this.selectedItem, null, 2);

        if (this.selectedItem.level === 2) {
            // Open Bidragsrader__c record modal
            this.openModal(this.selectedItem.id);
        }
    }

    // Method to open the modal
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

    connectedCallback() {
        this.getApplication(this.recordId);
    }

    async getApplication(applicationId) {
        this.record = await apexGetApplication({ formId: applicationId });
        console.log('Application: ', this.record, JSON.stringify(this.record, null, 2));
        this.data = this.buildTree();
    }

    buildTree() {
        let treeData = [];
        let barn = {};
        let _totalRequested = 0;
        let _totalGranted = 0;

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
                _children: []
            };
            barn[child.Id] = childNode;
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
                description: child.Annat_Beskrivning__c
            };
            barn[child.Barnet_ApplicationEntry__c]._children.push(childNode);
            barn[child.Barnet_ApplicationEntry__c].request += childNode.request || 0;
            barn[child.Barnet_ApplicationEntry__c].granted += childNode.granted || 0;
            _totalRequested += childNode.request || 0;
            _totalGranted += childNode.granted || 0;
            this.dataById[child.Id] = childNode;
            this.recordById[child.Id] = child;
        });

        const formatter = new Intl.NumberFormat('sv-SE', { style: 'currency', currency: 'SEK' });
        this.totalRequested = formatter.format(_totalRequested);
        this.totalGranted = formatter.format(_totalGranted);

        return treeData;
    }
}