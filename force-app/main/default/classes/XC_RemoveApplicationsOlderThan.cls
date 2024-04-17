global without sharing class XC_RemoveApplicationsOlderThan implements Database.Batchable<SObject>, Schedulable {

    @TestVisible private static Date END_DATE = Date.today().addYears(-9);

    global Database.QueryLocator start(Database.BatchableContext context) {
        Date endDate = END_DATE;
        String query = 'SELECT Id FROM Application__c WHERE CreatedDate < :endDate';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext context, List<Application__c> applications) {
        try {
            delete applications;
        } catch(Exception e) {
            System.debug('Error deleting applications: ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext context) {
    }

    global void execute(SchedulableContext context) {
        Database.executeBatch(new XC_RemoveApplicationsOlderThan());
    }

}