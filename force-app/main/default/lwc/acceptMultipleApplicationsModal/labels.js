import selectFirstApprover from '@salesforce/label/c.Select_First_Approver';
import selectSecondApprover from '@salesforce/label/c.Select_Second_Approver';
import approvedAmount from '@salesforce/label/c.Approved_amount';
import acceptedNotesReasons from '@salesforce/label/c.Accepted_notes_reasons';
import approve from '@salesforce/label/c.Approve';
import cancel from '@salesforce/label/c.Cancel';
import pleaseSelectAtLeastOneApprover from '@salesforce/label/c.Please_select_at_least_one_approver';

export default {
    SELECT_FIRST_APPROVER: selectFirstApprover,
    SELECT_SECOND_APPROVER: selectSecondApprover,
    APPROVED_AMOUNT: approvedAmount,
    ACCEPTED_NOTES_REASONS: acceptedNotesReasons,
    APPROVE: approve,
    CANCEL: cancel,
    PLEASE_SELECT_ONE_APPROVER: pleaseSelectAtLeastOneApprover,
};