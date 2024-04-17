@isTest
public with sharing class XC_Daily_Order_Summary_Schedule_Test {
    @isTest
    static void testScheduleExecutedBatch() {
        Test.startTest();
        Id jobId = XC_Daily_Order_Summary_Schedule.scheduleMe();
        Test.stopTest();
        System.assertNotEquals(null, jobId);
    }
}