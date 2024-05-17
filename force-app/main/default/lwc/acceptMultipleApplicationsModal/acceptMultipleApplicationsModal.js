import { api, track} from 'lwc';
import LightningModal from 'lightning/modal';
import apexUpdateApplicationsBulk from '@salesforce/apex/ApplicationFormsController.updateApplicationsBulk';
import apexGetApproversForCurrentUser from '@salesforce/apex/ApplicationFormsController.getApproversForCurrentUser';

export default class AcceptMultipleApplicationsModal extends LightningModal {
    
    @track applicationIds;
    @track approvers = [];
    @track error;
    @track isLoading = false;
    @track errorMsg = '';
    @track allApplications = [];
    @track isValidated = false;
    @track disabledButton = true;
    @track disabledCheckbox = true;

    @api set recordIds(rids) {
        this.applicationIds = rids.split(',');
    }

    get recordIds(){
        return this.applicationIds;
    }

    form = {
        XC_Approver1__c: '',
        XC_Approver2__c: '',
    }

    connectedCallback(){
        this.getApprovers();
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
        if(evt.target.value === ""){
            this.disabledCheckbox = true;
            //TODO: fix checkbox so that it unchecks
        }
        else if(this.form.XC_Approver1__c && this.form.XC_Approver2__c){
            this.disabledCheckbox = false; 
        }
        
    }

    handleCheckbox(event){
        this.isValidated = event.target.checked;
        this.disabledButton = !event.target.checked;
    }

    // inputChange(evt) {
    //     this.form[evt.target.dataset.field] = evt.target.value;
    // }

    validate() {
         this.errorMsg = '';
         let valid = true;
    //     this.template.querySelectorAll('[data-validity-check="true"]').forEach(
    //         el => {
    //             if (!el.checkValidity()) {
    //                 el.reportValidity();
    //                 valid = false;
    //             }
    //         }
    //     );
         if (!(this.form.XC_Approver1__c || this.form.XC_Approver2__c)) {
            this.errorMsg = "Välj godkännare";
             valid = false;
         }

         return valid;
     }

    async onSave() {
         if (!this.validate()) {
             return;
         }
        try {
            //this.isLoading = true; //turned of for testing
            this.createApplicationList();
            console.log(JSON.stringify(this.allApplications));

             // TODO: check if "updateApplicationsBulk" works
            //await apexUpdateApplicationsBulk({ forms: this.allApplications }); 
           
        } catch (e) {
             this.error = JSON.stringify(e);
            // this.close('error'); // turned off for testing
        } finally {
            // this.close('ok') // turned off for testing
        }
    }

    onCancel() {
        this.close('cancel');
    }

    createApplicationList(){
        this.applicationIds.forEach(appId => {
            let newForm = {
                Id: appId,
                XC_Approver1__c: this.form.XC_Approver1__c,
                XC_Approver2__c: this.form.XC_Approver2__c,
                XC_Status__c: this.form.XC_Status__c = 'Approved',
            };
            this.allApplications.push(newForm);
        });
        
        


    }

}