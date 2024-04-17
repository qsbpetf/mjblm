public with sharing class ContentDocumentTriggerHandler extends TriggerHandler {

    public override void beforeDelete() {
        t(Trigger.old);
    }

    private void t(List<ContentDocument> documents) {
        documents = [SELECT (SELECT LinkedEntityId FROM ContentDocumentLinks) FROM ContentDocument WHERE Id IN :documents];

        Set<Id> applicationsToCheck = new Set<Id>();

        for (ContentDocument document : documents) {
            if (document.ContentDocumentLinks == null || document.ContentDocumentLinks.isEmpty()) {
                continue;
            }
            for (ContentDocumentLink link : document.ContentDocumentLinks) {
                applicationsToCheck.add(link.LinkedEntityId);
            }
        }

        XC_UpdateFilesCount.start(applicationsToCheck);
    }

}