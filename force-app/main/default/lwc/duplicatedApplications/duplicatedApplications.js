import {LightningElement, api } from 'lwc';
import apexGetDuplicated from '@salesforce/apex/ApplicationFormsController.getDuplicated';

export default class DuplicatedApplications extends LightningElement {

    duplicated = [];

    _id;

    @api set recordId(rid) {
        this._id = rid;
        this.getDuplicated();
    }

    get recordId() {
        return this._id;
    }

    async getDuplicated() {
        try {
            this.duplicated = await apexGetDuplicated({appId: this.recordId})
            this.duplicated = [...this.duplicated.map(dup => Object.assign({...dup}, {
                link: this.getLink(dup.Id)
            }))];
            console.log(JSON.stringify(this.duplicated, null, 2));
            this.getLink();
        } catch (e) {
            console.log(e);
        }
    }

    getLink(id) {
        const url = new URL(window.location.href);
        return `${url.href.slice(0, url.href.search(this.recordId))}${id}/view`;
    }


}