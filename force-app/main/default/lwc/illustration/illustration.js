/**
 * Created by lukasz on 06/10/2022.
 */

import {LightningElement, api} from 'lwc';
import ILLUSTRATIONS from '@salesforce/resourceUrl/illustrations';

export default class Illustration extends LightningElement {

    @api type = 'not-available';
    @api title;
    @api size = 'small';

    get illustrationClasses() {
        return `slds-illustration slds-illustration_${this.size}`;
    }

    illustrationPath;

    connectedCallback() {
        this.illustrationPath = `${ILLUSTRATIONS}/${this.type}.svg`;
    }
}