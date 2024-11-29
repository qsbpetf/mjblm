public with sharing class ApplicationTriggerHelper {

    @TestVisible
    private static Integer emailsSent = 0;
    private static final String STATUS_NEW = 'New';
    private static final String TEMPORARY = 'Temporary';
    private static final String APPROVED = 'Approved';
    private static final String ACCEPTED = 'Accepted';
    private static final String REJECTED = 'Rejected';
    private static final String ONGOING = 'Ongoing';
    private static final String APPLICATION_FORM = 'ApplicationForm';
    private static final Id siteId = [SELECT Id FROM Site WHERE Name = :APPLICATION_FORM].Id;
    private static final String URL = [SELECT SecureUrl FROM SiteDetail WHERE DurableId = :siteId].SecureUrl;
    private static final String CERTIFY_PAGE_URL_TEMPLATE = '{0}/s/certify?formid={1}';
    private static final Map<String, EmailTemplate> EMAIL_TEMPLATES = getEmailTemplates();
    private static final String APPLICATION_TEMPLATES_FOLDER = 'Application form';
    private static final String APPLICANT_WHEN_APP_SENT_TO_CERTIFIER = 'XC_NotifyApplicantSentToCertifier';
    private static final String APPLICANT_WHEN_CERTIFIER_SUBMITTED = 'XC_NotifyApplicantCertifierSubmitted';
    private static final String CERTIFIER_WHEN_THEY_SUBMITTED = 'XC_ConfirmCertifierTheySubmitted';
    private static final String CERTIFIER_LINK_TO_FORM = 'XC_CertifierNotification';
    private static final String MAJBLOMMAN_ORG_WIDE_ADDRESS_NAME = 'Majblomman Ansökningar';
    private static final String DEFAULT_QUEUE = 'XC_ApplicationsQueue';
    private static final OrgWideEmailAddress MAJBLOMMAN_ORG_WIDE_ADDRESS = getOwa();

    public static void sendInfoEmails(List<Application__c> applications, Map<Id, Application__c> oldMap) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Application__c app : applications) {
            Map<String, String> replacements = new Map<String, String> {
                    '{FormId}' => app.XC_FormId__c,
                    '{CertifierName}' => app.XC_IntygsskrivarensNamn__c,
                    '{ApplicantName}' => app.XC_Vardnadshavare__c,
                    '{link}' => getLink(app)
            };
            if (STATUS_NEW.equals(app.XC_Status__c) && TEMPORARY.equals(oldMap.get(app.Id).XC_Status__c) && app.XC_IntygsskrivarensEpost__c != null) {
                emails.add(getEmail(app.XC_IntygsskrivarensEpost__c, CERTIFIER_LINK_TO_FORM, replacements));
                emails.add(getEmail(app.XC_Epost__c, APPLICANT_WHEN_APP_SENT_TO_CERTIFIER, replacements));
            }
            if (APPROVED.equals(app.XC_Status__c) && !APPROVED.equals(oldMap.get(app.Id).XC_Status__c)) {
//                emails.add(getEmail(app.XC_IntygsskrivarensEpost__c, CERTIFIER_WHEN_APPROVED, replacements));
            }
            if (app.XC_UpdatedByCertifier__c && !oldMap.get(app.Id).XC_UpdatedByCertifier__c) {
                emails.add(getEmail(app.XC_IntygsskrivarensEpost__c, CERTIFIER_WHEN_THEY_SUBMITTED, replacements));
                if (app.XC_ApprovedByCertifier__c) {
                    emails.add(getEmail(app.XC_Epost__c, APPLICANT_WHEN_CERTIFIER_SUBMITTED, replacements));
                }


            }
        }
        if (!emails.isEmpty()) {
            emailsSent = emails.size();
            Messaging.sendEmail(emails, false);
        }
    }

    public static void setRecordType(List<Application__c> applications) {
        Map<String, RecordTypeInfo> rt = Schema.SObjectType.Application__c.getRecordTypeInfosByDeveloperName();

        for (Application__c app : applications) {
            if (APPROVED.equals(app.XC_Status__c)) {
                app.RecordTypeId = rt.get(ACCEPTED).recordTypeId;
            } else if (REJECTED.equals(app.XC_Status__c)) {
                app.RecordTypeId = rt.get(REJECTED).recordTypeId;
            } else {
                app.RecordTypeId = rt.get(ONGOING).recordTypeId;
            }
        }
    }
    public static void setStatuses(List<Application__c> applications, Map<Id, Application__c> oldMap) {
        for (Application__c app : applications) {
            if (app.XC_UpdatedByCertifier__c && !oldMap.get(app.Id).XC_UpdatedByCertifier__c && !app.XC_ApprovedByCertifier__c) {
                app.XC_Status__c = 'Rejected';
            }
        }
    }

    public static void setOwner(List<Application__c> applications, Map<Id, Application__c> oldMap) {
        Id queueId = [SELECT Queue.Id FROM QueueSobject WHERE Queue.DeveloperName = :DEFAULT_QUEUE].Queue.Id;

        Set<Id> lfIds = new Set<Id>();
        for (Application__c app : applications) {
            lfIds.add(app.XC_LF__c);
        }
        lfIds.remove(null);

        List<User> users = [SELECT AccountId FROM User WHERE AccountId IN :lfIds AND IsActive = TRUE AND Name != 'RIKS'];
        Map<Id, Id> lfToOwner = new Map<Id, Id>();
        for (User usr: users) {
            lfToOwner.put(usr.AccountId, usr.Id);
        }

        for (Application__c app : applications) {
            if (STATUS_NEW.equals(app.XC_Status__c) && TEMPORARY.equals(oldMap.get(app.Id).XC_Status__c)) {
                if (app.XC_LF__c != null && lfToOwner.containsKey(app.XC_LF__c)) {
                    app.OwnerId = lfToOwner.get(app.XC_LF__c);
                } else {
                    app.OwnerId = queueId;
                }
            }
        }
    }

    public static void setApprovedDate(List<Application__c> applications, Map<Id, Application__c> oldMap) {
        for (Application__c app : applications) {
            if (APPROVED.equals(app.XC_Status__c) && !APPROVED.equals(oldMap.get(app.Id).XC_Status__c)) {
                app.XC_ApprovedDate__c = Date.today();
            } else if (!APPROVED.equals(app.XC_Status__c) && app.XC_ApprovedDate__c != null) {
                app.XC_ApprovedDate__c = null;
            }
        }
    }

    public static void deleteRelatedFiles(List<Application__c> applications) {
        Set<Id> applicationIds = new Set<Id>();
        for (Application__c app : applications) {
            applicationIds.add(app.Id);
        }
        List<ContentVersion> relatedFiles = [SELECT ContentDocumentId FROM ContentVersion WHERE XC_Form_fileupload__c IN :applicationIds];
        Set<ContentDocument> contentDocuments = new Set<ContentDocument> ();
        for (ContentVersion cv : relatedFiles) {
            contentDocuments.add(new ContentDocument(Id = cv.ContentDocumentId));
        }
        delete new List<ContentDocument> (contentDocuments);
    }

    private static Messaging.SingleEmailMessage getEmail (String recipient, String templateNAme, Map<String, String> replacements) {
        return EmailGenerator.getNew()
                .addRecipient(recipient)
                .usingTemplate(EMAIL_TEMPLATES.get(templateNAme))
                .replace(replacements)
                .usingOrgWideAddress(MAJBLOMMAN_ORG_WIDE_ADDRESS)
                .getEmail();
    }

    private static String getLink(Application__c app) {
        return String.format(CERTIFY_PAGE_URL_TEMPLATE, new List<String>{
                URL, app.XC_FormId__c
        });
    }

    private static OrgWideEmailAddress getOwa() {
        return [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = :MAJBLOMMAN_ORG_WIDE_ADDRESS_NAME];
    }

    private static Map<String, EmailTemplate> getEmailTemplates() {
        Id folderId = [SELECT Id FROM Folder WHERE Name = :APPLICATION_TEMPLATES_FOLDER].Id;
        Map<String, EmailTemplate> templates = new Map<String, EmailTemplate> ();
        for (EmailTemplate templ : [SELECT DeveloperName, HtmlValue, Subject FROM EmailTemplate WHERE FolderId = :folderId]) {
            templates.put(templ.DeveloperName, templ);
        }
        return templates;
    }

}