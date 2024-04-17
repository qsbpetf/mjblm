@IsTest
private class XC_AffiliationTriggerTest {

    private static final String RT_SKOLA = 'XC_Skola';
    private static final String SKOLA_RT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(RT_SKOLA).getRecordTypeId();
    private static final String RT_KONTAKT = 'XC_Kontakt';
    private static final String KONTAKT_RT = Schema.SObjectType.npe5__Affiliation__c.getRecordTypeInfosByDeveloperName().get(RT_KONTAKT).getRecordTypeId();
    private static final String RT_MEDLEM = 'XC_Medlem';
    private static final String MEDLEM_RT = Schema.SObjectType.npe5__Affiliation__c.getRecordTypeInfosByDeveloperName().get(RT_MEDLEM).getRecordTypeId();
    private static final String RT_MAJBLOMMAN_KONTAKT = 'XC_Majblomman_Kontakt';
    private static final String MAJBLOMMAN_KONTAKT_RT = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(RT_MAJBLOMMAN_KONTAKT).getRecordTypeId();

    @IsTest
    static void testChangeRecordType() {

        Account acc = new Account(
                Name = 'testacc',
                RecordTypeId = SKOLA_RT
        );
        insert acc;
        Contact c = new Contact(LastName = 'testcon',
                                RecordTypeId = MAJBLOMMAN_KONTAKT_RT);
        insert c;

        npe5__Affiliation__c aff = new npe5__Affiliation__c(
                npe5__Organization__c = acc.Id,
                npe5__Contact__c = c.Id,
                RecordTypeId = KONTAKT_RT
        );

        Test.startTest();
        insert aff;
        update aff;
        Test.stopTest();

        aff = [SELECT RecordTypeId FROM npe5__Affiliation__c WHERE Id = :aff.Id];

        Assert.areEqual(KONTAKT_RT, aff.RecordTypeId);

    }
}