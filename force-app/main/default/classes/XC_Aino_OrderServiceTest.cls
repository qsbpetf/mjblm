@IsTest
public with sharing class XC_Aino_OrderServiceTest {

    static final String createOrdersUrl = '/services/apexrest/createOrders';

    @TestSetup
    private static void makeData() {
        Product2 prod = new Product2(Name = 'Test Product', Family = 'Majblomman');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prod.Id,
                UnitPrice = 1, IsActive = true);
        insert standardPrice;
    }

    @isTest
    private static void createSellerSuccessTest() {
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf('{"orders": \n' +
                '[{\n' +
                '  "orderNumber": "K5GCLZ210415",\n' +
                '  "paymentType": "payment-success",\n' +
                '  "locale": "sv",\n' +
                '  "serviceType": "webshop",\n' +
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
                '        "sku": "package-2"\n' +
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
                '        "sku": "gift",\n' +
                '        "price": 100\n' +
                '      }\n' +
                '    ],\n' +
                '    "tip": 30,\n' +
                '    "grandTotal": 280,\n' +
                '    "total": 250\n' +
                '  }\n' +
                '}]}');
        request.requestUri = createOrdersUrl;
        request.httpMethod = 'POST';
        RestContext.request = request;

        Test.startTest();
        String response = XC_Aino_OrderService.process();
        Test.stopTest();

        System.assertEquals('success', response);
    }
}