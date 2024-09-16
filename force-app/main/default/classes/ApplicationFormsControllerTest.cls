@IsTest
private class ApplicationFormsControllerTest {

    private static final String TEMPORARY = 'Temporary';
    private static final String RT_TEMPORARY = 'Temp';
    private static final String FORM_ID = '123456789';
    private static final String STATUS_NEW = 'New';
    private static final String ONGOING = 'Ongoing';
    private static final String LF_STATUS_AKTIV = 'Aktiv';
    private static final String MEMBER_STATUS_CURRENT = 'Current';
    private static final String MAJBLOMMAN_ROLE = 'Majblomman';


    @TestSetup
    static void initData() {
        Application__c appTemp = new Application__c(
                XC_Status__c = TEMPORARY,
                RecordTypeId = Schema.SObjectType.Application__c.getRecordTypeInfosByDeveloperName().get(RT_TEMPORARY).getRecordTypeId()
        );
        Application__c appNew = new Application__c(
                XC_Status__c = STATUS_NEW,
                XC_FormId__c = FORM_ID,
                XC_LinkValidDate__c = Date.today().addDays(7),
                RecordTypeId = Schema.SObjectType.Application__c.getRecordTypeInfosByDeveloperName().get(ONGOING).getRecordTypeId()
        );
        insert new List<Application__c> { appTemp, appNew };
    }
    @IsTest
    static void testGetApplicationByFormId() {
        Application__c app = [SELECT Id, XC_FormId__c FROM Application__c WHERE XC_FormId__c = :FORM_ID];

        Application__c app1 = ApplicationFormsController.getApplication(app.XC_FormId__c);

        Assert.areEqual(app.Id, app1.Id);
    }

    @IsTest
    static void testApply() {
        Application__c app = [SELECT Id FROM Application__c WHERE XC_Status__c = :TEMPORARY LIMIT 1];
        List<XC_ApplicationEntryChild__c> children = new List<XC_ApplicationEntryChild__c> {
                new XC_ApplicationEntryChild__c()
        };

        String formId = ApplicationFormsController.apply(app, children);
        Assert.areNotEqual(null, formId);

        app = [SELECT (SELECT Id FROM Barnen__r) FROM Application__c WHERE XC_FormId__c = :formId];
        Assert.areNotEqual(null, app);
        Assert.areEqual(1, app.Barnen__r.size());
    }

    @IsTest
    static void testUpdateApplication() {
        Application__c app = [SELECT Id FROM Application__c WHERE XC_Status__c = :TEMPORARY LIMIT 1];
        app.XC_Status__c = STATUS_NEW;
        ApplicationFormsController.updateApplication(app);

        app = [SELECT XC_Status__c FROM Application__c WHERE Id = :app.Id LIMIT 1];
        Assert.areNotEqual(TEMPORARY, app.XC_Status__c);
    }

    @IsTest
    static void testCreateTempApplication() {

        Id tempId = ApplicationFormsController.createTemporary();

        Application__c app = [SELECT XC_Status__c FROM Application__c WHERE Id = :tempId];
        Assert.areEqual(TEMPORARY, app.XC_Status__c);
    }

    @IsTest
    static void testGetKommuns() {
        XC_Kommun__c kommun = new XC_Kommun__c();
        insert kommun;

        List<XC_Kommun__c> getKommuns = ApplicationFormsController.getKommuns();
        Assert.areEqual(1, getKommuns.size());
    }

    @IsTest
    static void testGetApplicationLfs() {
        XC_Kommun__c kommun = new XC_Kommun__c(Name = 'Kommun');
        insert kommun;

        Account acc = new Account(
                Name = 'acc',
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('XC_Lokalforening').getRecordTypeId(),
                LF_Status__c = LF_STATUS_AKTIV,
                XC_Kommun__c = kommun.Id
        );
        insert acc;

        List<Account> lfs = ApplicationFormsController.getLfs('Kommun');

        Assert.areEqual(1, lfs.size());
        Assert.areEqual(acc.Id, lfs[0].Id);
    }

    @IsTest
    static void testGetApplicationContacts() {

        Account acc = new Account(
                Name = 'acc',
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('XC_Lokalforening').getRecordTypeId(),
                LF_Status__c = LF_STATUS_AKTIV
        );
        insert acc;

        Contact c = new Contact(LastName = 'name');
        insert c;

        npe5__Affiliation__c aff = new npe5__Affiliation__c(
                npe5__Organization__c = acc.Id,
                npe5__Contact__c = c.Id,
                npe5__Status__c = MEMBER_STATUS_CURRENT
        );
        insert aff;

        Application__c app = new Application__c (
                XC_LF__c = acc.Id
        );
        insert app;

        List<Contact> cs = ApplicationFormsController.getApplicationContacts(app.Id);

        Assert.areEqual(1, cs.size());

    }

    @IsTest
    static void testFindDuplicatedApplications() {
        Application__c app1 = new Application__c(
                XC_Status__c = STATUS_NEW,
                RecordTypeId = Schema.SObjectType.Application__c.getRecordTypeInfosByDeveloperName().get(ONGOING).getRecordTypeId(),
                XC_FormId__c = '123'
        );
        Application__c app2 = new Application__c(
                XC_Status__c = STATUS_NEW,
                RecordTypeId = Schema.SObjectType.Application__c.getRecordTypeInfosByDeveloperName().get(ONGOING).getRecordTypeId(),
                XC_FormId__c = '456'
        );
        insert new List<Application__c> { app1, app2 };

        XC_ApplicationEntryChild__c entry1 = new XC_ApplicationEntryChild__c(
                XC_Application__c = app1.Id,
                XC_Personnummer__c = 'duplicated'
        );
        XC_ApplicationEntryChild__c entry2 = new XC_ApplicationEntryChild__c(
                XC_Application__c = app2.Id,
                XC_Personnummer__c = 'duplicated'
        );
        insert new List<XC_ApplicationEntryChild__c> { entry1, entry2 };


        List<Application__c> dupliacted = ApplicationFormsController.getDuplicated(app1.Id);

        Assert.areEqual(1, dupliacted.size());
        Assert.areEqual(app2.XC_FormId__c, dupliacted[0].XC_FormId__c);

    }

    @IsTest
    static void testGetCurrentUserAccId() {
        Account acc = new Account( Name = 'name');
        insert acc;
        Contact c = new Contact(
                Email = 'test+test@gmail.com.test',
                AccountId = acc.Id,
                FirstName = 'lululululu',
                LastName = 'tesname'
        );
        insert c;
        User curr = new User(
                Id = UserInfo.getUserId(),
                UserRoleId = [SELECT DeveloperName FROM UserRole WHERE DeveloperName = :MAJBLOMMAN_ROLE].Id
        );
        User usr =  new User(
                ContactId = c.Id,
                FirstName = c.FirstName,
                LastName =c .LastName,
                Username = c.Email + Datetime.now().getTime(),
                isActive = true,
                email = c.Email,
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Volunteer Community User'].Id,
                emailencodingkey = 'UTF-8',
                alias = 'alias',
                languagelocalekey = 'en_US',
                localesidkey = 'en_US',
                timezonesidkey = 'America/Los_Angeles',
                CommunityNickname = c.Email
        );
        System.runAs(curr) {
            update curr;
            insert usr;
        }
        System.runAs(usr) {
            Id accId = ApplicationFormsController.getCurrentUserAccountId();
            Assert.areEqual(acc.Id, accId);
        }

    }

    @IsTest
    static void testGetApplicationStatuses() {
        List<ApplicationFormsService.PicklistEntryWrapper> plew = ApplicationFormsController.getApplicationStatuses();

        Assert.areNotEqual(0, plew.size());
    }

    @IsTest
    static void testGetApplicationBySFId() {
        Application__c app = [SELECT Id FROM Application__c WHERE XC_FormId__c = :FORM_ID];

        Application__c app1 = ApplicationFormsController.getApplicationBySfId(app.Id);

        Assert.areEqual(app.Id, app1.Id);
    }

    @IsTest
    static void testGetRejectionReasons() {
        List<ApplicationFormsService.PicklistEntryWrapper> plew = ApplicationFormsController.getRejectionReasons();

        Assert.areNotEqual(0, plew.size());
    }

    @IsTest
    static void testCheckLinkValidityValid() {
        Application__c app = [SELECT XC_FormId__c FROM Application__c WHERE XC_Status__c = :STATUS_NEW];
        app.XC_UpdatedByCertifier__c = false;
        update app;

        Boolean valid = ApplicationFormsController.checkLinkValidity(app.XC_FormId__c);

        Assert.isTrue(valid);
    }

    @IsTest
    static void testCheckLinkValidityInvalid() {
        Application__c app = [SELECT XC_FormId__c FROM Application__c WHERE XC_Status__c = :STATUS_NEW];
        app.XC_UpdatedByCertifier__c = true;
        update app;

        Boolean valid = ApplicationFormsController.checkLinkValidity(app.XC_FormId__c);

        Assert.isFalse(valid);
    }

    @IsTest
    static void testGetLfByLfNummer() {
        Account acc = new Account(Name = 'name', XC_LF_Nummer2__c = 1);
        insert acc;

        Account acc2 = ApplicationFormsController.getPreselectedLf(String.valueOf(acc.XC_LF_Nummer2__c));
        Assert.areEqual(acc.Id, acc2.Id);
    }

    @IsTest
    static void testGetLfByLfNummerArgumentNull() {

        Boolean exceptionThrown = false;
        try {
            Account acc2 = ApplicationFormsController.getPreselectedLf(null);
        } catch (Exception e) {
            exceptionThrown = true;
        }

        Assert.isTrue(exceptionThrown);
    }

    @IsTest
    static void testInitEmptyApp() {
        Application__c app = ApplicationFormsController.initEmptyApp();
        Assert.areNotEqual(null, app);
    }

    @IsTest
    static void testGetApplicationBySFIdNullArg() {

        Boolean exceptionThrown = false;
        try {
            Application__c app1 = ApplicationFormsController.getApplicationBySfId(null);
        } catch (Exception e) {
            exceptionThrown = true;
        }

        Assert.isTrue(exceptionThrown);
    }

    @IsTest
    static void testUpdateApplicationNullArg() {

        Boolean exceptionThrown = false;
        try {
            ApplicationFormsController.updateApplication(null);
        } catch (Exception e) {
            exceptionThrown = true;
        }

        Assert.isTrue(exceptionThrown);
    }

    @IsTest
    static void testRemoveOldFiles() {
        Application__c app = [SELECT Id, XC_FormId__c FROM Application__c WHERE XC_FormId__c = :FORM_ID];

        ContentVersion cVersion = new ContentVersion();
        cVersion.ContentLocation = 'S';
        cVersion.Title = 'test';
        cVersion.PathOnClient = cVersion.Title + '.pdf';
        cVersion.VersionData = Blob.valueOf('test');
        cVersion.XC_Form_fileupload__c = app.Id;
        cVersion.XC_AddedBy__c= 'Certifier';
        cVersion.XC_Form_fileupload__c = app.Id;
        insert cVersion;

        List<ContentVersion> cvs = [SELECT Id FROM ContentVersion];
        Assert.areEqual(1, cvs.size());

        ApplicationFormsController.removeOldFiles(app.Id);

        cvs = [SELECT Id FROM ContentVersion];
        Assert.areEqual(0, cvs.size());
    }

}