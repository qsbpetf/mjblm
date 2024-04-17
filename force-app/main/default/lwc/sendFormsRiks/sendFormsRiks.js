/**
 * Created by lukasz on 22/09/2022.
 */

import {LightningElement} from 'lwc';
import createFormsRiks from '@salesforce/apex/PrintingFormsControllerLWC.createFormsRiks';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import labels from './labels'


export default class SendFormsRiks extends LightningElement {
    labels = labels;

    isLoading = false;

    sendForms = false;
    saveFiles = false;


    createForms() {
        this.confirm('Are you sure?');
        console.log('creating forms');
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

    get buttonDisabled() {
        return !this.sendForms && !this.saveFiles;
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
            console.log(JSON.stringify({ sendImmediately: this.sendForms, saveToFiles: this.saveFiles }));
            await createFormsRiks({ sendImmediately: this.sendForms, saveToFiles: this.saveFiles });
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Request sent correctly. Sending process may take a while.',
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