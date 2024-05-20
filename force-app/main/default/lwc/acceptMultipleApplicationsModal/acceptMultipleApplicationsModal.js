import { api, track} from 'lwc';
import LightningModal from 'lightning/modal';
import apexUpdateApplicationsBulk from '@salesforce/apex/ApplicationFormsController.updateApplicationsBulk';
import apexGetApproversForCurrentUser from '@salesforce/apex/ApplicationFormsController.getApproversForCurrentUser';

export default class AcceptMultipleApplicationsModal extends LightningModal {
    
    @track applicationIds;
    @track approvers = [];
    @track error;
    @track isLoading = false;
    @track errorMsg = ''; // not in use as of now
    @track allApplications = [];
    @track isValidated = false;
    @track disabledButton = true;
    @track disabledCheckbox = true;
    @track disabledSelect = false;
    

    @api set recordIds(rids) {
        this.applicationIds = rids.split(',');
    }

    get recordIds(){
        return this.applicationIds;
    }

    get infoText(){
        return `<strong>Du har valt att godkänna de markerade ansökningarna. Var vänlig notera följande:</strong><br>
        1. Godkända ansökningar kommer att försvinna från listvyn: Du kommer inte längre att kunna se eller hantera dessa ansökningar i den nuvarande vyn.<br>
        2. Åtgärden kan inte ångras: När ansökningarna har godkänts, kan denna åtgärd inte ångras eller ändras utan att kontakta Riksförbundet.<br>
        <strong>Är du säker på att du vill fortsätta med att godkänna alla markerade ansökningar?</strong>`;
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
        this.form[`XC_Approver${evt.target.dataset.approver}__c`] = evt.target.value;
        if(evt.target.value === ""){
            this.disabledCheckbox = true;

        }
        else if(this.form.XC_Approver1__c && this.form.XC_Approver2__c){
            this.disabledCheckbox = false; 
        }
        
    }

    handleCheckbox(event){
        this.isValidated = event.target.checked;
        this.disabledSelect = event.target.checked;
        this.disabledButton = !event.target.checked;
    }

    async onSave() {
        try {
            this.isLoading = true;
            this.createApplicationList();
            console.log(JSON.stringify(this.allApplications));

             // TODO: check if "updateApplicationsBulk" works
            //await apexUpdateApplicationsBulk({ forms: this.allApplications }); 
           
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