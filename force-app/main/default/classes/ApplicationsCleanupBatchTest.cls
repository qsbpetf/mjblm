@IsTest
public with sharing class ApplicationsCleanupBatchTest {

    private static final String TEMPORARY = 'Temporary';
    private static final String RT_TEMPORARY = 'Temp';

    @IsTest
    static void testBatch() {
        Application__c app = new Application__c(
                XC_Status__c = TEMPORARY,
                RecordTypeId = Schema.SObjectType.Application__c.getRecordTypeInfosByDeveloperName().get(RT_TEMPORARY).getRecordTypeId()
        );

        insert app;

        Test.startTest();
        ApplicationsCleanupBatch.execute(null);
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Application__c]);
    }

    @IsTest
    static void testBatchFail() {
        Application__c app = new Application__c(
                XC_Status__c = TEMPORARY,
                RecordTypeId = Schema.SObjectType.Application__c.getRecordTypeInfosByDeveloperName().get(RT_TEMPORARY).getRecordTypeId()
        );

        insert app;

        Test.startTest();
        ApplicationsCleanupBatch batch = new ApplicationsCleanupBatch();
        batch.errors.add('test error');
        Database.executeBatch(batch);
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Application__c]);
    }
}