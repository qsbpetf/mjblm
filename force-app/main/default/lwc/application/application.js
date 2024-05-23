import { LightningElement, track, api } from 'lwc';
import apexApply from '@salesforce/apex/ApplicationFormsController.apply';
import apexCreateTemporary from '@salesforce/apex/ApplicationFormsController.createTemporary';
import apexGetApplication from '@salesforce/apex/ApplicationFormsController.getApplication';
import apexUpdateApplication from '@salesforce/apex/ApplicationFormsController.updateApplication';
import apexGetKommuns from '@salesforce/apex/ApplicationFormsController.getKommuns';
import apexGetLfs from '@salesforce/apex/ApplicationFormsController.getLfs';
import apexGetRejectionReasons from '@salesforce/apex/ApplicationFormsController.getRejectionReasons';
import apexCheckLinkValidity from '@salesforce/apex/ApplicationFormsController.checkLinkValidity';
import apexGetPreselectedLf from '@salesforce/apex/ApplicationFormsController.getPreselectedLf';
import apexInitEmptyApp from '@salesforce/apex/ApplicationFormsController.initEmptyApp';
import apexRemoveOldFiles from '@salesforce/apex/ApplicationFormsController.removeOldFiles';
import apexGetPicklistHierarchy from '@salesforce/apex/ApplicationFormsController.getPicklistHierarchy';
import labels from './labels';

export default class Application extends LightningElement {

    labels = labels;

    _ctx;
    @api
    set ctx(ctx) {
        this._ctx = ctx;
        this.columns = [
            {label: 'Förnamn', fieldName: 'XC_Fornamn__c', type: 'text', show: true, maxLength: 255},
            {label: 'Efternamn', fieldName: 'XC_Efternamn__c', type: 'text', show: true, maxLength: 255},
            {label: 'Födelseår', fieldName: 'XC_Fodelsear__c', type: 'text', show: true, maxLength: 4, msgPatternMismatch: labels.YEAR_PATTERN_MISMATCH, pattern: '2[0-9]{3}'},
            {label: 'Personnummer/Samordningsnummer (ååmmddxxxx) ELLER LMA-nummer (00-000000/0)', fieldName: 'XC_Personnummer__c', type: 'text', show: this.isApply, pattern: '^(\\d{10}|(\\d{2}-\\d{8})|(\\d{2}-\\d{6}\\/\\d{1}))$', msgPatternMismatch: 'Samordningsnumret består av 10 siffror, där talet 60 är adderat till födelsedatumet. Om personen exempelvis är född den 1 januari 1970 så är samordningsnumret 700161XXXX. Exempel på LMA-nummer 20-000001/1, och det kan skrivas med eller utan skiljetecken.'}
        ]
    }

    get ctx() {
        return this._ctx;
    }

    get intygsEmailNotTheSame() {
        return this.isApply && this.form.XC_IntygsskrivarensEpost__c && this.form.XC_IntygsskrivarensEpost__c !== this.form.Confirm_XC_IntygsskrivarensEpost__c;
    }

    get policiesNotAccepted() {
        return this.isApply && !(this.form.integritetspolicy && this.form.uppgifterna);
    }

    get emailNotTheSame() {
        return this.isApply && this.form.XC_Epost__c && this.form.XC_Epost__c !== this.form.Confirm_XC_Epost__c;
    }

    @track
    form = {};
    @track
    data = [];
    @track
    columns = [];
    _kommunner = {}
    maxIndex = 0;
    temporaryId;
    createdId;
    isLoading = false;
    formLoaded = false;
    @track uploadedFiles = [];
    @track declaredFiles = [];
    tableErrors = [];
    formId;
    valid = true;
    selectedLan;
    selectedKommunn;
    selectedLF;
    lfs = [];
    rejectionReasons = [];
    lfPreselected = false;

    error;

    @track rowList = [];
    @track secondRowList = [];
    @track sumSecondRows = 0;
    @track optionGroups = [];

    // Getter for child select options
    get childOptions() {
        let options = [{ label: '-- Välj barn --', value: '' }];
        let next = this.rowList.map(child => {
            return { label: child.firstName + ' ' + child.lastName, value: child.id };
        });
        return options.concat(next);
    }

    // get optionGroups() {
    //     return [
    //         {
    //             label: "Lek, vila och fritid",
    //             options: [
    //                 { value: "Jul och andra högtider", text: "Jul och andra högtider" },
    //                 { value: "Läger och koloni", text: "Läger och koloni" },
    //                 { value: "Semester med familjen", text: "Semester med familjen" },
    //                 { value: "Terminsavgift", text: "Terminsavgift" },
    //                 { value: "Utsrustning", text: "Utsrustning" }
    //             ]
    //         },
    //         {
    //             label: "Utbildning",
    //             options: [
    //                 { value: "Skolaktiviteter", text: "Skolaktiviteter" },
    //                 { value: "Annan utbildning (beskriv)", text: "Annan utbildning (beskriv)" }
    //             ]
    //         },
    //         {
    //             label: "Hälsa",
    //             options: [
    //                 { value: "Glasögon", text: "Glasögon" },
    //                 { value: "Medicin", text: "Medicin" },
    //                 { value: "Behandling", text: "Behandling" },
    //             ]
    //         }
    //     ];
    // }

    addRow() {
        const id = this.rowList.length + 1;
        this.rowList.push({ id: id, firstName: '', lastName: '', year: '', ssn: '' });
        console.log('Added row with id: ' + id, this.rowList);
    }

    deleteRow(event) {
        const rowToDelete = parseInt(event.target.name, 10);
        this.rowList = this.rowList.filter(row => row.id !== rowToDelete);
    }

    handleInputChange(event) {
        const rowIndex = parseInt(event.target.dataset.id, 10);
        const fieldName = event.target.name;
        const value = event.target.value;

        let row = this.rowList.find(row => row.id === rowIndex);
        if (row) {
            row[fieldName] = value;
        }
    }

    addSecondRow() {
        const id = this.secondRowList.length + 1;
        this.secondRowList.push({ id: id, category: '', description: '', child: '', amount: null });
        console.log('Added row with id: ' + id, this.secondRowList);
    }

    deleteSecondRow(event) {
        const rowToDelete = parseInt(event.target.name, 10);
        this.secondRowList = this.secondRowList.filter(row => row.id !== rowToDelete);
    }

    handleSecondInputChange(event) {
        const rowIndex = parseInt(event.target.dataset.id, 10);
        const fieldName = event.target.name;
        const value = event.target.value;

        let row = this.secondRowList.find(row => row.id === rowIndex);
        if (row) {
            if (fieldName === 'amount') {
                row[fieldName] = parseInt(value, 10);
                this.calculateTotalAmount();
            } else {
                row[fieldName] = value;
            }
        }
    }

    calculateTotalAmount() {
        let totalAmount = 0;
        this.secondRowList.forEach(row => {
            totalAmount += this.asData(row.amount);
        });
        this.form.XC_Totalsumma_kr__c = totalAmount;
        // const formatter = new Intl.NumberFormat('sv-SE', { style: 'currency', currency: 'SEK' });
        this.sumSecondRows = totalAmount.toLocaleString('sv-SE');
    }

    asData(param) {
        let digitRegExp = /^\d+$/;
        return (digitRegExp.test(param)) ? param : 0;
    }

    get isApply() {
        return this.ctx === 'apply';
    }

    get isCertify() {
        return this.ctx === 'certify';
    }

    get isRiks() {
        return this.selectedLF.Name === 'RIKS';
    }

    get idForFile() {
        return this.isApply ? this.temporaryId : this.form.Id;
    }

    get certifierRejected() {
        return !this.form.XC_ApprovedByCertifier__c;
    }

    get showForm() {
        return this.formLoaded && !this.success && !this.createdId
    }

    get declaredFilesOptions() {
        return [
            {label: 'Normberäkning', value: 'Normberäkning'},
            {label: 'Intyg från intygsskrivare', value: 'Intyg från intygsskrivare'}
        ]
    }

    get filesInfo() {
        return (!(this.declaredFiles.length && this.uploadedFiles.length) && !this.form.XC_IntygsskrivarensEpost__c) ? labels.CERTIFIER_OR_FILE : null;
    }

    get lans() {
        return Object.keys(this._kommunner);
    }

    get applicantConfirmationMsg() {
        return labels.APPLICANT_CONFIRMATION_SCREEN.replace('{FormId}', this.createdId);
    }

    get kommunner() {
        return this._kommunner[this.selectedLan];
    }

    selectLan(evt) {
        this.selectedLan = evt.target.value;
    }

    selectRejectionReason(evt) {
        this.form.XC_CertifierRejectionReason__c = evt.target.value;
    }

    async selectKommun(evt) {
        this.selectedKommunn = evt.target.value;
        this.selectedLF = null;
        await this.getLfs();
    }

    selectLf(evt) {
        this.selectedLF = this.lfs.find(lf => lf.Id === evt.target.value);
    }

    get certifierRequired() {
        return this.isApply && this.selectedLF && this.selectedLF.XC_CertifierRequired__c && !(this.declaredFiles.includes('Intyg från intygsskrivare') && this.uploadedFiles.length);
    }

    async emptyForm() {
        try {
            this.form = await apexInitEmptyApp();
            this.form.XC_BorVardnadshavareTillsammans__c = true;
            this.form.uppgifterna = false;
            this.form.integritetspolicy = false;
            this.data = [
                {
                    XC_Fornamn__c: '',
                    XC_Efternamn__c: '',
                    XC_Fodelsear__c: null,
                    rowIndex: 0,
                    XC_Personnummer__c: ''
                }
            ];
            this.formLoaded = true;
        } catch (e) {
            this.error = JSON.stringify(e);
        }
        this.formLoaded = true;
    }

    async loadForm() {
        try {
            this.form = await apexGetApplication({formId: this.formId});
            this.data = [...this.form.Barnen__r.map(
                el => Object.assign(el, {rowIndex: el.Id})
            )];
            this.form.XC_ApprovedByCertifier__c = true;
            this.formLoaded = true;
        } catch (e) {
            this.error = JSON.stringify(e);
        }
    }

    getUrlParamValue(url, key) {
        const params = new URL(url).searchParams;
        return params.get(key);
    }

    async getPicklistHierarchy() {
        try {
            this.optionGroups = await apexGetPicklistHierarchy();
        } catch (e) {
            this.error = JSON.stringify(e);
        }
    }

    async connectedCallback() {
        this.addRow();
        this.addSecondRow();
        this.formId = this.getUrlParamValue(window.location.href, 'formid');
        await this.getPicklistHierarchy();
        if (this.isCertify) {
            this.valid = await apexCheckLinkValidity({formId: this.formId});
            await this.getRejectionReasons();
        }
        await this.getForm();
        await apexRemoveOldFiles({formId: this.form.Id});
        if (this.isApply) {
            await this.createTemporary();
            const preselectedLfNum = this.getUrlParamValue(window.location.href, 'lfnummer');
            if (preselectedLfNum && preselectedLfNum != null) {
                await this.getPreselectedLf(preselectedLfNum);
            }
        }
        await this.getKommuns();
    }

    async getPreselectedLf(preselectedLfNum) {
        try {
            const lf = await apexGetPreselectedLf({lfNumber: preselectedLfNum});
            this.selectedLF = lf;
            this.lfPreselected = true;
        } catch (e) {
            this.error = JSON.stringify(e);
        }
    }

    async getRejectionReasons() {
        try {
            this.rejectionReasons = await apexGetRejectionReasons();
        } catch (e) {
            this.error = JSON.stringify(e);
        }
    }

    async getForm() {
        if (this.isApply) {
            await this.emptyForm();
        } else if (this.isCertify) {
            await this.loadForm();
        }
    }

    async createTemporary() {
        try {
            this.temporaryId = await apexCreateTemporary();
        } catch (ex) {
            this.error = ex;
        }
    }

    handleUploadFinished(event) {
        const files = event.detail.files;
        this.uploadedFiles = [...this.uploadedFiles, ...files.map(
            file => ({
                name: file.name,
                index: file.contentVersionId
            })
        )];
    }

    add() {
        this.tableErrors = [];
        this.data.push(
            {
                XC_Fornamn__c: '',
                XC_Efternamn__c: '',
                XC_Fodelsear__c: null,
                XC_Personnummer__c: '',
                rowIndex: ++this.maxIndex
            }
        );
    }

    remove(evt) {
        const roww = evt.target.dataset.rowIndex;
        this.data = this.data.filter(row => {
            return row.rowIndex != roww;
        });
    }

    onInputChange(evt) {
        this.tableErrors = []
        const {index, value, field} = evt.detail;
        let el = this.data.find(el => el.rowIndex == index);
        el[field] = value;
    }

    inputChange(evt) {
        const {dataset, value, checked, type} = evt.target;
        if (type !== 'checkbox') {
            this.form[dataset.field] = value;
        } else {
            this.form[dataset.field] = checked;
        }
        if (dataset.field === 'XC_IntygsskrivarensInfo__c') {
            this.template.querySelector('span[data-id="filesInfo"]').classList.remove('xc-red');
        }
        if (dataset.inputType === 'finance') {
            try {
                const financeInputs = [...this.template.querySelectorAll('lightning-input[data-input-type="finance"]')];
                this.form.XC_Totalsumma_kr__c = financeInputs.reduce(
                    (start, el) => start + (parseFloat(el.value ) || 0.0), 0.0
                );
            } catch (e) {
                this.error = JSON.stringify(e);
            }

            this.template.querySelector('lightning-input[data-field="XC_Totalsumma_kr__c"]').value = this.form.XC_Totalsumma_kr__c;
        }
    }

    async save() {
        if (!this.validate()) {
            return;
        }
        try {
            if (this.isApply) {
                try {
                    this.isLoading = true;
                    this.form.Id = this.temporaryId;
                    this.form.XC_LF__c = this.selectedLF.Id;
                    this.form.XC_LinkValidDate__c = this.selectedLF.XC_CurrentApplicationDate__c;
                    delete this.form.uppgifterna;
                    delete this.form.integritetspolicy;
                    this.createdId = await apexApply({application: this.form, children: this.data});
                } catch (e) {
                    this.error = JSON.stringify(e);
                    console.log('err ' + this.error);
                } finally {
                    this.isLoading = false;
                }

            } else if (this.isCertify) {
                try {
                    this.isLoading = true;
                    this.form.XC_UpdatedByCertifier__c = true;
                    await apexUpdateApplication({form: this.form});
                    this.success = true;
                } catch (e) {
                    this.error = JSON.stringify(e);
                } finally {
                    this.isLoading = false;
                }
            }

        } catch (e) {
            this.error = JSON.stringify(e);
        }
    }

    validate() {
        if (this.isApply) {
            return this.validateApply();
        } else if (this.isCertify) {
            return this.validateCertify();
        }
    }

    validateCertify() {
        const approved = this.form.XC_ApprovedByCertifier__c;
        if (approved) {
            delete this.form.XC_CertifierRejectionReason__c;
            delete this.form.XC_CertifierRejectionInfo__c;
        } else {
            delete this.form.XC_IntygsskrivarensInfo__c;
        }
        let valid = true;
        this.template.querySelectorAll('[data-validity-check="true"]').forEach(
            el => {
                if (!el.checkValidity()) {
                    el.reportValidity();
                    valid = false;
                }
            }
        );
        return valid;
    }

    validateApply() {
        if (!this.selectedLF) {
            this.handleScrollClick('select');
            return false;
        }
        if (this.intygsEmailNotTheSame) {
            this.handleScrollClick('[data-id="intygs-emails-not-the-same"]');
            return false;
        }
        if (this.emailNotTheSame) {
            this.handleScrollClick('[data-id="emails-not-the-same"]');
            return false;
        }
        if (this.form.XC_Totalsumma_kr__c === 0) {
            this.handleScrollClick('span[data-id="totalsumma"]');
            return false;
        }
        if (this.form.XC_Epost__c?.length && this.form.XC_IntygsskrivarensEpost__c?.length && this.form.XC_Epost__c === this.form.XC_IntygsskrivarensEpost__c) {
            this.template.querySelector('span[data-id="intygsgivarenspost"]').classList.remove('hide');
            this.template.querySelector('span[data-id="intygsgivarenspost"]').classList.add('show-inline');
            this.handleScrollClick('span[data-id="intygsgivarenspost"]');
            return false;
        } else {
            this.template.querySelector('span[data-id="intygsgivarenspost"]').classList.add('hide');
            this.template.querySelector('span[data-id="intygsgivarenspost"]').classList.remove('show-inline');
        }
        let tableValid = true;
        let inputsValid = true;
        this.tableErrors = [];
        if (this.data.length === 0) {
            this.tableErrors.push(labels.AT_LEAST_ONE_ROW);
            tableValid = false;
        } else {
            const uniqueNumbers = new Set(this.data.map(el => el.XC_Personnummer__c));
            if (uniqueNumbers.size !== this.data.length) {
                this.tableErrors.push(labels.DUPLICATE_CHILD);
                this.handleScrollClick('tbody');
                tableValid = false;
            }
            this.template.querySelectorAll('c-table-input').forEach(
                el => {
                    if (!el.validate()) {
                        inputsValid = false;
                    }
                }
            );
            if (!inputsValid) {
                this.tableErrors.push(labels.ALL_FIELDS_COMPLETED);
                this.handleScrollClick('tbody');
                return false;
            }
            let agesCorrect = true;
            this.data.forEach(child => {
                if (child.XC_Fodelsear__c < new Date().getFullYear() - 19) {
                    agesCorrect = false;
                }
            });
            if (!agesCorrect) {
                this.tableErrors.push(labels.YEAR_TOO_LOW);
                tableValid = false;
            }
        }

        if (!tableValid) {
            console.log('scrolling...');
            this.handleScrollClick('tbody');
            return false;
        }

        let valid = true;
        this.template.querySelectorAll('[data-validity-check="true"]').forEach(
            el => {
                if (!el.checkValidity()) {
                    el.reportValidity();
                    valid = false;
                }
            }
        );
        this.template.querySelector('span[data-id="filesInfo"]').classList.remove('xc-red');
        if ((!(this.declaredFiles.length && this.uploadedFiles.length) && !this.form.XC_IntygsskrivarensEpost__c)) {
            let valid = false;
            this.template.querySelector('span[data-id="filesInfo"]').classList.add('xc-red');
            return valid;
        }
        if (!valid) {
            if (this.isApply) {
                this.handleScrollClick('tbody');
            }
        }
        return valid;
    }

    handleScrollClick(selector) {
        const topDiv = this.template.querySelector(selector);
        topDiv.scrollIntoView();
    }

    handleDeclaredFilesChange(evt) {
        this.template.querySelector('span[data-id="filesInfo"]').classList.remove('xc-red');
        this.declaredFiles = evt.detail.value;
    }

    get nextApplicationDates() {
        const applicationDates = [];
        if (this.selectedLF.XC_NextApplicationDate__c) {
            applicationDates.push(this.selectedLF.XC_NextApplicationDate__c);
        }
        if (this.selectedLF.XC_NextApplicationDate1__c) {
            applicationDates.push(this.selectedLF.XC_NextApplicationDate1__c);
        }
        if (this.selectedLF.XC_NextApplicationDate2__c) {
            applicationDates.push(this.selectedLF.XC_NextApplicationDate2__c);
        }
        if (applicationDates.length) {
            return applicationDates.join(', ');
        }
    }

    async getKommuns() {
        try {
            const kommunns = await apexGetKommuns();
            this._kommunner = kommunns.reduce((prev, curr) => {
                if (!prev[curr.XC_Lan__c]) {
                    prev[curr.XC_Lan__c] = [];
                }
                prev[curr.XC_Lan__c].push(curr.Name);
                return prev;
            }, {});
        } catch (error) {
            this.error = 'Error when pulling lans';
        }
    }

    async getLfs() {
        try {
            this.lfs = await apexGetLfs({kommun: this.selectedKommunn});
        } catch (e) {
            this.error = e;
        }
    }

}