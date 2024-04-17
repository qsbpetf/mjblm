public without sharing class XC_UpdateFilesCount implements Database.Batchable<SObject>, Queueable {

    private final Set<Id> applicationsToCheck;

    public static void start() {
        System.enqueueJob(new XC_UpdateFilesCount());
    }

    public static void start(Set<Id> applicationsToCheck) {
        System.enqueueJob(new XC_UpdateFilesCount(applicationsToCheck));
    }

    private XC_UpdateFilesCount() {}

    private XC_UpdateFilesCount(Set<Id> applicationsToCheck) {
        this.applicationsToCheck = applicationsToCheck;
    }

    public List<Application__c> start(Database.BatchableContext context) {
        if (applicationsToCheck == null) {
            return [SELECT (SELECT Id FROM ContentDocumentLinks) FROM Application__c];
        } else {
            return [SELECT (SELECT Id FROM ContentDocumentLinks) FROM Application__c WHERE Id IN :applicationsToCheck];
        }
    }

    public void execute(Database.BatchableContext context, List<Object> records) {
        List<Application__c> apps = (List<Application__c>) records;
        for(Application__c app : apps) {
            if (app.ContentDocumentLinks == null | app.ContentDocumentLinks.size() == 0) {
                app.Bilaga_finns__c = false;
            } else {
                app.Bilaga_finns__c = true;
            }
        }
        update apps;
    }

    public void finish(Database.BatchableContext context) {
    }

    public void execute(QueueableContext context) {
        if (applicationsToCheck == null) {
            Database.executeBatch(new XC_UpdateFilesCount());
        } else {
            Database.executeBatch(new XC_UpdateFilesCount(this.applicationsToCheck));
        }
    }
}