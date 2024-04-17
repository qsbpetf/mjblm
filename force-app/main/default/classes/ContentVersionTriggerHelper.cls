public without sharing class ContentVersionTriggerHelper {

    private static final String TEMPORARY = 'Temporary';
    private static final String FROM_APPLICANT = 'Applicant';
    private static final String FROM_CERTIFIER = 'Certifier';

    public static void setFileSource(List<ContentVersion> newFiles) {
        Set<String> formsIds = new Set<String>();
        for (ContentVersion cv : newFiles) {
            formsIds.add(cv.XC_Form_fileupload__c);
        }
        Map<String, Application__c> applicationsByFormIds = new Map<String, Application__c>();
        for (Application__c app : [SELECT XC_FormId__c, XC_Status__c FROM Application__c WHERE Id IN :formsIds]) {
            applicationsByFormIds.put(app.Id, app);
        }

        for (ContentVersion cv : newFiles) {
            Application__c app = applicationsByFormIds.get(cv.XC_Form_fileupload__c);
            if (app == null) {
                continue;
            } else {
                if (TEMPORARY.equals(app.XC_Status__c)) {
                    cv.XC_AddedBy__c = FROM_APPLICANT;
                } else {
                    cv.XC_AddedBy__c = FROM_CERTIFIER;
                }
            }
        }
    }

    public static void connectToApplications(List<ContentVersion> newFiles){
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();

        for (ContentVersion cv : newFiles) {
            if (cv.XC_Form_fileupload__c == null) {
                continue;
            }
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cv.ContentDocumentId;
            cdl.LinkedEntityId = cv.XC_Form_fileupload__c;
            cdl.ShareType = 'V';
            links.add(cdl);
        }
        insert links;
    }

    public static void updateApplication(List<ContentVersion> cvs) {
        List<ContentVersion> versions = [SELECT ContentDocumentId FROM ContentVersion WHERE Id IN :cvs];
        List<Id> contentDocumentIds = new List<Id>();
        for (ContentVersion cv : versions) {
            contentDocumentIds.add(cv.ContentDocumentId);
        }

        List<ContentDocument> documents = [SELECT (SELECT LinkedEntityId FROM ContentDocumentLinks) FROM ContentDocument WHERE Id IN :contentDocumentIds];

        Set<Id> applicationsToCheck = new Set<Id>();

        for (ContentDocument document : documents) {
            if (document.ContentDocumentLinks == null || document.ContentDocumentLinks.isEmpty()) {
                continue;
            }
            for (ContentDocumentLink link : document.ContentDocumentLinks) {
                applicationsToCheck.add(link.LinkedEntityId);
            }
        }

        XC_UpdateFilesCount.start(applicationsToCheck);
    }

}