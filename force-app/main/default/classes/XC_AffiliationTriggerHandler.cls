public with sharing class XC_AffiliationTriggerHandler extends TriggerHandler {

    List<npe5__Affiliation__c> newList = (List<npe5__Affiliation__c>) Trigger.new;
    List<npe5__Affiliation__c> oldList = (List<npe5__Affiliation__c>) Trigger.old;
    Map<Id, npe5__Affiliation__c> oldMap = (Map<Id, npe5__Affiliation__c>) Trigger.oldMap;

    public override void beforeInsert() {
        XC_AffiliationTriggerHelper.initSkolaAffiliationsRecordType(newList);
    }
}