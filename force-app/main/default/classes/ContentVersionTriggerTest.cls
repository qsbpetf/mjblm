@isTest
public with sharing class ContentVersionTriggerTest {

    private static final String STATUS_NEW = 'New';
    private static final String STATUS_TEMP = 'Temporary';
    private static final String RT_TEMP = 'Temp';
    private static final String RT_ONGOING = 'Ongoing';

    @IsTest
    static void shouldCorrectlySetFileSourceToApplicant_WhenAppTemp() {
        Application__c app = new Application__c(
                XC_Status__c = STATUS_TEMP,
                RecordTypeId = Schema.SObjectType.Application__c.getRecordTypeInfosByDeveloperName().get(RT_TEMP).getRecordTypeId()
        );
        insert app;

        ContentVersion cv = getTestCv(app);
        insert cv;

        cv = [SELECT XC_AddedBy__c FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        Assert.areEqual('Applicant', cv.XC_AddedBy__c);
    }

    @IsTest
    static void shouldCorrectlySetFileSourceToCertifier_WhenAppNew() {
        Application__c app = new Application__c(
                XC_Status__c = STATUS_NEW,
                RecordTypeId = Schema.SObjectType.Application__c.getRecordTypeInfosByDeveloperName().get(RT_ONGOING).getRecordTypeId()
        );
        insert app;

        ContentVersion cv = getTestCv(app);
        insert cv;

        cv = [SELECT XC_AddedBy__c FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        Assert.areEqual('Certifier', cv.XC_AddedBy__c);
    }

    @IsTest
    static void shouldChangeNumberOfAttachments_WhenInsertingNew() {
        Application__c app = new Application__c(
                XC_Status__c = STATUS_NEW,
                RecordTypeId = Schema.SObjectType.Application__c.getRecordTypeInfosByDeveloperName().get(RT_ONGOING).getRecordTypeId(),
                Bilaga_finns__c = false
        );
        insert app;

        ContentVersion cv = getTestCv(app);
        insert cv;

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cv.ContentDocumentId;
        cdl.LinkedEntityId = app.Id;
        cdl.ShareType = 'V';

        Test.startTest();
        ContentVersionTriggerHelper.updateApplication(new List<ContentVersion> { cv });
        Test.stopTest();

        app = [SELECT Bilaga_finns__c FROM Application__c WHERE Id = :app.Id];

        Assert.isTrue(app.Bilaga_finns__c);

    }

    @IsTest static void testQueueable() {
        Test.startTest();
        XC_UpdateFilesCount.start();
        Test.stopTest();
    }

    private static ContentVersion getTestCv(Application__c app) {
        ContentVersion cVersion = new ContentVersion();
        cVersion.ContentLocation = 'S';
        cVersion.Title = 'test';
        cVersion.PathOnClient = cVersion.Title + '.pdf';
        cVersion.VersionData = Blob.valueOf('test');
        cVersion.XC_Form_fileupload__c = app.Id;
        return cVersion;
    }
}