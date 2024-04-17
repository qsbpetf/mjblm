public with sharing class XC_NotifyNewApplicatiponsSchedulable implements Schedulable {

    private static final String MAJBLOMMAN_ORG_WIDE_ADDRESS_NAME = 'Majblomman Ansökningar';
    private static final OrgWideEmailAddress MAJBLOMMAN_ORG_WIDE_ADDRESS = getOwa();

    public void execute(SchedulableContext context) {
        String query = 'SELECT Name, XC_Epost__c, (SELECT Id FROM Applications__r WHERE (CreatedDate >= :startDate AND CreatedDate <= :endDate)';
        if (Test.isRunningTest()) {
            query += ' OR CreatedDate = TODAY';
        }
        query += ' ) FROM Account WHERE RecordTypeId = :rtId AND XC_Receive_Applications_Notifications__c = true';
        List<Account> accounts = Database.queryWithBinds(query, new Map<String, Object> {
            'startDate' => Date.today().addDays(-7),
            'endDate' => Date.today().addDays(-1),
            'rtId' => Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('XC_Lokalforening').getRecordTypeId()
        }, AccessLevel.USER_MODE);
        Set<Account> accountsToSend = new Set<Account> ();
        system.debug('query ' + query);
        system.debug('accounts ' + accounts);
        for (Account acc : accounts) {
            if (acc.Applications__r != null && !acc.Applications__r.isEmpty()) {
                accountsToSend.add(acc);
            }
        }
        system.debug('accountsToSend ' + accountsToSend);

        EmailTemplate template = [SELECT DeveloperName, HtmlValue, Subject FROM EmailTemplate WHERE DeveloperName = 'XC_Notify_New_Applications'];
        String period = Date.today().addDays(-7).format() + ' — ' + Date.today().addDays(-1).format();


        List<Messaging.SingleEmailMessage> msgs = new List<Messaging.SingleEmailMessage>();
        for (Account acc : accountsToSend) {
            if (String.isEmpty(acc.XC_Epost__c)) {
                continue;
            }
            Map<String, String> replacements = new Map<String, String> {
                '{recipient}' => acc.Name,
                '{period}' => period
            };
            msgs.add(
                EmailGenerator.getNew()
                    .addRecipient(acc.XC_Epost__c)
                    .usingTemplate(template)
                    .replace(replacements)
                    .usingOrgWideAddress(MAJBLOMMAN_ORG_WIDE_ADDRESS)
                    .getEmail()
            );
        }

        if (!msgs.isEmpty()) {
            Messaging.sendEmail(msgs, false);
        }
    }

    private static OrgWideEmailAddress getOwa() {
        return [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = :MAJBLOMMAN_ORG_WIDE_ADDRESS_NAME];
    }
}