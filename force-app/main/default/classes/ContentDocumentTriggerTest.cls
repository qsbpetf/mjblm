@IsTest
private class ContentDocumentTriggerTest {

    private static final String STATUS_NEW = 'New';
    private static final String RT_ONGOING = 'Ongoing';

    @IsTest
    static void shouldChangeNumberOfAttachments_WhenRemoving() {
        Application__c app = new Application__c(
                XC_Status__c = STATUS_NEW,
                RecordTypeId = Schema.SObjectType.Application__c.getRecordTypeInfosByDeveloperName().get(RT_ONGOING).getRecordTypeId(),
                Bilaga_finns__c = true
        );
        insert app;

        ContentVersion cv = getTestCv(app);
        insert cv;
        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cv.ContentDocumentId;
        cdl.LinkedEntityId = app.Id;
        cdl.ShareType = 'V';

        Test.startTest();
        delete new ContentDocument(Id = cv.ContentDocumentId);
        Test.stopTest();

        app = [SELECT Bilaga_finns__c FROM Application__c WHERE Id = :app.Id];

        Assert.isFalse(app.Bilaga_finns__c);
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