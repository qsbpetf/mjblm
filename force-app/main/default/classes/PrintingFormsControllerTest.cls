@IsTest
public with sharing class PrintingFormsControllerTest {

    private static final String ACC_NAME = 'test_name_acc';
    private static final String CON_NAME = 'test_name_con';

    private static final Map<String, Id> MEMBER_RECORD_TYPE_TO_ID = XC_AccountTriggerTestHelper.getRecordTypes();
    private static final String ACC_RECORD_TYPE_LF = 'XC_Lokalforening';
    private static final String ACC_RECORD_TYPE_LF_ID = XC_AccountTriggerTestHelper.getRecordTypeId(ACC_RECORD_TYPE_LF);

    @TestSetup
    static void setupTest() {
        Account acc1 = new Account(
                Name = ACC_NAME + 1,
                LF_Status__c = 'Aktiv',
                RecordTypeId = ACC_RECORD_TYPE_LF_ID);
        List<Account> accounts = new List<Account> { acc1 };
        insert accounts;
        Set<Id> ids = new Map<Id, Account>(accounts).keySet();

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


    }


    @IsTest
    static void testQueryAffiliations() {
        PageReference pageRef = Page.PrintingFormVF;
        Test.setCurrentPage(pageRef);

        Account acc = [SELECT Id FROM Account LIMIT 1];
        pageRef.getParameters().put('Id', String.valueOf(acc.Id));
        ApexPages.StandardController sc = new  ApexPages.StandardController(acc);


        Test.startTest();
        List<PrintingFormsController.AffiliationWrapper> affiliations  = new PrintingFormsController(sc).getAffiliations();
        Test.stopTest();

        System.assertEquals(1, affiliations.size());
    }

    @IsTest
    static void testGetYear() {
        PageReference pageRef = Page.PrintingFormVF;
        Test.setCurrentPage(pageRef);

        Account acc = [SELECT Id FROM Account LIMIT 1];
        pageRef.getParameters().put('Id', String.valueOf(acc.Id));
        ApexPages.StandardController sc = new  ApexPages.StandardController(acc);

        Date today = Date.today();
        String year = String.valueOf(today.year());

        Test.startTest();
        String yearFromController = new PrintingFormsController(sc).getYear();
        Test.stopTest();

        System.assertEquals(year, yearFromController);
    }

    @IsTest
    static void testGetLfNamePretty() {
        PageReference pageRef = Page.PrintingFormVF;
        Test.setCurrentPage(pageRef);

        Account acc = [SELECT Name, XC_LF_Nummer2__c FROM Account LIMIT 1];
        pageRef.getParameters().put('Id', String.valueOf(acc.Id));
        ApexPages.StandardController sc = new  ApexPages.StandardController(acc);


        Test.startTest();
        String accNamePretty = new PrintingFormsController(sc).getLfNamePretty();
        Test.stopTest();

        System.assertEquals(acc.XC_LF_Nummer2__c + ' - ' + acc.Name, accNamePretty);
    }

    @IsTest
    static void testGetHeaders() {
        PageReference pageRef = Page.PrintingFormVF;
        Test.setCurrentPage(pageRef);

        Account acc = [SELECT Name, XC_LF_Nummer__c FROM Account LIMIT 1];
        pageRef.getParameters().put('Id', String.valueOf(acc.Id));
        ApexPages.StandardController sc = new  ApexPages.StandardController(acc);

        Test.startTest();
        List<String> headers = new PrintingFormsController(sc).getHeaders();
        Test.stopTest();

        System.assert(!headers.isEmpty());
    }
}