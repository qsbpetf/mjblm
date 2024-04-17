trigger XC_AffiliationTrigger on npe5__Affiliation__c (before update) {

    Map<Id, npe5__Affiliation__c> newAffiliation = (Map<Id, npe5__Affiliation__c>) Trigger.newMap;
    Map<Id, npe5__Affiliation__c> oldAffiliation = (Map<Id, npe5__Affiliation__c>) Trigger.oldMap;
    
    XC_AffiliationService.updateHistoriskRollAndDatum(newAffiliation, oldAffiliation);
}