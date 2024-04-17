@IsTest
private class DuplicatedApplicationsControllerTest {

    private static final String STATUS_NEW = 'New';
    private static final String ONGOING = 'Ongoing';

    @IsTest
    static void testBehavior() {
        Application__c app1 = new Application__c(
                XC_Status__c = STATUS_NEW,
                RecordTypeId = Schema.SObjectType.Application__c.getRecordTypeInfosByDeveloperName().get(ONGOING).getRecordTypeId(),
                XC_FormId__c = '123'
        );
        Application__c app2 = new Application__c(
                XC_Status__c = STATUS_NEW,
                RecordTypeId = Schema.SObjectType.Application__c.getRecordTypeInfosByDeveloperName().get(ONGOING).getRecordTypeId(),
                XC_FormId__c = '456'
        );
        insert new List<Application__c> { app1, app2 };

        XC_ApplicationEntryChild__c entry1 = new XC_ApplicationEntryChild__c(
                XC_Application__c = app1.Id,
                XC_Personnummer__c = 'duplicated'
        );
        XC_ApplicationEntryChild__c entry2 = new XC_ApplicationEntryChild__c(
                XC_Application__c = app2.Id,
                XC_Personnummer__c = 'duplicated'
        );
        insert new List<XC_ApplicationEntryChild__c> { entry1, entry2 };

        ApexPages.StandardController stdApp = new ApexPages.StandardController(app1);
        DuplicatedApplicationsController ext  = new DuplicatedApplicationsController(stdApp);

        Application__c app = ext.getApp();
        List<Application__c> dupliacted = ext.getApps();

        Assert.isNotNull(app);
        Assert.areEqual(1, dupliacted.size());
        Assert.areEqual(app2.XC_FormId__c, dupliacted[0].XC_FormId__c);

    }
}