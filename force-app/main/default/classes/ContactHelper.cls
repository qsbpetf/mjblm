public class ContactHelper {
     public static Integration_Setting__c setting =Integration_Setting__c.getOrgDefaults();
    public static void afterUpdate(list<Contact> records, map<Id,Contact> oldMap){
        
        if(ContactRESTService.serviceRunning==false){
            set<id> setContactIds = new set<Id>();
            for(Contact record:records){
                Contact oldRecord = oldMap.get(record.Id);
                if(record.FirstName != oldRecord.FirstName || record.LastName != oldRecord.LastName ||record.Email != oldRecord.Email ||
                   record.Phone != oldRecord.Phone ||record.MailingStreet != oldRecord.MailingStreet ||record.Mailingcity != oldRecord.Mailingcity ||
                   record.MailingState != oldRecord.MailingState ||record.MailingPostalCode != oldRecord.MailingPostalCode ||record.MailingCountry != oldRecord.MailingCountry){
                       setContactIds.add(record.Id);
                   }
            }
            
            
            if(!system.isFuture() && setContactIds.size()>0){
                asyncPostToExternal(setContactIds);
            }
        }
        
    }
    public static void postToExternal(set<id> setContactIds){
        list<Contact> lstContacts = [select id,FirstName,LastName,Email,Phone,MailingStreet,Mailingcity,MailingState,MailingPostalCode,MailingCountry,ExternalId__c 
                                     from Contact where ID IN:setContactIds];
        
        ContactRESTService.ContactRecord   contactRecord = new ContactRESTService.ContactRecord(lstContacts.get(0));
      
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(setting.Contact_Endpoint__c);
        request.setHeader('XXX-API-KEY','cbd824bd-d0b3-4055-995e-f94e5a541659');
        request.setMethod('POST');
        ContactRESTService.ServiceMutate ServiceMutate = new ContactRESTService.ServiceMutate();
        ServiceMutate.mutate.customer = contactRecord;
        request.setBody(Json.serialize(ServiceMutate));
        request.setHeader('Content-Type','application/json');
        
        HttpResponse response = http.send(request);
        system.debug('request::'+request);  
        system.debug('request::body::'+request.getBody());  
        system.debug('response::'+response);        
        system.debug('response::body::'+response.getBody());
        
    }
    @future(Callout=true)
    public static void asyncPostToExternal(set<id> setContactIds){
        postToExternal(setContactIds);
    }
    
}