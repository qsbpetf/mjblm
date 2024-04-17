@isTest
public with sharing class ApplicationTriggerTest {

    private static final String STATUS_NEW = 'New';
    private static final String APPROVED = 'Approved';
    private static final String ACCEPTED = 'Accepted';
    private static final String REJECTED = 'Rejected';
    private static final String ONGOING = 'Ongoing';
    private static final String TEMPORARY = 'Temporary';
    private static final String RT_TEMPORARY = 'Temp';

    @IsTest
    static void testSetCorrectRecordTypeOngoing() {
        Application__c app = new Application__c(
                XC_Status__c = TEMPORARY,
                RecordTypeId = Schema.SObjectType.Application__c.getRecordTypeInfosByDeveloperName().get(RT_TEMPORARY).getRecordTypeId()
        );

        insert app;

        app.XC_Status__c = STATUS_NEW;
        update app;

        app = [SELECT RecordType.DeveloperName FROM Application__c WHERE Id = :app.Id];
        Assert.areEqual(ONGOING, app.RecordType.DeveloperName);
    }

    @IsTest
    static void testSetCorrectRecordTypeApproved() {
        Application__c app = new Application__c(
                XC_Status__c = TEMPORARY,
                RecordTypeId = Schema.SObjectType.Application__c.getRecordTypeInfosByDeveloperName().get(RT_TEMPORARY).getRecordTypeId()
        );

        insert app;

        app.XC_Status__c = APPROVED;
        update app;

        app = [SELECT RecordType.DeveloperName FROM Application__c WHERE Id = :app.Id];
        Assert.areEqual(ACCEPTED, app.RecordType.DeveloperName);
    }

    @IsTest
    static void testSetCorrectRecordTypeRejected() {
        Application__c app = new Application__c(
                XC_Status__c = TEMPORARY,
                RecordTypeId = Schema.SObjectType.Application__c.getRecordTypeInfosByDeveloperName().get(RT_TEMPORARY).getRecordTypeId()
        );

        insert app;

        app.XC_Status__c = REJECTED;
        update app;

        app = [SELECT RecordType.DeveloperName FROM Application__c WHERE Id = :app.Id];
        Assert.areEqual(REJECTED, app.RecordType.DeveloperName);
    }

    @IsTest
    static void testSendEmailWhenApplicationApproved() {
        Application__c app = new Application__c(
                XC_Status__c = TEMPORARY,
                RecordTypeId = Schema.SObjectType.Application__c.getRecordTypeInfosByDeveloperName().get(RT_TEMPORARY).getRecordTypeId()
        );

        insert app;

        app.XC_Status__c = APPROVED;
        update app;

        Assert.areEqual(1, Limits.getEmailInvocations());
        Assert.areEqual(1, ApplicationTriggerHelper.emailsSent);
    }

    @IsTest
    static void testSendEmailWhenApplicationSubmitted() {
        Application__c app = new Application__c(
                XC_Status__c = TEMPORARY,
                RecordTypeId = Schema.SObjectType.Application__c.getRecordTypeInfosByDeveloperName().get(RT_TEMPORARY).getRecordTypeId()
        );

        insert app;

        app.XC_Status__c = STATUS_NEW;
        app.XC_IntygsskrivarensEpost__c = 'test@test.se';
        update app;

        Assert.areEqual(1, Limits.getEmailInvocations());
        Assert.areEqual(2, ApplicationTriggerHelper.emailsSent);
    }

    @IsTest
    static void testSendEmailWhenApplicationSubmittedNoCertifierEmail() {
        Application__c app = new Application__c(
                XC_Status__c = TEMPORARY,
                RecordTypeId = Schema.SObjectType.Application__c.getRecordTypeInfosByDeveloperName().get(RT_TEMPORARY).getRecordTypeId()
        );

        insert app;

        app.XC_Status__c = STATUS_NEW;
        update app;

        Assert.areEqual(0, Limits.getEmailInvocations());
        Assert.areEqual(0, ApplicationTriggerHelper.emailsSent);
    }

    @IsTest
    static void testSendEmailWhenCertifierUpdated() {
        Application__c app = new Application__c(
                XC_Status__c = STATUS_NEW,
                XC_UpdatedByCertifier__c = false,
                RecordTypeId = Schema.SObjectType.Application__c.getRecordTypeInfosByDeveloperName().get(ONGOING).getRecordTypeId()
        );

        insert app;

        app.XC_UpdatedByCertifier__c = true;
        update app;

        Assert.areEqual(1, Limits.getEmailInvocations());
        Assert.areEqual(1, ApplicationTriggerHelper.emailsSent);
    }

    @IsTest
    static void testDeleteFiels_WhenApplicationDeleted() {
        Application__c app = new Application__c(
                XC_Status__c = STATUS_NEW,
                RecordTypeId = Schema.SObjectType.Application__c.getRecordTypeInfosByDeveloperName().get(ONGOING).getRecordTypeId()
        );
        insert app;

        insert getTestCv(app);
        Assert.areEqual(1, [SELECT COUNT() FROM ContentVersion]);

        delete app;
        Assert.areEqual(0, [SELECT COUNT() FROM ContentVersion]);
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