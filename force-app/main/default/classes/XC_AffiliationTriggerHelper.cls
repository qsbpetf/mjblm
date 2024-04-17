public with sharing class XC_AffiliationTriggerHelper {

    private static final String RT_KONTAKT = 'XC_Kontakt';
    private static final String RT_SKOLA = 'XC_Skola';
    private static final String KONTAKT_RT = Schema.SObjectType.npe5__Affiliation__c.getRecordTypeInfosByDeveloperName().get(RT_KONTAKT).getRecordTypeId();


    public static void initSkolaAffiliationsRecordType(List<npe5__Affiliation__c> newAffs) {
        Set<Id> accsIds = new Set<Id>();
        for (npe5__Affiliation__c affiliation : newAffs) {
            accsIds.add(affiliation.npe5__Organization__c);
        }

        Map<Id, Account> accsMap = new Map<Id, Account> ([SELECT Id, RecordType.DeveloperName FROM Account WHERE RecordType.DeveloperName = :RT_SKOLA AND Id in :accsIds]);

        for (npe5__Affiliation__c affiliation : newAffs) {
            if (accsMap.containsKey(affiliation.npe5__Organization__c)) {
                affiliation.RecordTypeId = KONTAKT_RT;
            }
        }
    }

}