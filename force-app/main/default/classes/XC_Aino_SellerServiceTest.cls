@isTest
public with sharing class XC_Aino_SellerServiceTest {

    static final String createSellerUrl = '/services/apexrest/createSeller';

    @isTest
    private static void createSellerSuccessTest() {
        XC_Aino_SellerService.SellerWrapper seller = new XC_Aino_SellerService.SellerWrapper();
        seller.webshopId = 'emmy-17-webshop';
        seller.bagId = 'emmy-17-bag';
        seller.name = 'Emmy Blom';
        seller.provision = 0.1;
        seller.groupCode = 'UVIKNF';

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(seller));
        request.requestUri = createSellerUrl;
        request.httpMethod = 'POST';
        RestContext.request = request;

        Test.startTest();
        String response = XC_Aino_SellerService.process();
        Test.stopTest();

        Contact sellerContact = [SELECT Id FROM Contact WHERE CreatedDate = TODAY LIMIT 1];

        System.assertEquals(sellerContact.Id, response);
    }
}