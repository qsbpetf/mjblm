import selectLan from '@salesforce/label/c.Select_Lan';
import selectKommunn from '@salesforce/label/c.Select_Kommun';
import selectLf from '@salesforce/label/c.Select_LF';
import certifierOrFile from '@salesforce/label/c.Certifier_or_file';
import declaredFiles from '@salesforce/label/c.Declared_Files';
import allFieldsCompleted from '@salesforce/label/c.Make_sure_all_fields_completed';
import atLeastOneRow from '@salesforce/label/c.Please_select_at_least_one_row';
import applicantConfirmationScreen from '@salesforce/label/c.Applicant_Confirmation_Screen';
import certifierConfirmationScreen from '@salesforce/label/c.Certifier_Confirmation_Screen';
import infoTextAttachments from '@salesforce/label/c.Info_Text_Attachments';
import infoTextIntygsgivarePost from '@salesforce/label/c.Info_text_for_Intygsgivare_e_post';
import infoTextSelectLanKommunn from '@salesforce/label/c.Info_text_for_selecting_L_n_Kommun_LF';
import yearTooLow from '@salesforce/label/c.Year_too_low';
import totalSummaNotZero from '@salesforce/label/c.Total_summa_not_zero';
import emailsNotTheSame from '@salesforce/label/c.Emails_not_the_same';
import save from '@salesforce/label/c.Save';
import yearPatternMismatch from '@salesforce/label/c.Year_pattern_Mismatch';
import duplicateChild from '@salesforce/label/c.Duplicate_child';
import infoText from '@salesforce/label/c.Informational_Text';
import intygEpostInfo from '@salesforce/label/c.Intyg_Epost_Info';
import confirmEmailFailMsg from '@salesforce/label/c.Confirm_Email_Fail_Message';
import integritetspolicy from '@salesforce/label/c.Integritetspolicy';
import uppgifterna from '@salesforce/label/c.Uppgifterna';

export default {
    SELECT_LAN: selectLan,
    SELECT_KOMMUNN: selectKommunn,
    SELECT_LF: selectLf,
    CERTIFIER_OR_FILE: certifierOrFile,
    DECLARED_FILES: declaredFiles,
    ALL_FIELDS_COMPLETED: allFieldsCompleted,
    AT_LEAST_ONE_ROW: atLeastOneRow,
    APPLICANT_CONFIRMATION_SCREEN: applicantConfirmationScreen,
    CERTIFIER_CONFIRMATION_SCREEN: certifierConfirmationScreen,
    INFO_TEXT_ATTACHMENTS: infoTextAttachments,
    INFO_TEXT_INTYGSGIVARE_EPOST: infoTextIntygsgivarePost,
    INFO_TEXT_SELECT_LAN_KOMMUNN: infoTextSelectLanKommunn,
    YEAR_TOO_LOW: yearTooLow,
    TOTALSUMMA_NOT_ZERO: totalSummaNotZero,
    EMAILS_NOT_THE_SAME: emailsNotTheSame,
    SAVE: save,
    YEAR_PATTERN_MISMATCH: yearPatternMismatch,
    DUPLICATE_CHILD: duplicateChild,
    INFO_TEXT: infoText,
    INTYG_EPOST_INFO: intygEpostInfo,
    CONFIRM_EMAIL_FAIL_MSG: confirmEmailFailMsg,
    INTEGRITETSPOLICY: integritetspolicy,
    UPPGIFTERNA: uppgifterna
};