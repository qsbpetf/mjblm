@IsTest
public with sharing class XC_CreateSavePrintingFormsTest {

    private static final String ACC_NAME = 'test_name_acc';
    private static final String CON_NAME = 'test_name_con';

    private static final Map<String, Id> MEMBER_RECORD_TYPE_TO_ID = XC_AccountTriggerTestHelper.getRecordTypes();
    private static final String ACC_RECORD_TYPE_LF = 'XC_Lokalforening';
    private static final String ACC_RECORD_TYPE_LF_ID = XC_AccountTriggerTestHelper.getRecordTypeId(ACC_RECORD_TYPE_LF);

    @IsTest
    static void testBatchSendEmails() {
        Account riks = new Account(Name = 'RIKS');
        insert riks;
        Account acc1 = new Account(
                Name = ACC_NAME + 1,
                LF_Status__c = 'Aktiv',
                RecordTypeId = ACC_RECORD_TYPE_LF_ID);
        Account acc2 = new Account(
                Name = ACC_NAME + 2,
                LF_Status__c = 'Aktiv',
                RecordTypeId = ACC_RECORD_TYPE_LF_ID);
        List<Account> accounts = new List<Account> { acc1, acc2 };
        insert accounts;

        Contact c1 = new Contact(LastName = CON_NAME + 1, Email = 'test@email.com');
        Contact c2 = new Contact(LastName = CON_NAME + 2, Email = 'test@email.com');
        List<Contact> contacts = new List<Contact> { c1, c2 };
        insert contacts;

        npe5__Affiliation__c aff1 = new npe5__Affiliation__c(
                npe5__Organization__c = acc1.Id,
                npe5__Contact__c = c1.Id,
                RecordTypeId = MEMBER_RECORD_TYPE_TO_ID.get(XC_Constants.MEMBER_RECORD_TYPE),
                npe5__Status__c = XC_Constants.MEMBER_ACTIVE
        );

        npe5__Affiliation__c aff2 = new npe5__Affiliation__c(
                npe5__Organization__c = acc2.Id,
                npe5__Contact__c = c2.Id,
                RecordTypeId = MEMBER_RECORD_TYPE_TO_ID.get(XC_Constants.MEMBER_RECORD_TYPE),
                npe5__Status__c = XC_Constants.MEMBER_ACTIVE,
                XC_Medlemskategorier__c = 'B - Sekreterare'
        );

        List<npe5__Affiliation__c> affiliations = new List<npe5__Affiliation__c> { aff1, aff2 };

        insert affiliations;

        XC_CreateSavePrintingForms formsBatch = new XC_CreateSavePrintingForms(true, false);

        Test.startTest();
        Database.executeBatch(formsBatch);
        Test.stopTest();

        System.assertEquals(1, XC_CreateSavePrintingForms.emailsSent);
    }

    @IsTest
    static void testBatchSaveFiles() {
        Account riks = new Account(Name = 'RIKS');
        insert riks;
        Account acc1 = new Account(
                Name = ACC_NAME + 1,
                LF_Status__c = 'Aktiv',
                RecordTypeId = ACC_RECORD_TYPE_LF_ID);
        Account acc2 = new Account(
                Name = ACC_NAME + 2,
                LF_Status__c = 'Aktiv',
                RecordTypeId = ACC_RECORD_TYPE_LF_ID);
        List<Account> accounts = new List<Account> { acc1, acc2 };
        insert accounts;

        Contact c1 = new Contact(LastName = CON_NAME + 1, Email = 'test@email.com');
        Contact c2 = new Contact(LastName = CON_NAME + 2, Email = 'test@email.com');
        List<Contact> contacts = new List<Contact> { c1, c2 };
        insert contacts;

        npe5__Affiliation__c aff1 = new npe5__Affiliation__c(
                npe5__Organization__c = acc1.Id,
                npe5__Contact__c = c1.Id,
                RecordTypeId = MEMBER_RECORD_TYPE_TO_ID.get(XC_Constants.MEMBER_RECORD_TYPE),
                npe5__Status__c = XC_Constants.MEMBER_ACTIVE
        );

        npe5__Affiliation__c aff2 = new npe5__Affiliation__c(
                npe5__Organization__c = acc2.Id,
                npe5__Contact__c = c2.Id,
                RecordTypeId = MEMBER_RECORD_TYPE_TO_ID.get(XC_Constants.MEMBER_RECORD_TYPE),
                npe5__Status__c = XC_Constants.MEMBER_ACTIVE,
                XC_Medlemskategorier__c = 'B - Sekreterare'
        );

        List<npe5__Affiliation__c> affiliations = new List<npe5__Affiliation__c> { aff1, aff2 };

        insert affiliations;

        XC_CreateSavePrintingForms formsBatch = new XC_CreateSavePrintingForms(false, true);

        Test.startTest();
        Database.executeBatch(formsBatch);
        Test.stopTest();

        List<ContentVersion> createdContentVersions = [SELECT XC_LF_Nummer__c, ContentDocumentId FROM ContentVersion];
        System.assertEquals(2, createdContentVersions.size());

        Set<Id> contentDocumentsIds = new Set<Id>();

        for (ContentVersion cv : createdContentVersions) {
            contentDocumentsIds.add(cv.ContentDocumentId);
        }

        List<ContentDocumentLink> links = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN :contentDocumentsIds];
        System.debug('links in test ' + links);

        List<ContentDocumentLink> linksFiltered = new List<ContentDocumentLink>();
        for (ContentDocumentLink link : links) {
            if (String.valueOf(link.LinkedEntityId).startsWith('001')) {
                linksFiltered.add(link);
            }
        }

        System.assertEquals(4, linksFiltered.size());

        Set<Id> connectedRecords = new Set<Id>();
        for (ContentDocumentLink link : linksFiltered) {
            connectedRecords.add(link.LinkedEntityId);
        }


        System.assert(connectedRecords.contains(acc1.Id));
        System.assert(connectedRecords.contains(acc2.Id));
        System.assert(connectedRecords.contains(riks.Id));

        List<Account> accs = [SELECT XC_Date_Last_Member_Form_Generated__c FROM Account WHERE Id IN :accounts];

        System.assertEquals(2, accs.size());
        System.assertEquals(Date.today(), accs[0].XC_Date_Last_Member_Form_Generated__c);
        System.assertEquals(Date.today(), accs[1].XC_Date_Last_Member_Form_Generated__c);
    }
}