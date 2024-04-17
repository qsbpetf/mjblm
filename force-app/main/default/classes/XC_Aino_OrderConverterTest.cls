@IsTest
public with sharing class XC_Aino_OrderConverterTest {

    public static final String PRIVATE_CUSTOMER_RT_DEV_NAME = 'XC_Privat_kund';

    @TestSetup
    private static void makeData() {
        Id privateCustomerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get(PRIVATE_CUSTOMER_RT_DEV_NAME).getRecordTypeId();
        Account acc = new Account(RecordTypeId = privateCustomerRecordTypeId, Phone = '0705519173', Name = 'Seb Vettel');
        insert acc;

        Contact seller = new Contact();
        seller.XC_Webshop_ID__c = 'webshop-id1';
        seller.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('XC_Privat_Saljare').getRecordTypeId();
        seller.FirstName = 'Test';
        seller.LastName = 'Seller';

        insert seller;

        Product2 prod = new Product2(Name = 'Large', StockKeepingUnit = 'test-package-large');
        Product2 prod1 = new Product2(Name = 'Pin', StockKeepingUnit = 'test-pin');
        insert new List<Product2>{prod, prod1};
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prod.Id,
                UnitPrice = 1, IsActive = true);
        PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prod1.Id,
                UnitPrice = 1, IsActive = true);
        insert new List<PricebookEntry>{pbe, pbe1};

        XC_OrderStagingTable__c stagingTable1 = new XC_OrderStagingTable__c();
        stagingTable1.XC_OrderNumber__c = 'K5GCLZ210415';
        stagingTable1.XC_ConversionStatus__c = 'New';
        stagingTable1.XC_OrderInformation__c = '{"orderNumber": "K5GCLZ210415",\n' +
                '  "paymentType": "payment-success",\n' +
                '  "locale": "sv",\n' +
                '  "serviceType": "webshop",\n' +
                '  "customer": {\n' +
                '    "email": "sebvettel@gmail.com",\n' +
                '    "address2": "",\n' +
                '    "city": "Stockholm",\n' +
                '    "lastName": "Vettel",\n' +
                '    "state": "",\n' +
                '    "firstName": "Seb",\n' +
                '    "acceptShowName": true,\n' +
                '    "country": "Sweden",\n' +
                '    "acceptTerms": true,\n' +
                '    "zipCode": "00001",\n' +
                '    "address1": "Hyttgatan 25",\n' +
                '    "phoneNumber": "0705519173"\n' +
                '  },\n' +
                '  "paymentData": {\n' +
                '    "datePaid": "2021-04-15T19:07:25.410Z",\n' +
                '    "amount": 280,\n' +
                '    "payeePaymentReference": "03vCLBSXomIYFszN8B8U",\n' +
                '    "status": "PAID",\n' +
                '    "callbackUrl": "https://europe-west3-majblomman-shop.cloudfunctions.net/api/swishresponse",\n' +
                '    "id": "84EC554A9F624788B72C00FF7A70889A",\n' +
                '    "errorMessage": null,\n' +
                '    "paymentReference": "291B987A060049B5BA1625AF217B7F3C",\n' +
                '    "errorCode": null,\n' +
                '    "message": null,\n' +
                '    "currency": "SEK",\n' +
                '    "dateCreated": "2021-04-15T19:06:36.098Z",\n' +
                '    "payerAlias": "46705519173",\n' +
                '    "payeeAlias": "1236886980"\n' +
                '  },\n' +
                '  "created": "2021-04-15T19:06:35.586Z",\n' +
                '  "sellerId": "webshop-id1",\n' +
                '  "cart": {\n' +
                '    "items": [\n' +
                '      {\n' +
                '        "totalPrice": 150,\n' +
                '        "price": 150,\n' +
                '        "image": "https://cdn.sanity.io/images/8nyi0s9x/production/b9e84fea6df1165cb8da8fd821d075087334d17d-1401x1401.jpg?w=800",\n' +
                '        "quantity": 1,\n' +
                '        "name": {\n' +
                '          "en": " Single flower, pin, wreath and sticker",\n' +
                '          "sv": "Singelblomma, pin, krans och klistermärke"\n' +
                '        },\n' +
                '        "sku": "test-package-large"\n' +
                '      },\n' +
                '      {\n' +
                '        "isGift": true,\n' +
                '        "totalPrice": 100,\n' +
                '        "image": "https://cdn.sanity.io/images/8nyi0s9x/production/1710b5edcbd2d8c3bc46b4f0af996361407f16bd-1230x1230.jpg?w=800",\n' +
                '        "quantity": 1,\n' +
                '        "name": {\n' +
                '          "sv": "Ge en gåva till Majblomman",\n' +
                '          "en": "Donate money to Majblomman"\n' +
                '        },\n' +
                '        "sku": "test-gift",\n' +
                '        "price": 100\n' +
                '      }\n' +
                '    ],\n' +
                '    "tip": 30,\n' +
                '    "grandTotal": 280,\n' +
                '    "total": 250\n' +
                '  }}';

        XC_OrderStagingTable__c stagingTable2 = new XC_OrderStagingTable__c();
        stagingTable2.XC_OrderNumber__c = 'K5GCLZ210415';
        stagingTable2.XC_ConversionStatus__c = 'New';
        stagingTable2.XC_OrderInformation__c = '{"orderNumber": "K5GCLZ210415",\n' +
                '  "paymentType": "payment-success",\n' +
                '  "locale": "sv",\n' +
                '  "serviceType": "webshop",\n' +
                '  "customer": {\n' +
                '    "email": "sebvettel@gmail.com",\n' +
                '    "address2": "",\n' +
                '    "city": "Stockholm",\n' +
                '    "lastName": "Vettel",\n' +
                '    "state": "",\n' +
                '    "firstName": "Seb",\n' +
                '    "acceptShowName": true,\n' +
                '    "country": "Sweden",\n' +
                '    "acceptTerms": true,\n' +
                '    "zipCode": "00001",\n' +
                '    "address1": "Hyttgatan 25",\n' +
                '    "phoneNumber": "0705519173"\n' +
                '  },\n' +
                '  "paymentData": {\n' +
                '    "datePaid": "2021-04-15T19:07:25.410Z",\n' +
                '    "amount": 280,\n' +
                '    "payeePaymentReference": "03vCLBSXomIYFszN8B8U",\n' +
                '    "status": "PAID",\n' +
                '    "callbackUrl": "https://europe-west3-majblomman-shop.cloudfunctions.net/api/swishresponse",\n' +
                '    "id": "84EC554A9F624788B72C00FF7A70889A",\n' +
                '    "errorMessage": null,\n' +
                '    "paymentReference": "291B987A060049B5BA1625AF217B7F3C",\n' +
                '    "errorCode": null,\n' +
                '    "message": null,\n' +
                '    "currency": "SEK",\n' +
                '    "dateCreated": "2021-04-15T19:06:36.098Z",\n' +
                '    "payerAlias": "46705519173",\n' +
                '    "payeeAlias": "1236886980"\n' +
                '  },\n' +
                '  "created": "2021-04-15T19:06:35.586Z",\n' +
                '  "sellerId": "webshop-id1",\n' +
                '  "cart": {\n' +
                '    "items": [\n' +
                '      {\n' +
                '        "totalPrice": 150,\n' +
                '        "price": 150,\n' +
                '        "image": "https://cdn.sanity.io/images/8nyi0s9x/production/b9e84fea6df1165cb8da8fd821d075087334d17d-1401x1401.jpg?w=800",\n' +
                '        "quantity": 1,\n' +
                '        "name": {\n' +
                '          "en": " Single flower, pin, wreath and sticker",\n' +
                '          "sv": "Singelblomma, pin, krans och klistermärke"\n' +
                '        },\n' +
                '        "sku": "test-package-large"\n' +
                '      },\n' +
                '      {\n' +
                '        "isGift": true,\n' +
                '        "totalPrice": 100,\n' +
                '        "image": "https://cdn.sanity.io/images/8nyi0s9x/production/1710b5edcbd2d8c3bc46b4f0af996361407f16bd-1230x1230.jpg?w=800",\n' +
                '        "quantity": 1,\n' +
                '        "name": {\n' +
                '          "sv": "Ge en gåva till Majblomman",\n' +
                '          "en": "Donate money to Majblomman"\n' +
                '        },\n' +
                '        "sku": "test-gift",\n' +
                '        "price": 100\n' +
                '      }\n' +
                '    ],\n' +
                '    "tip": 30,\n' +
                '    "grandTotal": 280,\n' +
                '    "total": 250\n' +
                '  }}';

        XC_OrderStagingTable__c stagingTable3 = new XC_OrderStagingTable__c();
        stagingTable3.XC_OrderNumber__c = 'TESTTEST';
        stagingTable3.XC_ConversionStatus__c = 'New';
        stagingTable3.XC_OrderInformation__c = '{"orderNumber": "TESTTEST",\n' +
                '  "paymentType": "payment-success",\n' +
                '  "locale": "sv",\n' +
                '  "serviceType": "bag",\n' +
                '  "customer": {\n' +
                '    "email": "larstobbe3@gmail.com",\n' +
                '    "address2": "",\n' +
                '    "city": "Sala",\n' +
                '    "lastName": "Johansson",\n' +
                '    "state": "",\n' +
                '    "firstName": "Lars-Åke",\n' +
                '    "acceptShowName": true,\n' +
                '    "country": "Sweden",\n' +
                '    "acceptTerms": true,\n' +
                '    "zipCode": "73331",\n' +
                '    "address1": "Hyttgatan 25",\n' +
                '    "phoneNumber": "0705519172"\n' +
                '  },\n' +
                '  "paymentData": {\n' +
                '    "datePaid": "2021-04-15T19:07:25.410Z",\n' +
                '    "amount": 280,\n' +
                '    "payeePaymentReference": "03vCLBSXomIYFszN8B8U",\n' +
                '    "status": "PAID",\n' +
                '    "callbackUrl": "https://europe-west3-majblomman-shop.cloudfunctions.net/api/swishresponse",\n' +
                '    "id": "84EC554A9F624788B72C00FF7A70889A",\n' +
                '    "errorMessage": null,\n' +
                '    "paymentReference": "291B987A060049B5BA1625AF217B7F3C",\n' +
                '    "errorCode": null,\n' +
                '    "message": null, \n' +
                '    "currency": "SEK",\n' +
                '    "dateCreated": "2021-04-15T19:06:36.098Z",\n' +
                '    "payerAlias": "46705519173",\n' +
                '    "payeeAlias": "1236886980"\n' +
                '  },\n' +
                '  "created": "2021-04-15T19:06:35.586Z",\n' +
                '  "sellerId": "bag-id1", \n' +
                '  "cart": {\n' +
                '    "items": [\n' +
                '      {\n' +
                '        "totalPrice": 150,\n' +
                '        "price": 150,\n' +
                '        "image": "https://cdn.sanity.io/images/8nyi0s9x/production/b9e84fea6df1165cb8da8fd821d075087334d17d-1401x1401.jpg?w=800",\n' +
                '        "quantity": 1,\n' +
                '        "name": {\n' +
                '          "en": "Pin",\n' +
                '          "sv": "Pin"\n' +
                '        },\n' +
                '        "sku": "test-pin"\n' +
                '      }\n' +
                '    ],\n' +
                '    "tip": 30,\n' +
                '    "grandTotal": 280,\n' +
                '    "total": 250\n' +
                '  }}';

        insert new List<XC_OrderStagingTable__c>{stagingTable1, stagingTable2, stagingTable3};
    }

    @IsTest
    public static void convertOrdersTest() {
        Test.startTest();
        Database.executeBatch(new XC_Aino_OrderConverter());
        Test.stopTest();

        List<Order> orders = [SELECT XC_OrderNumber__c FROM Order];

        System.assertEquals(1, orders.size());
    }
}