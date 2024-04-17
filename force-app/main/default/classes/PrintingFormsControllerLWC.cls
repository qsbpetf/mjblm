public with sharing class PrintingFormsControllerLWC {

    @TestVisible private static Integer emailsSent = 0;

    @AuraEnabled
    public static List<npe5__Affiliation__c> getDefaultRecipientsForAccount(Id accId) {
        return [SELECT npe5__Contact__r.Name, XC_E_post__c, XC_Medlemskategorier__c  FROM npe5__Affiliation__c WHERE npe5__Organization__c = :accId AND npe5__Status__c = 'Current'];
    }

    @AuraEnabled
    public static Account getAccount(Id accId) {
        List<Account> accs = [SELECT Name FROM Account WHERE Id = :accId LIMIT 1];
        if (!accs.isEmpty()) {
            return accs[0];
        } else {
            return null;
        }
    }
    @AuraEnabled
    public static void createFormsSingle(Boolean sendImmediately, Boolean saveToFiles, Id accountId, List<Id> memberAccountsIds) {

        String lfNumber = String.valueOf([SELECT XC_LF_Nummer2__c FROM Account WHERE Id = :accountId].XC_LF_Nummer2__c);

        Map<Id, npe5__Affiliation__c> affiliationsWithEmails = new Map<Id, npe5__Affiliation__c> ([SELECT XC_E_post__c FROM npe5__Affiliation__c WHERE XC_E_post__c != null AND npe5__Status__c = 'Current']);

        Blob attachment = getAttachment(accountId);

        Account accToUpdate = new Account(Id = accountId);

        if (saveToFiles) {
            Set<Id> cvs = new Set<Id>();
            for (ContentVersion cv : [SELECT ContentDocumentId FROM ContentVersion WHERE XC_LF_Nummer__c = :lfNumber]) {
                cvs.add(cv.ContentDocumentId);
            }
            if (!cvs.isEmpty()) {
                List<ContentDocument> contentsToDelete = [SELECT Id FROM ContentDocument WHERE Id IN :cvs];
                delete contentsToDelete;
            }

            Account riksAcc = [SELECT Id FROM Account WHERE Name = 'RIKS'];

            DateTime dt = DateTime.now();
            String dateStr = dt.format('yyyy/MM/dd:hh:mm:ss');

            ContentVersion cVersion = new ContentVersion();
            cVersion.ContentLocation = 'S';
            cVersion.Title = lfNumber + '_' + dateStr;
            cVersion.PathOnClient = cVersion.Title +'.pdf';
            cVersion.VersionData = attachment;
            cVersion.XC_LF_Nummer__c = lfNumber;
            insert cVersion;

            Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion.id].contentDocumentId;

            System.debug('conDocument ' + conDocument);

            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            if (riksAcc != null ) {
                ContentDocumentLink cDocLink = new ContentDocumentLink();
                cDocLink.ContentDocumentId = conDocument;
                cDocLink.LinkedEntityId = riksAcc.Id;
                links.add(cDocLink);
            }

            ContentDocumentLink cDocLink = new ContentDocumentLink();
            cDocLink = new ContentDocumentLink();
            cDocLink.ContentDocumentId = conDocument;
            cDocLink.LinkedEntityId = accountId;
            links.add(cDocLink);
            System.debug('links ' + links);
            accToUpdate.XC_Date_Last_Member_Form_Generated__c = Date.today();

            insert links;
        }

        if (sendImmediately) {
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            for (Id memberId : memberAccountsIds) {
                if (!affiliationsWithEmails.containsKey(memberId)) {
                    continue;
                }
                emails.add(getMessage(attachment, lfNumber, affiliationsWithEmails.get(memberId).XC_E_post__c));
            }
            if (!emails.isEmpty()) {
                try {
                    emailsSent++;
                    Messaging.SendEmailResult [] r1 = Messaging.sendEmail(emails);
                } catch (Exception e) {
                    System.debug(e);
                }
            }
            accToUpdate.XC_Date_Last_Member_Form_Sent__c = Date.today();
        }
        if (accToUpdate.XC_Date_Last_Member_Form_Sent__c != null || accToUpdate.XC_Date_Last_Member_Form_Generated__c != null) {
            update accToUpdate;
        }
    }

    @AuraEnabled
    public static void createFormsRiks(Boolean sendImmediately, Boolean saveToFiles) {
        Database.executeBatch(new XC_CreateSavePrintingForms(sendImmediately, saveToFiles), 10);
    }

    private static Blob getAttachment(Id accountId) {
        PageReference PDf =  Page.PrintingFormVF;
        PDf.getParameters().put('Id', accountId);
        PDf.setRedirect(true);
        Attachment attach = new Attachment();
        Blob b ;
        if (Test.isRunningTest()) {
            b = Blob.valueOf('UnitTest');
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

    private class TestException extends Exception{}

}