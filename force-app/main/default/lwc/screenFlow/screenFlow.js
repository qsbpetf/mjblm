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
    // These will be set from the community builder or the page where you are using this LWC
    @api flowApiName;
    @api buttonLabel;
    @api casePrefix;
    @api recordId;      // This property is populated by the App Builder when the component is placed on a record page.
    @api objectApiName; // API name of the record’s sObject type.
    @api buttonJustify;

    // @track flowTitle = 'Your Flow Title';
    @track showFlow = false;
    @track flowInputVariables;

    // Injects the page reference into the component.
    @wire(CurrentPageReference) pageRef;

    // Flag to check if wire service returned data
    wireCompleted = false;
    @wire(getRecord, {
        recordId: userId, fields: [
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
            console.log('CasePrefix:', (this.casePrefix) ? this.casePrefix : '');
            console.log('PageRef:', (this.pageRef) ? this.pageRef : '');
            this.wireCompleted = true;
        }
    }

    get buttonJustifyClass() {
        return `button-container-${this.buttonJustify}`;
    }

    handleStatusChange(event) {
        console.log('EVENT = ', JSON.parse(JSON.stringify(event.detail)));
        if (event.detail.status === 'FINISHED') {
            this.closeModal();
        }
    }

    closeModal() {
        this.showFlow = false;
    }

    // 3 flows covering 9 scenarios
    // Log a case
    //    varCasePrefix (configurable) = "Support" eller "PSIRT"
    //
    handleStartFlow() {
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
                name : 'varCasePrefix',
                type : 'String',
                value : this.casePrefix
            },
            {
                name : 'varRecordId',
                type : 'String',
                value : (this.recordId) ? this.recordId : ''
            },
            {
                name : 'varObjectApiName',
                type : 'String',
                value : (this.objectApiName) ? this.objectApiName : ''
            }
        ];
        this.showFlow = true;
    }
}