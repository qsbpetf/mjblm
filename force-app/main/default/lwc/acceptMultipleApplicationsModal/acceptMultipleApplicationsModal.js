import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import apexUpdateApplication from '@salesforce/apex/ApplicationFormsController.updateApplication';
import apexGetApproversForCurrentUser from '@salesforce/apex/ApplicationFormsController.getApproversForCurrentUser';
import Labels from './labels';

export default class AcceptMultipleApplicationsModal extends LightningModal {
    
    applicationIds;

    @api set recordIds(rids) {
        this.applicationIds = rids;
        console.log(rids);
    }

    get recordIds(){
        return this.applicationIds;
    }

    labels = Labels;
    approvers = [];
    error;
    isLoading = false;
    errorMsg = '';

    connectedCallback(){
        this.getApprovers();
    }

    form = {
        // Id: '',
        // XC_AcceptedNotes__c: '',
        XC_Approver1__c: '',
        XC_Approver2__c: '',
        // XC_Kostnad_for_Majblomman__c: 0.0,
        // XC_ApprovedAmount__c: 0.0
    }

    async getApprovers() {
        try {
            this.approvers = await apexGetApproversForCurrentUser();
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

    // validate() {
    //     this.errorMsg = '';
    //     let valid = true;
    //     this.template.querySelectorAll('[data-validity-check="true"]').forEach(
    //         el => {
    //             if (!el.checkValidity()) {
    //                 el.reportValidity();
    //                 valid = false;
    //             }
    //         }
    //     );
    //     if (!(this.form.XC_Approver1__c || this.form.XC_Approver2__c)) {
    //         this.errorMsg = labels.PLEASE_SELECT_ONE_APPROVER;
    //         valid = false;
    //     }

    //     return valid;
    // }

    async onSave() {
        // if (!this.validate()) {
        //     return;
        // }
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