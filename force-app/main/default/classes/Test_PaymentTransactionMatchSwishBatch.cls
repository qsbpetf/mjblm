@isTest
private class Test_PaymentTransactionMatchSwishBatch {


    @TestSetup
    static void makeData(){
        
        axnpsp__AXSP_Swish_Admin__c swishAdmin = new axnpsp__AXSP_Swish_Admin__c();
        swishAdmin.axnpsp__Swish_Number__c = '123';
        swishAdmin.axnpsp__Swish_Number_Reference__c = '123';
        swishAdmin.axnpsp__Campaign__c = null;
        swishAdmin.axnpsp__Donation_Type__c = 'Donation';
        insert swishAdmin;

        Contact con = new Contact();
        con.FirstName = 'Swish';
        con.LastName = 'Swish';
        con.MobilePhone = '0765639000';
        insert con;


    }

    @isTest
    static void shouldMatchExistingOpp(){
        Contact con = [SELECT Id FROM Contact];
        Opportunity opp = new Opportunity();
        opp.Name = 'Test';
        opp.StageName = 'Pledged';
        opp.CloseDate = Date.today();
        opp.axnpsp__Payment_Reference_ID__c = '999';
        opp.npsp__Primary_Contact__c = con.Id;
        insert opp;
        axnpsp__Payment_Transaction__c pt = new axnpsp__Payment_Transaction__c();
        pt.axnpsp__Swish_Amount__c = 100; 
        pt.axnpsp__Swish_Payment_Reference__c = '999';
        pt.axnpsp__Swish_Payer_mobile__c = '765639680';
        pt.axnpsp__Swish_number__c = '123';
        pt.axnpsp__Swish_Amount__c = 100;
        pt.axnpsp__Swish_Payer_Name__c = 'Andreas TIMOUDAS';
        pt.axnpsp__Payment_Transaction_Origin__c = 'Swish Foretag';
        pt.axnpsp__Swish_Paydate_time__c = '2023-01-01';
        insert pt;

        Test.startTest();
        Database.executeBatch(new PaymentTransactionMatchSwishBatch());
        Test.stopTest();

    }

        @isTest
        static void shouldMatchSwishAdminWithoutContacttest(){
            axnpsp__Payment_Transaction__c pt = new axnpsp__Payment_Transaction__c();
            pt.axnpsp__Swish_Amount__c = 100; 
            pt.axnpsp__Swish_Payment_Reference__c = '123';
            pt.axnpsp__Swish_Payer_mobile__c = '765639680';
            pt.axnpsp__Swish_number__c = '123';
            pt.axnpsp__Swish_Amount__c = 100;
            pt.axnpsp__Swish_Payer_Name__c = 'Andreas TIMOUDAS';
            pt.axnpsp__Payment_Transaction_Origin__c = 'Swish Foretag';
            pt.axnpsp__Swish_Paydate_time__c = '2023-01-01';
            insert pt;

            Test.startTest();
            Database.executeBatch(new PaymentTransactionMatchSwishBatch());
            Test.stopTest();

            npe01__OppPayment__c payment = [SELECT Id, npe01__Paid__c FROM npe01__OppPayment__c];
            Opportunity opp = [SELECT Id, StageName FROM Opportunity];
            System.assertEquals(true, payment.npe01__Paid__c);

        }

        @isTest
        static void shouldMatchSwishAdminAndContacttest(){
            axnpsp__Payment_Transaction__c pt = new axnpsp__Payment_Transaction__c();
            pt.axnpsp__Swish_Amount__c = 100; 
            pt.axnpsp__Swish_Payment_Reference__c = '123';
            pt.axnpsp__Swish_Payer_mobile__c = '765639000';
            pt.axnpsp__Swish_number__c = '123';
            pt.axnpsp__Swish_Amount__c = 100;
            pt.axnpsp__Swish_Payer_Name__c = 'Andreas TIMOUDAS';
            pt.axnpsp__Payment_Transaction_Origin__c = 'Swish Foretag';
            pt.axnpsp__Swish_Paydate_time__c = '2023-01-01';
            insert pt;

            Test.startTest();
            Database.executeBatch(new PaymentTransactionMatchSwishBatch());
            Test.stopTest();
            npe01__OppPayment__c payment = [SELECT Id, npe01__Paid__c FROM npe01__OppPayment__c];
            Opportunity opp = [SELECT Id, StageName FROM Opportunity];
            Contact con = [SELECT FirstName, LastName FROM Contact];
            System.assertEquals(true, payment.npe01__Paid__c);
            System.assertEquals('Andreas', con.FirstName);
            System.assertEquals('TIMOUDAS', con.LastName);
        }

        @isTest
        static void PaymentTransactionMatchSwishSchtest() {
            Test.startTest();
            String cronExpression = '0 0 0 * * ?';
            PaymentTransactionMatchSwishSch schedulable = new PaymentTransactionMatchSwishSch();
            String jobId = System.schedule('Test Job', cronExpression, schedulable);
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
            System.assertEquals(cronExpression, ct.CronExpression);
            Test.stopTest();
        }


    
}