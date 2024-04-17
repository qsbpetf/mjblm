@ISTest
public class ContactRESTServiceTest {
    
    public @testSetup static void setupData(){
        ContactHelper.setting.Contact_Endpoint__c='https://any4m-uat.swedencentral.cloudapp.azure.com/dql';
        ContactHelper.setting.Disable_Integration__c=false;
        ContactHelper.setting.XXX_API_KEY__c='xyx';
        upsert  ContactHelper.setting;
    }
    public testmethod static void unitTest(){
        
        
        ContactRESTService.ServiceMutate ServiceMutate = new ContactRESTService.ServiceMutate();
        
        
        ContactRESTService.ContactRecord record = new ContactRESTService.ContactRecord();
        record.eid ='1234';
        record.firstName = 'firstName';
        record.lastName = 'LastName';
        record.email = 'email@email.com';
        record.phone = '1234567890';
        record.address = 'street';
        record.city = 'city';
        record.state = 'state';
        record.postalCode = '1234';
        record.country = 'country';
        ServiceMutate.mutate.customer = record;
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestBody = blob.valueof(Json.serialize(ServiceMutate));
        req.requestURI = '/services/apexrest/contactupdate'; 
        req.httpMethod = 'Post';
        req.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req;
        RestContext.response = res; 
        Test.startTest();
        ContactRESTService.doPost();
        Test.stopTest();  
        
        
        list<Contact> lstContacts = [select id,FirstName,LastName,Email,Phone,MailingStreet,Mailingcity,MailingState,MailingPostalCode,MailingCountry,ExternalId__c from Contact where ExternalId__c='1234'];
        
        system.assertEquals(1,lstContacts.size());
    }
    
    public testmethod static void unitTestContact(){
        
        Contact record = new Contact();
        
        record.ExternalID__c ='1234';
        record.firstName = 'firstName';
        record.lastName = 'LastName';
        record.email = 'email@email.com';
        record.phone = '1234567890';
        record.Mailingstreet = 'street';
        record.Mailingcity = 'city';
        record.Mailingstate = 'state';
        record.MailingpostalCode = '1234';
        record.Mailingcountry = 'country';
        insert record;
        
        test.startTest();
       Test.setMock(HttpCalloutMock.class, new YourHttpCalloutMockImpl());
        record.firstName ='prq';
        update record;
        test.stopTest();
    }
    
    public class YourHttpCalloutMockImpl implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{}');
            res.setStatusCode(200);
            return res;
        }
    }
}