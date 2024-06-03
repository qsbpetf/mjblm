import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from "lightning/uiRecordApi";
import NAME_FIELD from '@salesforce/schema/Bidragsrader__c.Name';
import KATEGORI_FIELD from '@salesforce/schema/Bidragsrader__c.Kategori__c';
import UNDERKAT_FIELD from '@salesforce/schema/Bidragsrader__c.Underkategori__c';
import ANSOKT_FIELD from '@salesforce/schema/Bidragsrader__c.Ans_kt_V_rde_Kontanter_Presentkort__c';
import BEVILJAT_FIELD from '@salesforce/schema/Bidragsrader__c.Beviljat_V_rde_Presentkort_Kontanter__c';
import KONTANTPKORT_FIELD from '@salesforce/schema/Bidragsrader__c.Kontanter_Presentkort__c';
import BESKRIVNING_FIELD from '@salesforce/schema/Bidragsrader__c.Annat_Beskrivning__c';
import KOSTNAD_MAJBLOMMAN_FIELD from '@salesforce/schema/Bidragsrader__c.Kostnad_majblomman_kr__c';
import KOMMENTAR_FIELD from '@salesforce/schema/Bidragsrader__c.Kommentar__c';

export default class BidragsraderModal extends LightningElement {

    @api isOpen = false;
    @api
    get recordId() {
        return this.privateRecordId;
    }
    set recordId(value) {
        console.log('set recordId() called with value: ' + value);
        this.privateRecordId = value;
        this.initializedRecordId = value;
        if (value) {
            this.openModal();
        }
    }

    privateRecordId;
    @track initializedRecordId = '';

    // wire to get the Bidragsrader__c record
    @wire(getRecord, {
        recordId: '$initializedRecordId',
        fields: [NAME_FIELD, KATEGORI_FIELD, UNDERKAT_FIELD, ANSOKT_FIELD, BEVILJAT_FIELD, KONTANTPKORT_FIELD, BESKRIVNING_FIELD, KOSTNAD_MAJBLOMMAN_FIELD, KOMMENTAR_FIELD]
    })
    wiredRecord({ error, data }) {
        console.log('wiredRecord() called with data: ' + data);
        if (data) {
            this.record = data;
            this.error = undefined;
            console.log('Record data:', JSON.stringify(data));
        } else if (error) {
            this.error = error;
            this.record = undefined;
            console.error('Error fetching record:', JSON.stringify(error));
        }
    }

    // To open the modal
    @api openModal() {
        this.isOpen = true;
        console.log('openModal() called for record id: ' + this.recordId);
    }

    // To close the modal
    handleClose() {
        this.isOpen = false;
        this.dispatchEvent(new CustomEvent('close'));
    }

    // Handling saving the data - this utilizes the built-in submit functionality of lightning-record-edit-form
    handleSave() {
        console.log('handleSave() called');
        this.template.querySelector('lightning-record-edit-form').submit();
        this.isOpen = false; // Optionally close the modal on save
        this.dispatchEvent(new CustomEvent('close', {
            detail: {
                saved: true,
                data: this.record
            }
        }));
    }

    handleSuccess(event) {
        const updatedRecord = event.detail; // This contains the fields that were submitted.
        console.log('handleSuccess() called' + JSON.stringify(event.detail, null, 2));
        this.isOpen = false;
        this.dispatchEvent(new CustomEvent('close', {
            detail: {
                saved: true,
                data: updatedRecord
            }
        }));
    }
}