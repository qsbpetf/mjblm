@IsTest
private class XC_RemoveApplicationsOlderThanTest {
    private static final String TEMPORARY = 'Temporary';
    private static final String RT_TEMPORARY = 'Temp';


    @IsTest
    static void testDeleteApplication() {
        Application__c app = new Application__c(
                XC_Status__c = TEMPORARY,
                RecordTypeId = Schema.SObjectType.Application__c.getRecordTypeInfosByDeveloperName().get(RT_TEMPORARY).getRecordTypeId()
        );

        insert app;

        List<Application__c> apps = [SELECT Id FROM Application__c];
        Assert.isFalse(apps.isEmpty());


        Test.startTest();
        XC_RemoveApplicationsOlderThan.END_DATE = Date.today().addDays(1);
        Database.executeBatch(new XC_RemoveApplicationsOlderThan());
        System.schedule('Test', '0 30 * * * ?', new XC_RemoveApplicationsOlderThan());
        Test.stopTest();

        apps = [SELECT Id FROM Application__c];
        Assert.isTrue(apps.isEmpty());
    }
}