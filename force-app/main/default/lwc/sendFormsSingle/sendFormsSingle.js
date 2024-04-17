import { api, LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDefaultRecipientsForAccount from '@salesforce/apex/PrintingFormsControllerLWC.getDefaultRecipientsForAccount';
import createFormsSingle from '@salesforce/apex/PrintingFormsControllerLWC.createFormsSingle';
import labels from './labels';

export default class SendFormsSingle extends LightningElement {

    labels = labels;

    isLoading = false;

    _recordId;

    sendForms = false;
    saveFiles = false;

    _selected = [];

    selected = [];
    candidates = [];

    get hasSelected() {
        return this.selected.length;
    }

    get selectedEmpty() {
        return !this.hasSelected;
    }

    checkboxChanged(event) {
        const action = event.target.dataset.id;
        if (action === 'send') {
            this.sendForms = event.target.checked;
        } else if (action === 'save') {
            this.saveFiles = event.target.checked;
        }
        console.log(this.sendForms + ' ' + this.saveFiles);
    }

    @api
    set recordId(recId) {
        this._recordId = recId;
        this.getRecipients();
    }

    checkboxChanged(event) {
        const action = event.target.dataset.id;
        if (action === 'send') {
            this.sendForms = event.target.checked;
        } else if (action === 'save') {
            this.saveFiles = event.target.checked;
        }
    }

    createForm() {
        console.log('this.allRecipientsWithNoEmail() ' + this.allRecipientsWithNoEmail());
        if (this.allRecipientsWithNoEmail() && this.sendForms) {
            this.dispatchEvent(new ShowToastEvent({
                title: labels.NO_RECIPIENTS_WITH_ADDRESS,
                message: labels.NONE_OF_SELECTED_RECIPIENTS_EMAIL,
                variant: 'warning'
            }));
            return;
        }

        if (this.someRecipientsWithNoEmail()) {
            this.confirm(labels.SOME_RECIPIENTS_NO_EMAIL);
        } else {
            this.send();
        }
    }


    get recordId() {
        return this._recordId;
    }

    get hasSelected() {
        return this.selected.length;
    }
    get buttonDisabled() {
        return (!this.hasSelected && !this.saveFiles) || (!this.saveFiles && !this.sendForms);
    }

    get selectedEmpty() {
        return !this.hasSelected;
    }

    selected = [];
    candidates = [];

    get selectedRecipients() {
        return this.candidates.filter(
            rec => this.selected.includes(rec.id)
        );
    }

    async getRecipients() {
        try {
            this.isLoading = true;
            const recipients = await getDefaultRecipientsForAccount({accId: this.recordId});
            this.parseRecipients(recipients);
            console.log('this.recipients ' + this.recipients);
        } catch (ex) {
            console.log('EXCEPTION' + ex);
        } finally {
            this.isLoading = false;
        }
    }



    parseRecipients(recs) {
        const recipients = recs.map(
            rec => ({
                id: rec.Id,
                name: rec.npe5__Contact__r.Name,
                categories: rec.XC_Medlemskategorier__c ? rec.XC_Medlemskategorier__c.split(';') : [],
                label: `${rec.npe5__Contact__r.Name}${rec.XC_Medlemskategorier__c ? ' (' + rec.XC_Medlemskategorier__c + ')' : []}`,
                value: rec.Id,
                email: rec.XC_E_post__c
            })
        );

        const candidates = [];
        const preSelected = [];

        recipients.forEach(rec => {
            let description = rec.name;
            if (rec.email) {
                description += ' - ' + rec.email;
            }
            if (rec.categories.length) {
                description += ' - ' + rec.categories.join(', ');
            }
            rec['description'] = description;
            if (rec.categories.includes('B - Sekreterare')) {
                preSelected.push(rec.id);
            }
            candidates.push(rec);
        });


        this.candidates = [...candidates];
        this.selected = [...preSelected];


    }

    handleChange(e) {
        this.selected = e.detail.value;
        if (!this.selected.length) {
            this.sendForms = false;
            this.template.querySelector('[data-id="send"]').checked = false;
        }
    }

    someRecipientsWithNoEmail() {
        const noEmailRecs = [];
        this.selected.forEach(rec => {
            const selectedData = this.candidates.find(el => {
                return el.id === rec;
            });
            if (!selectedData.email) {
                noEmailRecs.push(selectedData);
            }
        });

        return !!noEmailRecs.length;
    }

    allRecipientsWithNoEmail() {
        let allRecipientsWithNoEmails = true;
        this.selected.forEach(rec => {
            const selectedData = this.candidates.find(el => {
                return el.id === rec;
            });
            if (selectedData.email) {
                allRecipientsWithNoEmails = false;
            }
        });

        return allRecipientsWithNoEmails;
    }

    set selected(val) {
        this._selected = val;
    }

    get selected() {
        return this._selected;
    }

    confirm(msg) {
        this.template.querySelector("c-confirmation-dialog").open(msg);
    }

    confirmed() {
        console.log('confirmed');
        this.send();
        this.template.querySelector("c-confirmation-dialog").close();
    }

    rejected() {
        this.template.querySelector("c-confirmation-dialog").close();
    }

    async send() {
        try {
            this.isLoading = true;
            console.log(JSON.stringify({ accountId: this.recordId, memberAccountsIds: this.selected }));
            await createFormsSingle({ sendImmediately: this.sendForms, saveToFiles: this.saveFiles, accountId: this.recordId, memberAccountsIds: this.selected });
            this.dispatchEvent(new ShowToastEvent({
                title: labels.SUCCESS,
                message: labels.REQUEST_CORRECT,
                variant: 'success'
            }));
            this.dispatchEvent(new CustomEvent('close'));
        } catch(e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: JSON.stringify(e.body.message),
                variant: 'error'
            }));
        } finally {
            this.isLoading = false;
        }
    }
}