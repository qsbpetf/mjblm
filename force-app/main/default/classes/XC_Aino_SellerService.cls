@RestResource(urlMapping = '/createSeller')
global with sharing class XC_Aino_SellerService {

    private static final Integer HTTP_ERROR_CODE = 400;

    @HttpPost
    global static String process() {
        RestRequest request = RestContext.request;
        String requestBody = request.requestBody.toString();

        System.debug('>>> Request_Body:  ' + requestBody);
        SellerWrapper sellerWrapper = new SellerWrapper().parse(requestBody);

        Contact sellerContact = new Contact();
        RestResponse response = RestContext.response;
//        try {
            sellerContact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('XC_Privat_Saljare').getRecordTypeId();
            sellerContact.FirstName = sellerWrapper.name.substring(0,sellerWrapper.name.lastIndexOf(' '));
            sellerContact.LastName = sellerWrapper.name.substring(sellerWrapper.name.lastIndexOf(' ') + 1);
            sellerContact.XC_Tillhandahallande__c = sellerWrapper.provision;
            sellerContact.XC_Gruppkod__c = sellerWrapper.groupCode;
            sellerContact.XC_Webshop_ID__c = sellerWrapper.webshopId;
            sellerContact.XC_Bag_ID__c = sellerWrapper.bagId;

            insert sellerContact;
            return sellerContact.Id;
        }
//        catch(Exception e) {
//            System.debug('>>> Error while creating a Seller record: ' + e);
//
//            return e.getMessage();
//        }
//
//
//        return sellerContact.Id;
//    }

    public class SellerWrapper {
        public String webshopId;
        public String bagId;
        public String name;
        public Double provision;
        public String groupCode;

        public SellerWrapper parse(String json) {
            return (SellerWrapper) System.JSON.deserialize(json, SellerWrapper.class);
        }
    }
}