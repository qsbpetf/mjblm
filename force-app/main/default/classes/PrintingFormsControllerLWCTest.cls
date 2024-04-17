@IsTest
public with sharing class PrintingFormsControllerLWCTest {

    private static final String ACC_NAME = 'test_name_acc';
    private static final String CON_NAME = 'test_name_con';

    private static final Map<String, Id> MEMBER_RECORD_TYPE_TO_ID = XC_AccountTriggerTestHelper.getRecordTypes();
    private static final String ACC_RECORD_TYPE_LF = 'XC_Lokalforening';
    private static final String ACC_RECORD_TYPE_LF_ID = XC_AccountTriggerTestHelper.getRecordTypeId(ACC_RECORD_TYPE_LF);

    @IsTest
    static void shouldCreatePrintingFormsForASingleAccount() {
        Account riks = new Account(Name = 'RIKS');
        insert riks;
        Account acc1 = new Account(
                Name = ACC_NAME + 1,
                LF_Status__c = 'Aktiv',
                RecordTypeId = ACC_RECORD_TYPE_LF_ID);
        List<Account> accounts = new List<Account> { acc1 };
        insert accounts;

        Contact c1 = new Contact(LastName = CON_NAME + 1);
        List<Contact> contacts = new List<Contact> { c1 };
        insert contacts;

        npe5__Affiliation__c aff1 = new npe5__Affiliation__c(
                npe5__Organization__c = acc1.Id,
                npe5__Contact__c = c1.Id,
                RecordTypeId = MEMBER_RECORD_TYPE_TO_ID.get(XC_Constants.MEMBER_RECORD_TYPE),
                npe5__Status__c = XC_Constants.MEMBER_ACTIVE
        );

        List<npe5__Affiliation__c> affiliations = new List<npe5__Affiliation__c> { aff1 };

        insert affiliations;

        Test.startTest();
        PrintingFormsControllerLWC.createFormsSingle(false, true, acc1.Id, new List<Id>());
        Test.stopTest();

        List<ContentVersion> createdContentVersions = [SELECT XC_LF_Nummer__c, ContentDocumentId FROM ContentVersion];
        System.assertEquals(1, createdContentVersions.size());

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

        System.assertEquals(2, linksFiltered.size());

        Set<Id> connectedRecords = new Set<Id>();
        for (ContentDocumentLink link : linksFiltered) {
            connectedRecords.add(link.LinkedEntityId);
        }
        System.debug('WHICH ACCOUNTS : ' + [SELECT Name FROM ACCOUNT WHERE ID IN :connectedRecords]);
        System.debug('connectedRecords ' + connectedRecords);

        System.assert(connectedRecords.contains(acc1.Id));
        System.assert(connectedRecords.contains(riks.Id));

        acc1 = [SELECT XC_Date_Last_Member_Form_Generated__c FROM Account WHERE Id = :acc1.Id];
        System.assertEquals(Date.today(), acc1.XC_Date_Last_Member_Form_Generated__c);
    }

    @IsTest
    static void shouldSendPrintingFormsForASingleAccount() {
        Account riks = new Account(Name = 'RIKS');
        insert riks;
        Account acc1 = new Account(
                Name = ACC_NAME + 1,
                LF_Status__c = 'Aktiv',
                RecordTypeId = ACC_RECORD_TYPE_LF_ID);
        List<Account> accounts = new List<Account> { acc1 };
        insert accounts;

        Contact c1 = new Contact(LastName = CON_NAME + 1, Email = 'test@email.com');
        List<Contact> contacts = new List<Contact> { c1 };
        insert contacts;

        npe5__Affiliation__c aff1 = new npe5__Affiliation__c(
                npe5__Organization__c = acc1.Id,
                npe5__Contact__c = c1.Id,
                RecordTypeId = MEMBER_RECORD_TYPE_TO_ID.get(XC_Constants.MEMBER_RECORD_TYPE),
                npe5__Status__c = XC_Constants.MEMBER_ACTIVE
        );

        List<npe5__Affiliation__c> affiliations = new List<npe5__Affiliation__c> { aff1 };

        insert affiliations;

        Test.startTest();
        PrintingFormsControllerLWC.createFormsSingle(true, false, acc1.Id, new List<Id> { aff1.Id });
        Test.stopTest();

        System.assertEquals(1, PrintingFormsControllerLWC.emailsSent);

    }

    @IsTest
    static void testGetAccount_whenExists() {
        Account riks = new Account(Name = 'test');
        insert riks;

        Test.startTest();
        Account acc = PrintingFormsControllerLWC.getAccount(riks.Id);
        Test.stopTest();

        System.assertEquals(riks.Name, acc.Name);
    }

    @IsTest
    static void testGetAccount_whenNotExists() {
        Account riks = new Account(Name = 'test');
        insert riks;

        Id riksId = riks.Id;
        delete riks;

        Test.startTest();
        Account acc = PrintingFormsControllerLWC.getAccount(riksId);
        Test.stopTest();

        System.assertEquals(null, acc);
    }

    @IsTest
    static void shouldOverwriteFile_whenNewCreated() {
        Account riks = new Account(Name = 'RIKS');
        insert riks;
        Account acc1 = new Account(
                Name = ACC_NAME + 1,
                LF_Status__c = 'Aktiv',
                RecordTypeId = ACC_RECORD_TYPE_LF_ID);
        List<Account> accounts = new List<Account> { acc1 };
        insert accounts;

        Contact c1 = new Contact(LastName = CON_NAME + 1);
        List<Contact> contacts = new List<Contact> { c1 };
        insert contacts;

        npe5__Affiliation__c aff1 = new npe5__Affiliation__c(
                npe5__Organization__c = acc1.Id,
                npe5__Contact__c = c1.Id,
                RecordTypeId = MEMBER_RECORD_TYPE_TO_ID.get(XC_Constants.MEMBER_RECORD_TYPE),
                npe5__Status__c = XC_Constants.MEMBER_ACTIVE
        );

        List<npe5__Affiliation__c> affiliations = new List<npe5__Affiliation__c> { aff1 };

        insert affiliations;

        PrintingFormsControllerLWC.createFormsSingle(false, true, acc1.Id, new List<Id>());

        List<ContentVersion> createdContentVersions = [SELECT XC_LF_Nummer__c, ContentDocumentId FROM ContentVersion];
        System.assertEquals(1, createdContentVersions.size());
        ContentVersion createdContentVersion = createdContentVersions[0];

        Test.startTest();
        PrintingFormsControllerLWC.createFormsSingle(false, true, acc1.Id, new List<Id>());
        Test.stopTest();

        createdContentVersions = [SELECT XC_LF_Nummer__c, ContentDocumentId FROM ContentVersion];
        System.assertEquals(1, createdContentVersions.size());
        createdContentVersions = [SELECT Id FROM ContentVersion WHERE Id = :createdContentVersion.Id];
        System.assertEquals(0, createdContentVersions.size());

    }

    @IsTest
    static void testGetDefaultRecipientsForAccount() {
        Account acc1 = new Account(
                Name = ACC_NAME + 1,
                LF_Status__c = 'Aktiv',
                RecordTypeId = ACC_RECORD_TYPE_LF_ID);
        List<Account> accounts = new List<Account> { acc1 };
        insert accounts;

        Contact c1 = new Contact(LastName = CON_NAME + 1);
        List<Contact> contacts = new List<Contact> { c1 };
        insert contacts;

        npe5__Affiliation__c aff1 = new npe5__Affiliation__c(
                npe5__Organization__c = acc1.Id,
                npe5__Contact__c = c1.Id,
                RecordTypeId = MEMBER_RECORD_TYPE_TO_ID.get(XC_Constants.MEMBER_RECORD_TYPE),
                npe5__Status__c = XC_Constants.MEMBER_ACTIVE
        );

        List<npe5__Affiliation__c> affiliations = new List<npe5__Affiliation__c> { aff1 };
        insert affiliations;

        Test.startTest();
        affiliations = PrintingFormsControllerLWC.getDefaultRecipientsForAccount(acc1.Id);
        Test.stopTest();

        System.assertEquals(1, affiliations.size());
    }

}