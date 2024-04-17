import { api, LightningElement } from 'lwc';
import {CloseActionScreenEvent} from "lightning/actions";
import getAccount from '@salesforce/apex/PrintingFormsControllerLWC.getAccount';
import hasPermission from '@salesforce/customPermission/Utskick_av_Medlemsregister';
export default class SendForm extends LightningElement {

    isLoading = false;
    _recordId;
    record;
    hasPermission = hasPermission;

    get isRiks() {
        return this.record?.Name === 'RIKS';
    }

    get showRiks() {
        return this.isRiks && this.hasPermission;
    }

    get showSingle() {
        return !this.isRiks && this.hasPermission;
    }

    @api
    set recordId(recId) {
        this._recordId = recId;
        this.getAccount();
        console.log('acc : ' + JSON.stringify(this.record));
    }

    get recordId() {
        return this._recordId;
    }


    async getAccount() {
        if (!hasPermission) {
            return;
        }
        this.isLoading = true;
        try {
            this.record = await getAccount({accId: this.recordId});
        } catch (ex) {
            console.log('EXCEPTION' + ex);
        } finally {
            this.isLoading = false;
        }

    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

}