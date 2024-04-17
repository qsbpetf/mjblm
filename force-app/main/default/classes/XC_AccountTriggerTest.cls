@IsTest
public with sharing class XC_AccountTriggerTest {

    private static final String ACC_NAME = 'test_name_acc';
    private static final String CON_NAME = 'test_name_con';

    private static final Map<String, Id> MEMBER_RECORD_TYPE_TO_ID = XC_AccountTriggerTestHelper.getRecordTypes();
    private static final String ACC_RECORD_TYPE_LF = 'XC_Lokalforening';
    private static final String ACC_RECORD_TYPE_LF_ID = XC_AccountTriggerTestHelper.getRecordTypeId(ACC_RECORD_TYPE_LF);

    @IsTest
    static void shouldSetMembersToInactive() {
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
        Set<Id> ids = new Map<Id, Account>(accounts).keySet();

        Contact c1 = new Contact(LastName = CON_NAME + 1);
        Contact c2 = new Contact(LastName = CON_NAME + 2);
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
                RecordTypeId = MEMBER_RECORD_TYPE_TO_ID.get(XC_Constants.CONTACT_RECORD_TYPE),
                npe5__Status__c = XC_Constants.MEMBER_ACTIVE
        );

        List<npe5__Affiliation__c> affiliations = new List<npe5__Affiliation__c> { aff1, aff2 };
        insert affiliations;

        Test.startTest();
        acc1.LF_Status__c = 'Upphörd';
        acc2.LF_Status__c = 'Upphörd';
        update new List<Account> { acc1, acc2 };
        Test.stopTest();

        affiliations = [SELECT npe5__Organization__c, npe5__Status__c FROM npe5__Affiliation__c WHERE Id IN :affiliations];

        for (npe5__Affiliation__c aff : affiliations) {
            if (aff.npe5__Organization__c == acc1.Id) {
                System.assertEquals(XC_Constants.MEMBER_INACTIVE, aff.npe5__Status__c, 'Member of type MEMBER should be set to incative.');
            } else if (aff.npe5__Organization__c == acc2.Id) {
                System.assertEquals(XC_Constants.MEMBER_ACTIVE, aff.npe5__Status__c, 'Member of type KONTAKT should not be set to incative.');
            }
        }
    }

    @IsTest
    static void shouldSetLfNumber() {
        Account acc1 = new Account(
                Name = ACC_NAME + 1,
                LF_Status__c = 'Aktiv',
                RecordTypeId = ACC_RECORD_TYPE_LF_ID);

        insert acc1;

        acc1 = [SELECT XC_LF_Nummer2__c FROM Account WHERE Id = : acc1.Id];

        System.assertEquals(1, acc1.XC_LF_Nummer2__c);

        Account acc2 = new Account(
                Name = ACC_NAME + 2,
                LF_Status__c = 'Aktiv',
                RecordTypeId = ACC_RECORD_TYPE_LF_ID);

        insert acc2;

        acc2 = [SELECT XC_LF_Nummer2__c FROM Account WHERE Id = : acc2.Id];

        System.assertEquals(2, acc2.XC_LF_Nummer2__c);

    }

}