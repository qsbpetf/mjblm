@RestResource(urlMapping='/contactupdate/*')
global  without sharing class ContactRESTService {
    global static  boolean serviceRunning =false;
    
    
    @HttpPost
    global static ServiceMutate doPost() {
        serviceRunning = true;
        
        ServiceMutate payload = (ServiceMutate)JSON.deserialize(RestContext.request.requestBody.toString(), ServiceMutate.class);
        if(ContactHelper.setting.Disable_Integration__c ==false){
            list<Contact> lstContacts = [select id,FirstName,LastName,Email,Phone,MailingStreet,Mailingcity,MailingState,MailingPostalCode,MailingCountry,ExternalID__c from Contact where ExternalID__c=:payload.mutate.customer.eid];
            Contact contactToUpsert = new Contact();
            if(lstContacts.size()>0){
                contactToUpsert = lstContacts.get(0);
            }
            ContactRecord payloadContact = payload.mutate.customer;
            
            contactToUpsert.FirstName = payloadContact.firstName;
            contactToUpsert.LastName = payloadContact.lastName;
            contactToUpsert.Email = payloadContact.email;
            contactToUpsert.Phone = payloadContact.phone;
            contactToUpsert.MailingStreet = payloadContact.address;
            contactToUpsert.Mailingcity = payloadContact.city;
            contactToUpsert.MailingState = payloadContact.state;
            contactToUpsert.MailingPostalCode = payloadContact.postalCode;
            contactToUpsert.MailingCountry = payloadContact.country;
            contactToUpsert.ExternalID__c = payloadContact.eid;
            
            if(contactToUpsert.Id ==null){
                Account acc = new Account(Name =contactToUpsert.FirstName +''+contactToUpsert.LastName);
                insert acc;
                contactToUpsert.AccountId = acc.Id;
            }
            upsert contactToUpsert;
            serviceRunning = false;
        }
        return payload;
    }
    global Class ServiceMutate{
        public CustomerMutate mutate{get;set;}
        global ServiceMutate(){
            mutate = new CustomerMutate();
        }
    }
    global class CustomerMutate{
        public ContactRecord customer{get;set;}
        global CustomerMutate(){
            customer = new ContactRecord();
        }
    }
    global class ContactRecord{
        public string eid;
        public string name;
        public string firstName;
        public string lastName;
        public string email;
        public string phone;
        public string address;
        public string city;
        public string state;
        public string postalCode;
        public string country;
        public ContactRecord(){}
        public ContactRecord(Contact record){
            this.eid = record.ExternalID__c;
            this.name = record.FirstName+' '+record.LastName;
            this.firstName = record.FirstName;
            this.lastName= record.LastName;
            this.email= record.Email;
            this.phone= record.Phone;
            this.address= record.MailingStreet;
            this.city= record.MailingCity;
            this.state= record.MailingState;
            this.postalCode= record.MailingPostalCode;
            this.country= record.MailingCountry;
        }
        
        
    }
}