/**
 * Created by lukasz on 09/12/2022.
 */

import {LightningElement} from 'lwc';
import {NavigationMixin} from "lightning/navigation";
import apexGetCurrentUserAccount from '@salesforce/apex/ApplicationFormsController.getCurrentUserAccountId';

export default class NavigateToAccount extends NavigationMixin(LightningElement) {

    error;
    accId;

    async connectedCallback() {
        await this.getCurrentUserAccount();
        if (this.accId) {
            this.navigate();
        }
    }

    async getCurrentUserAccount() {
        try {
            this.accId = await apexGetCurrentUserAccount();
        } catch (e) {
            this.error = 'Error loading Account id';
        }
    }

    navigate() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.accId,
                objectApiName: 'Account',
                actionName: 'view'
            },
        });
    }

}