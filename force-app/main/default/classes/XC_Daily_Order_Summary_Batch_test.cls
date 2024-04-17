@IsTest
private class XC_Daily_Order_Summary_Batch_test {

    @IsTest
    static void testDailyOrderBatch() {
        Account a = new Account(
                Name = 'test name'
        );
        insert a;
        Order o = new Order(
                AccountId = a.Id,
                Status = 'Draft',
                EffectiveDate = Date.today(),
                Pricebook2Id = test.getStandardPricebookId()
        );
        insert o;
        Product2 prod = new Product2(Name = 'Large', StockKeepingUnit = 'test-package-large');
        Product2 prod1 = new Product2(Name = 'Pin', StockKeepingUnit = 'test-pin');
        insert new List<Product2>{prod, prod1};
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prod.Id,
                UnitPrice = 1, IsActive = true);
        PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prod1.Id,
                UnitPrice = 1, IsActive = true);
        insert new List<PricebookEntry>{pbe, pbe1};
        OrderItem o1 = new OrderItem(
                Quantity = 1,
                OrderId = o.Id,
                UnitPrice = 100,
                PricebookEntryId = pbe.Id,
                XC_Sku__c = 'package-small'
        );
        OrderItem o2 = new OrderItem(
                Quantity = 2,
                OrderId = o.Id,
                UnitPrice = 300,
                PricebookEntryId = pbe1.Id,
                XC_Sku__c = 'package-large'
        );
        insert new List<OrderItem>{o1, o2};
        Order oo = [select XC_Quantity_Large__c, XC_Quantity_Small__c from Order];

        Test.startTest();
        new XC_Daily_Order_Summary_Schedule().execute(null);
        Test.stopTest();

        List<XC_Order_Summary_Object__c> obj =  [SELECT XC_Day_Collected__c, XC_Total_Amount__c, XC_Total_Orders_Number__c, XC_Large_Packages_Total_Number__c, XC_Small_Packages_Total_Number__c FROM XC_Order_Summary_Object__c];
        System.assertEquals(1, obj.size());
        XC_Order_Summary_Object__c res = obj[0];
        System.assertEquals(Date.today().addDays(-1), res.XC_Day_Collected__c);
        System.assertEquals(700, res.XC_Total_Amount__c);
        System.assertEquals(2, res.XC_Large_Packages_Total_Number__c);
        System.assertEquals(1, res.XC_Small_Packages_Total_Number__c);
        System.assertEquals(1, res.XC_Total_Orders_Number__c);
    }
}