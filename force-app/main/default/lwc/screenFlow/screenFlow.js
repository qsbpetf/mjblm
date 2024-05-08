/*
----------------------------------------------------------------------------
|  Lightning Javascript: screenFlow
|
|  Filename: screenFlow.js
|
|  Author: Peter Friberg, Xceed AB
|
|  Description:
|     The ScreenFlow class is an LWC controller designed for Salesforce. It
|     provides properties and methods to manage flows in Salesforce, such as
|     start and stop a flow, handle status changes, etc. It utilises the
|     power of the Lightning Web Components, the wire service, and the Apex
|     method getRecord from Salesforce to achieve its function. There are
|     console.log statements integrated to provide crucial logging during the
|     different stages of the flow.
|
|  Change Log:
|     2023-10-18  Peter Friberg  Initial Development.
----------------------------------------------------------------------------
*/

import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import userId from '@salesforce/user/Id';
import userContactIdField from '@salesforce/schema/User.ContactId';
import userAccountIdField from '@salesforce/schema/User.AccountId';
import { getRecord } from 'lightning/uiRecordApi';

export default class ScreenFlow extends LightningElement {
    @api
    get flowApiName() {
        return this.privateFlowApiName;
    }
    set flowApiName(value) {
        console.log('set flowApiName() called with value: ' + value);
        this.privateFlowApiName = value;
    }

    @api handleStartFlow(data) {
        console.log('screenFlow.data = ', JSON.stringify(data));
        this.flowInputVariables = [
            {
                name : 'varContactId',
                type : 'String',
                value : this.contactId
            },
            {
                name : 'varAccountId',
                type : 'String',
                value : this.accountId
            },
            {
                name : 'varRecordId',
                type : 'String',
                value : data.recordId
            },
            {
                name : 'varObjectApiName',
                type : 'String',
                value : data.objectApiName
            }
        ];
        this.showFlow = true;
    }

    privateFlowApiName;

    // @track flowTitle = 'Your Flow Title';
    @track showFlow = false;
    @track flowInputVariables;

    // Injects the page reference into the component.
    @wire(CurrentPageReference) pageRef;

    // Flag to check if wire service returned data
    wireCompleted = false;
    @wire(getRecord, {
        recordId: userId,
        fields: [
            userContactIdField, userAccountIdField
        ]
    })
    wireuser({ error, data}) {
        if (error) {
            this.error = error;
            this.wireCompleted = true; // Set this even if there's an error, to indicate the attempt was made
        } else if (data) {
            this.contactId = data.fields.ContactId.value;
            this.accountId = data.fields.AccountId.value;
            console.log('AccountId:', this.accountId);
            console.log('ContactId:', this.contactId);
            console.log('RecordId:', (this.recordId) ? this.recordId : '');
            console.log('ObjectApiName:', (this.objectApiName) ? this.objectApiName : '');
            console.log('PageRef:', (this.pageRef) ? this.pageRef : '');
            this.wireCompleted = true;
        }
    }

    handleStatusChange(event) {
        console.log('EVENT = ', JSON.parse(JSON.stringify(event.detail)));
        if (event.detail.status === 'FINISHED') {
            this.dispatchEvent(new CustomEvent('close', {
                detail: {
                    saved: true,
                    data: event.detail
                }
            }));
            this.closeModal();
        }
    }

    closeModal() {
        this.showFlow = false;
    }
}