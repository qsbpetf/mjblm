@IsTest
public with sharing class XC_Aino_OrderErrorCalloutTest {

    @TestSetup
    private static void makeData() {

        XC_AinoIntegration__c ainoIntegration = new XC_AinoIntegration__c(
                Call_Identifier__c = 'ordererrors',
                Endpoint_URL__c = 'https://europe-west3-majblomman-shop.cloudfunctions.net/api/salesforceresponse',
                Token__c = 'abcdefghijklmnoprstuwxyz');

        insert ainoIntegration;

        XC_OrderStagingTable__c ost = new XC_OrderStagingTable__c();
        ost.XC_OrderNumber__c = 'testOrderNum';
        ost.XC_ConversionStatus__c = 'Failed';
        ost.XC_ConversionErrors__c = 'ORDER: duplicate value found: XC_OrderNumber__c';

        insert ost;
    }

    @IsTest
    private static void testCallout() {
        Test.setMock(HttpCalloutMock.class, new XC_Aino_MockHttpResponse());

        Test.startTest();
        Database.executeBatch(new XC_Aino_OrderErrorCallout());
        Test.stopTest();

        List<XC_OrderStagingTable__c> orderStagingTables = [SELECT Id FROM XC_OrderStagingTable__c];
        System.assertEquals(0, orderStagingTables.size());
    }
}