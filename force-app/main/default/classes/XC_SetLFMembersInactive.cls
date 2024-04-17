public with sharing class XC_SetLFMembersInactive implements Database.Batchable<SObject> {

    private List<Id> accountIds;

    public XC_SetLFMembersInactive(List<Id> accountIds) {
        this.accountIds = accountIds;
    }

    public List<npe5__Affiliation__c> start(Database.BatchableContext ctx) {
        return [SELECT
                npe5__Status__c
        FROM
                npe5__Affiliation__c
        WHERE
                npe5__Organization__c IN :this.accountIds
        AND
                RecordType.DeveloperName = :XC_Constants.MEMBER_RECORD_TYPE];
    }

    public void execute(Database.BatchableContext ctx, List<npe5__Affiliation__c> scope) {
        for (npe5__Affiliation__c aff : scope) {
            aff.npe5__Status__c = XC_Constants.MEMBER_INACTIVE;
        }
        update scope;
    }

    public void finish(Database.BatchableContext ctx) {
    }

}