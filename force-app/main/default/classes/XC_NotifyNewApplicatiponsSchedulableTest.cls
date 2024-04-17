@IsTest
private class XC_NotifyNewApplicatiponsSchedulableTest {
    private static final String TEMPORARY = 'Temporary';
    private static final String RT_TEMPORARY = 'Temp';

    @IsTest
    static void testNotify() {

        Account acc = new Account(
                Name = 'test',
                XC_Epost__c = 'test@test.pl',
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('XC_Lokalforening').getRecordTypeId()
        );
        insert acc;

        Application__c app = new Application__c(
                XC_Status__c = TEMPORARY,
                RecordTypeId = Schema.SObjectType.Application__c.getRecordTypeInfosByDeveloperName().get(RT_TEMPORARY).getRecordTypeId(),
                XC_LF__c = acc.Id
        );

        insert app;

        Test.startTest();
        new XC_NotifyNewApplicatiponsSchedulable().execute(null);
        Test.stopTest();
    }
}