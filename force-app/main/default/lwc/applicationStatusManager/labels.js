import cancel from '@salesforce/label/c.Cancel';
import rejectedBy from '@salesforce/label/c.Rejected_By';
import rejectedNotesReasons from '@salesforce/label/c.Rejected_Notes_Reasons';
import pleaseSelectRejecter from '@salesforce/label/c.Please_select_rejecting_person';
import reject from '@salesforce/label/c.Reject';
import approve from '@salesforce/label/c.Approve';
import save from '@salesforce/label/c.Save';

export default {
    CANCEL: cancel,
    REJECTED_BY: rejectedBy,
    REJECTED_NOTES_REASONS: rejectedNotesReasons,
    SELECT_REJECTER: pleaseSelectRejecter,
    REJECT: reject,
    APPROVE: approve,
    SAVE: save
};