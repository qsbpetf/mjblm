@isTest
public with sharing class XC_OrderErrorSchedulerTest {

    @isTest
    public static void scheduleTest() {
        Test.startTest();
        String jobID = XC_OrderErrorScheduler.scheduleMe();
        CronTrigger ct = [SELECT Id, CronExpression, CronJobDetailId, CronJobDetail.Name FROM CronTrigger WHERE Id = :jobID];
        System.assertEquals('XC_Aino_OrderErrorCallout' + Date.today(), ct.CronJobDetail.Name);
        Test.stopTest();
    }
}