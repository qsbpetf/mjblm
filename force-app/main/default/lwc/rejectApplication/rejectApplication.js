import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import apexGetContacts from '@salesforce/apex/ApplicationFormsController.getApplicationContacts';
import apexUpdateApplication from '@salesforce/apex/ApplicationFormsController.updateApplication';
import labels from './labels';

export default class RejectApplication extends LightningModal {

    labels = labels;

    _recordId;

    isLoading = false;
    errorMsg = '';

    @api set recordId(rid) {
        this._recordId = rid;
        this.form.Id = rid;
        this.getRejecters();
    }

    get recordId() {
        return this._recordId;
    }

    form = {
        Id: '',
        XC_RejectedNotes__c: '',
        XC_RejectedBy__c: '',
        XC_IntygSaknas__c: false
    }

    rejecters = [];

    async getRejecters() {
        try {
            this.rejecters = await apexGetContacts( {applicationId: this.recordId});
        } catch (err) {
            console.log( err);
        }
    }

    selectRejecter(evt) {
        this.errorMsg = '';
        this.form.XC_RejectedBy__c = evt.target.value;
    }

    inputChange(evt) {
        console.log('evt.target.value ' + evt.target.value);
        console.log('evt.target.checked ' + evt.target.checked);
        if (evt.target.type === 'checkbox') {
            this.form[evt.target.dataset.field] = evt.target.checked;
        } else {
            this.form[evt.target.dataset.field] = evt.target.value;
        }
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
        if (!this.form.XC_RejectedBy__c) {
            this.errorMsg = labels.SELECT_REJECTER;
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
            this.form.XC_Status__c = 'Rejected';
            console.log(JSON.stringify(this.form, null, 2));
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