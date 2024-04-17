/**
 * Created by lukasz on 18/11/2022.
 */

import { LightningElement, api } from 'lwc';

export default class TableInput extends LightningElement {

    @api row;
    @api column;
    @api readonlyy;

    @api validate() {
        if (this.column.min && this.value < this.column.min) {
            return false;
        }
        return this.value && this.value.length > 0 && this.template.querySelector('lightning-input').checkValidity();
    }

    set value(val) {
        this.row[this.column.fieldName] = val;
    }

    get value() {
        return this.row[this.column.fieldName];
    }

    inputChange(evt) {
        this.dispatchEvent(new CustomEvent('inputchange', { detail: { index: this.row.rowIndex, value: evt.target.value, field: this.column.fieldName} } ));
    }
}