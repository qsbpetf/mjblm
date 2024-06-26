import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import apexGetContacts from '@salesforce/apex/ApplicationFormsController.getApplicationContacts';
import apexUpdateApplication from '@salesforce/apex/ApplicationFormsController.updateApplication';
import labels from './labels';

export default class AcceptApplication extends LightningModal {

    labels = labels;

    _recordId;

    error;
    isLoading = false;
    errorMsg = '';

    @api set recordId(rid) {
        this._recordId = rid;
        this.form.Id = rid;
        this.getApprovers();
    }

    get recordId() {
        return this._recordId;
    }

    form = {
        Id: '',
        XC_AcceptedNotes__c: '',
        XC_Approver1__c: '',
        XC_Approver2__c: '',
        XC_Kostnad_for_Majblomman__c: 0.0,
        XC_ApprovedAmount__c: 0.0
    }

    approvers = [];


    async getApprovers() {
        try {
            this.approvers = await apexGetContacts( {applicationId: this.recordId});
        } catch (err) {
            this.error = JSON.stringify(err, null, 2);
        }
    }

    selectApprover(evt) {
        this.errorMsg = '';
        this.form[`XC_Approver${evt.target.dataset.approver}__c`] = evt.target.value;
    }

    inputChange(evt) {
        this.form[evt.target.dataset.field] = evt.target.value;
    }

    validate() {
        this.errorMsg = '';
        let valid = true;
        this.template.querySelectorAll('[data-validity-check="true"]').forEach(
            el => {
                if (!el.checkValidity()) {
                    el.reportValidity();
                    valid = false;
                }
            }
        );
        if (!(this.form.XC_Approver1__c || this.form.XC_Approver2__c)) {
            this.errorMsg = labels.PLEASE_SELECT_ONE_APPROVER;
            valid = false;
        }

        return valid;
    }

    async onSave() {
        if (!this.validate()) {
            return;
        }
        try {
            this.isLoading = true;
            this.form.XC_Status__c = 'Approved';
            await apexUpdateApplication({ form: this.form });
        } catch (e) {
            this.error = JSON.stringify(e);
            this.close('error');
        } finally {
            this.close('ok')
        }
    }

    onCancel() {
        this.close('cancel');
    }

}