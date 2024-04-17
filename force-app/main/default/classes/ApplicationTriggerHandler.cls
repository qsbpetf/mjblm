public with sharing class ApplicationTriggerHandler extends TriggerHandler {

    List<Application__c> newList = (List<Application__c>) Trigger.new;
    List<Application__c> oldList = (List<Application__c>) Trigger.old;
    Map<Id, Application__c> oldMap = (Map<Id, Application__c>) Trigger.oldMap;

    public override void afterUpdate() {
        ApplicationTriggerHelper.sendInfoEmails(newList, oldMap);
    }

    public override void beforeUpdate() {
        ApplicationTriggerHelper.setStatuses(newList, oldMap);
        ApplicationTriggerHelper.setRecordType(newList);
        ApplicationTriggerHelper.setOwner(newList, oldMap);
    }

    public override void afterDelete() {
        ApplicationTriggerHelper.deleteRelatedFiles(oldList);
    }

    public override void beforeDelete() {
        ApplicationTriggerHelper.deleteRelatedFiles(oldList);
    }
}