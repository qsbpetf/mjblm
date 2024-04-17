trigger ContentVersionTrigger on ContentVersion (before insert, after insert, before delete) {
    (new ContentVersionTriggerHandler()).run();
}