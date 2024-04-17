@IsTest
private class XC_OrderStagingCleanupBatchTest {
    @IsTest
    static void testBatch() {

        XC_OrderStagingTable__c table1 = new XC_OrderStagingTable__c(
                XC_ConversionStatus__c = 'Converted',
                XC_OrderNumber__c = 'abce'
        );
        XC_OrderStagingTable__c table2 = new XC_OrderStagingTable__c(
                XC_ConversionStatus__c = 'New',
                XC_OrderNumber__c = 'abcd'
        );

        insert new List<XC_OrderStagingTable__c> { table1, table2 };

        Test.startTest();
        Database.executeBatch(new XC_OrderStagingCleanupBatch(1));
        Test.stopTest();

        Assert.areEqual(1, [SELECT Id FROM XC_OrderStagingTable__c].size());

    }

}