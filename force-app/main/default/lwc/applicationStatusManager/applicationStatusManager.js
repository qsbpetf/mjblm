import {LightningElement, api, track} from 'lwc';
import AcceptApplication from 'c/acceptApplication';
import RejectApplication from 'c/rejectApplication';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import apexGetApplication from '@salesforce/apex/ApplicationFormsController.getApplicationBySfId';
import apexGetContacts from '@salesforce/apex/ApplicationFormsController.getApplicationContacts';
import apexUpdateApplication from '@salesforce/apex/ApplicationFormsController.updateApplication';
import labels from './labels';

export default class ApplicationStatusManager extends LightningElement {

    labels = labels;

    _recordId;
    // isOpen = false;

    @track
    application;

    contacts = [];
    @track
    owner;
    newOwner;
    editMode = false;
    isLoading = false;
    // readyForApproval = false;

    @api
    set recordId(rid) {
        this._recordId = rid;
        this.getApplication();
        this.getContacts();
    }

    get ownerNotChanged() {
        return !this.newOwner;
    }

    get recordId() {
        return this._recordId;
    }

    async getApplication() {
        try {
            this.form = await apexGetApplication({ appId: this.recordId});
            console.log(JSON.stringify(this.form, null, 2));
            if (this.form.XC_Hanteras_av__r) {
                this.owner = {
                    Id: this.form.XC_Hanteras_av__r.Id,
                    Name: this.form.XC_Hanteras_av__r.Name
                };
            }
            // this.setIsOpen();
            // this.setReadyForApproval();
        } catch (e) {
            console.log('error1');
        }
    }

    // setIsOpen() {
    //     this.isOpen = !(['Approved', 'Rejected'].includes(this.form.XC_Status__c));
    // }

    // setReadyForApproval() {
    //     this.readyForApproval = this.form.XC_Status__c === 'Ready for Decision';
    // }

    // async handleApprove() {
    //     const result = await AcceptApplication.open({
    //         size: 'medium',
    //         description: 'Approve',
    //         recordId: `${this.recordId}`,
    //     });

    //     if (result === 'ok') {
    //         window.location.reload();
    //     } else if (result === 'error') {
    //         this.showNotification('Error', 'Error occurred when updating the form.', 'error');
    //     }

    // }

    // async handleReject() {
    //     const result = await RejectApplication.open({
    //         size: 'medium',
    //         description: 'Reject',
    //         recordId: `${this.recordId}`,
    //     });

    //     if (result === 'ok') {
    //         window.location.reload();
    //     } else if (result === 'error') {
    //         this.showNotification('Error', 'Error occurred when updating the form.', 'error');
    //     }
    // }

    // showNotification(title, message, variant) {
    //     const evt = new ShowToastEvent({
    //         title: title,
    //         message: message,
    //         variant: variant,
    //     });
    //     this.dispatchEvent(evt);
    // }

    async getContacts() {
        try {
            this.contacts = await apexGetContacts( {applicationId: this.recordId});
            this.contacts = this.contacts.filter(con => con.Id != this.owner?.Id);
        } catch (err) {
            this.error = JSON.stringify(err, null, 2);
        }
    }

    selectOwner(evt) {
        this.newOwner = this.contacts.find(c => c.Id === evt.target.value);
    }

    async saveOwner() {
        try {
            this.isLoading = true;
            this.form.XC_Hanteras_av__c = this.newOwner.Id;
            await apexUpdateApplication({ form: this.form });
            window.location.reload();
        } catch (e) {
            this.error = JSON.stringify(e);
        } finally {
            this.isLoading = false;
        }
    }

    toggleEditMode() {
        console.log('hehe');
        this.editMode = !this.editMode;
    }

}