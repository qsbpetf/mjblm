public with sharing class ContentVersionTriggerHandler extends TriggerHandler {

    List<ContentVersion> newList = (List<ContentVersion>) Trigger.new;

    public override void beforeInsert() {
        ContentVersionTriggerHelper.setFileSource(newList);
    }

    public override void afterInsert() {
        ContentVersionTriggerHelper.connectToApplications(newList);
        ContentVersionTriggerHelper.updateApplication(newList);
    }
}