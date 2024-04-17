trigger ContentDocumentTrigger on ContentDocument (before delete, after insert) {
    (new ContentDocumentTriggerHandler()).run();
}