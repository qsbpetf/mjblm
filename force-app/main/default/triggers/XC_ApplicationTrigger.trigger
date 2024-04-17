trigger XC_ApplicationTrigger on Application__c (before update, after update, after insert, after delete, before delete) {
    (new ApplicationTriggerHandler()).run();
}