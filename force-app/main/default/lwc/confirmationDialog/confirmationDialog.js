/**
 * Created by lukasz on 15/09/2022.
 */

import {api, LightningElement} from 'lwc';
import labels from './labels';

export default class ConfirmationDialog extends LightningElement {

    labels = labels;

    _visible = false;
    _question;
    _confirmLabel;
    _rejectLabel;
    _title;

    @api closable = false;

    @api set confirmLabel(confirmLbl) {
        this._confirmLabel = confirmLbl;
    }
    @api set rejectLabel(rejectLbl) {
        this._rejectLabel = rejectLbl;
    }
    @api set title(title) {
        this._title = title;
    }

    @api open(msg) {
        this._question = msg;
        this._visible = true;
    }
    @api close() {
        this._visible = false;
    }

    get question() {
        return this._question || "Do you want to proceed?";
    }
    get confirmLabel() {
        return this._confirmLabel || labels.YES;
    }
    get rejectLabel() {
        return this._rejectLabel || labels.NO;
    }
    get title() {
        return this._title || labels.CONFIRM;
    }
    get visible() {
        return this._visible;
    }

    handleReject() {
        this.dispatchEvent(new CustomEvent("reject"));
    }

    handleConfirm() {
        this.dispatchEvent(new CustomEvent("confirm"));
    }
}