@isTest
public with sharing class XC_OrderConverterSchedulerTest {

    @isTest 
    public static void scheduleTest() {
        Test.startTest();
        String jobID = XC_OrderConverterScheduler.scheduleMe();
        CronTrigger ct = [SELECT Id, CronExpression, CronJobDetailId, CronJobDetail.Name FROM CronTrigger WHERE Id = :jobID];
        System.assertEquals('XC_Aino_OrderConverter' + Date.today(), ct.CronJobDetail.Name);
        Test.stopTest();
    }
}