/**
 * Created by peterfriberg on 2024-09-18.
 */

@IsTest
private class ApplicationFormsServiceTest {

    private static final String MEMBER_STATUS_CURRENT = 'Current';
    private static final String EXPERIENCE_USER_ROLE = 'msebbPersonkontoPartner';
    private static final String MAJBLOMMAN_ROLE = 'Majblomman';
    private static final String LF_STATUS_AKTIV = 'Aktiv';

    @TestSetup
    static void prepare() {
        // Create a user with a role
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        UserRole r = [SELECT Id FROM UserRole WHERE DeveloperName = :MAJBLOMMAN_ROLE LIMIT 1];

        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@testorg.com',
            Username = 'testuser' + Integer.valueOf(Math.ceil(Math.random() * 1000000)) + '@testorg.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            UserRoleId = r.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert u;

        // Use runAs() to create records as the new user
        System.runAs(u) {

            Account acc = new Account(
                Name = 'acc',
                // RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('XC_Lokalforening').getRecordTypeId(),
                LF_Status__c = LF_STATUS_AKTIV
            );
            insert acc;

            Contact c = new Contact(
                LastName = 'name',
                Email = 'test+test@gmail.com.test',
                AccountId = acc.Id
            );
            insert c;

            npe5__Affiliation__c aff = new npe5__Affiliation__c(
                npe5__Organization__c = acc.Id,
                npe5__Contact__c = c.Id,
                npe5__Status__c = MEMBER_STATUS_CURRENT,
                RecordTypeId = Schema.SObjectType.npe5__Affiliation__c.getRecordTypeInfosByDeveloperName().get('XC_Kontakt').getRecordTypeId()
            );
            insert aff;

            Application__c app = new Application__c (
                XC_LF__c = acc.Id
            );
            insert app;
        }
    }

    @IsTest
    static void testGetApplicationContacts() {
        Id volunteerProfileId = [SELECT Id FROM Profile WHERE Name = 'Volunteer Community User'].Id;
        Id experienceUserRoleId = [SELECT Id FROM UserRole WHERE DeveloperName = :EXPERIENCE_USER_ROLE].Id;
        System.debug('*** volunteerProfileId: ' + volunteerProfileId);
        System.debug('*** experienceUserRoleId: ' + experienceUserRoleId);

        Contact c = [SELECT Id, FirstName, LastName, Email, Owner.UserRole.Name FROM Contact LIMIT 1];
        Account a = [SELECT Id, Name, Owner.UserRole.Name FROM Account LIMIT 1];
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];

        System.debug('CONTACT: ' + c);
        System.debug('ACCOUNT: ' + a);

        User usr = new User(
            ContactId = c.Id,
            FirstName = 'Adam', // c.FirstName,
            LastName = 'Kalle', // c.LastName,
            Username = 'asdasd.asdasd' + Integer.valueOf(Math.ceil(Math.random() * 1000000)) + '@sdfsdf.se', // c.Email + Datetime.now().getTime(),
            IsActive = true,
            Email = 'asdasd.asdasd@sdfsdf.se', //c.Email,
            ProfileId = volunteerProfileId,
            EmailEncodingKey = 'UTF-8',
            Alias = 'alias',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            CommunityNickname = 'sdfsdfsdf' //, // c.Email,
            // UserRoleId = experienceUserRoleId
        );

        System.debug('usr: ' + usr);

        System.runAs(usr) {
            // Assert expected values
            List<Contact> cs = ApplicationFormsController.getApplicationContacts(app.Id);
            System.assertEquals(1, cs.size());
        }
    }
}