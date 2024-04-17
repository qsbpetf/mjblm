public with sharing class XC_CreateSavePrintingForms implements Database.Batchable<SObject>, Database.Stateful {

    @TestVisible private static Integer emailsSent = 0;
    @TestVisible private List<Account> accountsNotSentEmail = new List<Account>();

    private Integer no = 0;
    private Boolean sendImmediately = false;
    private Boolean saveToFiles = false;
    private Account riksAcc;

    public XC_CreateSavePrintingForms(Boolean sendImmediately, Boolean saveToFiles) {
        this.sendImmediately = sendImmediately;
        this.saveToFiles = saveToFiles;
        this.riksAcc = [SELECT Id FROM Account WHERE Name = 'RIKS'];
    }

    public List<Account> start(Database.BatchableContext ctx) {
        return [SELECT Id, XC_LF_Nummer2__c FROM Account WHERE RecordType.Id = :getLFId() AND Name != 'RIKS' AND LF_Status__c = 'Aktiv'];
    }

    public void execute(Database.BatchableContext cts, List<Account> scope) {

        List<Account> accsWithAffs = [SELECT Id, Name, XC_LF_Nummer2__c, (SELECT XC_E_post__c, XC_Medlemskategorier__c FROM npe5__Affiliations__r WHERE XC_E_post__c != null AND npe5__Status__c = 'Current') FROM Account WHERE Id IN: scope];

        Map<Account, ContentVersion> accountsWithContentVersions = new Map<Account, ContentVersion>();

        Map<Id, Account> accToUpdate = new Map<Id, Account>();

        if (saveToFiles) {
            Set<String> lfNumbers = new Set<String>();
            for (Account acc : accsWithAffs) {
                lfNumbers.add(String.valueOf(acc.XC_LF_Nummer2__c));
            }
            Set<Id> cvs = new Set<Id>();
            for (ContentVersion cv : [SELECT ContentDocumentId FROM ContentVersion WHERE XC_LF_Nummer__c IN :lfNumbers]) {
                cvs.add(cv.ContentDocumentId);
            }
            if (!cvs.isEmpty()) {
                List<ContentDocument> contentsToDelete = [SELECT Id FROM ContentDocument WHERE Id IN :cvs];
                delete contentsToDelete;
            }
            for (Account lfAccount : accsWithAffs) {
                Blob Attachment = getAttachment(lfAccount.Id);
                DateTime dt = DateTime.now();
                String dateStr = dt.format('yyyy/MM/dd:hh:mm:ss');


                ContentVersion cVersion = new ContentVersion();
                cVersion.ContentLocation = 'S';
                cVersion.Title = lfAccount.XC_LF_Nummer2__c + '_' + dateStr;
                cVersion.PathOnClient = cVersion.Title +'.pdf';
                cVersion.VersionData = attachment;
                cVersion.XC_LF_Nummer__c = String.valueOf(lfAccount.XC_LF_Nummer2__c);
                accountsWithContentVersions.put(lfAccount, cVersion);
            }

            insert accountsWithContentVersions.values();
            Map<Id, ContentVersion> cVersions = new Map<Id, ContentVersion>([SELECT ContentDocumentId FROM ContentVersion Where Id IN:accountsWithContentVersions.values()]);

            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            if (riksAcc != null ) {
                for (Account acc : accountsWithContentVersions.keySet()) {
                    ContentDocumentLink cDocLink = new ContentDocumentLink();
                    cDocLink.ContentDocumentId = cVersions.get(accountsWithContentVersions.get(acc).Id).ContentDocumentId;
                    cDocLink.LinkedEntityId = riksAcc.Id;
                    links.add(cDocLink);
                }
            }

            for (Account acc : accountsWithContentVersions.keySet()) {
                ContentDocumentLink cDocLink = new ContentDocumentLink();
                cDocLink.ContentDocumentId = cVersions.get(accountsWithContentVersions.get(acc).Id).ContentDocumentId;
                cDocLink.LinkedEntityId = acc.Id;
                links.add(cDocLink);
                if (!accToUpdate.containsKey(acc.Id)) {
                    accToUpdate.put(acc.Id, new Account());
                }
                Account accc = accToUpdate.get(acc.Id);
                accc.Id = acc.Id;
                accc.XC_Date_Last_Member_Form_Generated__c = Date.today();
            }

            insert links;
        }


        if (sendImmediately) {
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            for (Account lfAccount : accsWithAffs) {
                Blob Attachment = getAttachment(lfAccount.Id);
                List<npe5__Affiliation__c> recipients = getRecipients(lfAccount);
                System.debug('recipients  ' + recipients);
                if (recipients.isEmpty()) {
                    accountsNotSentEmail.add(lfAccount);
                    continue;
                }
                for (npe5__Affiliation__c aff : recipients) {
                    emails.add(getMessage(attachment, String.valueOf(lfAccount.XC_LF_Nummer2__c), aff.XC_E_post__c));
                }
                if (!accToUpdate.containsKey(lfAccount.Id)) {
                    accToUpdate.put(lfAccount.Id, new Account());
                }
                Account accc = accToUpdate.get(lfAccount.Id);
                accc.Id = lfAccount.Id;
                accc.XC_Date_Last_Member_Form_Sent__c = Date.today();
            }

            try {
                Messaging.SendEmailResult [] r1 = Messaging.sendEmail(emails);
                emailsSent += emails.size();
            } catch (Exception e) {
                System.debug(e);
            }
        }
        update accToUpdate.values();

    }

    public void finish(Database.BatchableContext ctx) {
        System.debug('accountsNotSentEmail ' + accountsNotSentEmail );
        if (accountsNotSentEmail.isEmpty()) {
            return;
        }
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage emailTobeSent = new Messaging.SingleEmailMessage();
        List<String> listEmailMembers = new List<String>();
        listEmailMembers.addAll(getEmailsToSendSummary());
        System.debug('listEmailMembers ' + listEmailMembers );
        emailTobeSent.setToAddresses(listEmailMembers);
        emailTobeSent.setSubject('Medlemsregister not completed');
        String body = 'Hi, because of missing a person applicable to receive the form, the Member Forms were not sent to the following Accounts:<br>';
        Integer count = 1;
        for (Account acc : accountsNotSentEmail) {
            body += String.valueOf(count++) + '. ' + acc.Name + ' - ' + String.valueOf(acc.XC_LF_Nummer2__c) + '<br>';
        }
        emailTobeSent.setHtmlBody(body);
        emails.add(emailTobeSent);
        Messaging.sendEmail(emails);
    }


    public static Id getLFId() {
        return [select Name FROM recordtype where DeveloperName = 'XC_Lokalforening'].Id;
    }

    private static List<npe5__Affiliation__c> getRecipients(Account acc) {
        List<npe5__Affiliation__c> relatedAffiliations = acc.npe5__Affiliations__r;
        if (relatedAffiliations == null || relatedAffiliations.isEmpty()) {
            return new List<npe5__Affiliation__c>();
        }
        List<npe5__Affiliation__c> secretaries = new List<npe5__Affiliation__c>();
        for (npe5__Affiliation__c aff : relatedAffiliations) {
            String categories = aff.XC_Medlemskategorier__c;
            if (categories != null && String.isNotEmpty(categories) && categories.split(';').contains('B - Sekreterare')) {
                secretaries.add(aff);
            }
        }
        return secretaries;
    }

    private static Blob getAttachment(Id accountId) {
        PageReference PDf =  Page.PrintingFormVF;
        PDf.getParameters().put('Id', accountId);
        PDf.setRedirect(true);
        Attachment attach = new Attachment();
        Blob b ;
        if (Test.isRunningTest()) {
            b = blob.valueOf('UnitTest');
        } else {
            b = PDf.getContent();
        }
        return b;
    }

    public static Messaging.SingleEmailMessage getMessage(Blob attachment, String lfNumber, String email) {
        Messaging.SingleEmailMessage emailTobeSent = new Messaging.SingleEmailMessage();
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName('Medlemsregister_LF_' + lfNumber + '.pdf');
        efa.setBody(attachment);
        List<String> listEmailMembers = new List<String>();
        listEmailMembers.add(email);
        emailTobeSent.setToAddresses(listEmailMembers);
        emailTobeSent.setSubject('Medlemsregister ' + String.valueOf(Date.today().year()));
        emailTobeSent.setHtmlBody('Medlemsregister ' + String.valueOf(Date.today().year()));
        emailTobeSent.setFileAttachments(new Messaging.EmailFileAttachment[] { efa });
        return emailTobeSent;
    }

    public static List<String> getEmailsToSendSummary() {
        List<String> emails = new List<String>();
        for (Email_for_printing_forms_summary__mdt email : [SELECT Email__c FROM Email_for_printing_forms_summary__mdt]) {
            emails.add(email.Email__c);
        }
        return emails;
    }
}