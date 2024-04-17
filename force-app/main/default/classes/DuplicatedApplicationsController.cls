public with sharing class DuplicatedApplicationsController {

    private final Application__c app;
    private List<Application__c> apps;

    public Application__c getApp() {
        return this.app;
    }

    public List<Application__c> getApps() {
        return this.apps;
    }

    public DuplicatedApplicationsController(ApexPages.StandardController stdController) {
        Id appId = ((Application__c) stdController.getRecord()).Id;
        this.app = [SELECT Id, XC_FormId__c, (SELECT XC_Personnummer__c FROM Barnen__r ) FROM Application__c WHERE Id = :appId];
        Set<String> childrensPersonNummers = new Set<String>();
        Set<String> childrensIds = new Set<String>();
        for (XC_ApplicationEntryChild__c child : this.app.Barnen__r) {
            childrensPersonNummers.add(child.XC_Personnummer__c);
            childrensIds.add(child.Id);
        }
        List<XC_ApplicationEntryChild__c> children = [SELECT XC_Application__c FROM XC_ApplicationEntryChild__c WHERE XC_Personnummer__c IN :childrensPersonNummers AND Id NOT IN :childrensIds];
        Set<Id> applications = new Set<Id>();
        for (XC_ApplicationEntryChild__c child : children) {
            applications.add(child.XC_Application__c);
        }
        this.apps = [SELECT Id, XC_FormId__c FROM Application__c WHERE Id IN :applications];
    }

}