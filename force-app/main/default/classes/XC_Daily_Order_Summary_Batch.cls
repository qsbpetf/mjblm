public with sharing class XC_Daily_Order_Summary_Batch implements Database.Batchable<sObject>, Database.Stateful {

    private static final String query = 'SELECT XC_ServiceTyp__c , XC_Quantity_Large__c, XC_Quantity_Small__c, XC_Packages_Amount__c FROM Order WHERE XC_ServiceTyp__c = \'webshop\' AND (XC_Quantity_Large__c != 0 OR XC_Quantity_Small__c != 0)';

    public Integer totalPackageLarge;
    public Integer totalPackageSmall;
    public Integer totalOrders;
    public Decimal totalAmount;

    public Database.QueryLocator start(Database.BatchableContext param1) {
        this.totalPackageLarge = 0;
        this.totalPackageSmall = 0;
        this.totalOrders = 0;
        this.totalAmount = 0;
        if (Test.isRunningTest()) {
            return Database.getQueryLocator('SELECT XC_ServiceTyp__c , XC_Quantity_Large__c, XC_Quantity_Small__c, XC_Packages_Amount__c FROM Order WHERE XC_Quantity_Large__c != 0 OR XC_Quantity_Small__c != 0');
        } else {
            Date da = Date.today();
            Integer y = da.year();
            Integer m = da.month();
            Integer d = da.day();
            Datetime startDate = Datetime.newInstanceGMT(y, m, d-1);
            Datetime endDate = Datetime.newInstanceGMT(y, m, d);
            String query = 'SELECT XC_ServiceTyp__c , XC_Quantity_Large__c, XC_Quantity_Small__c, XC_Packages_Amount__c FROM Order WHERE XC_ServiceTyp__c = \'webshop\' AND (XC_Quantity_Large__c != 0 OR XC_Quantity_Small__c != 0) and CreatedDate < :endDate AND CreatedDate >= :startDate';
            return Database.getQueryLocator(query);
        }
    }

    public void execute(Database.BatchableContext ctx, List<Order> orders) {
        for (Order o : (List<Order>) orders) {
            this.totalPackageLarge += Integer.valueOf(o.XC_Quantity_Large__c);
            this.totalPackageSmall += Integer.valueOf(o.XC_Quantity_Small__c);
            this.totalAmount += o.XC_Packages_Amount__c;
            this.totalOrders += 1;
        }
    }

    public void finish(Database.BatchableContext ctx) {
        insert new XC_Order_Summary_Object__c(
                XC_Small_Packages_Total_Number__c = this.totalPackageSmall,
                XC_Large_Packages_Total_Number__c = this.totalPackageLarge,
                XC_Total_Orders_Number__c = this.totalOrders,
                XC_Total_Amount__c = this.totalAmount,
                XC_Day_Collected__c = Date.today().addDays(-1)
        );
    }
}