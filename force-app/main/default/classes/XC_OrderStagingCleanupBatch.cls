public with sharing class XC_OrderStagingCleanupBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {

    private static final String MAJBLOMMAN_ORG_WIDE_ADDRESS_NAME = 'Majblomman Ansökningar';
    private static final String BATCH_TEMPLATE_NAME = 'XC_StagingCleanupBatch';

    private Integer failed = 0;
    private Integer successed = 0;
    private Integer offset;

    public XC_OrderStagingCleanupBatch(Integer offset) {
        this.offset = offset;
    }

    public Database.QueryLocator start(Database.BatchableContext ctx) {
        return Database.getQueryLocator([SELECT Id FROM XC_OrderStagingTable__c WHERE CreatedDate < :Date.today().addDays(offset) AND XC_ConversionStatus__c = 'Converted']);
    }
    public void execute(Database.BatchableContext ctx, List<SObject> chunk) {
        try {
            delete chunk;
            successed += chunk.size();
        } catch (Exception e) {
            this.failed += chunk.size();
        }
    }

    public void finish(Database.BatchableContext ctx) {
        if (successed == 0 && failed == 0) {
            return;
        }
        String results = 'Successfully deleted ' + successed + ' records.<br> Records failed to delete: ' + failed;
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        OrgWideEmailAddress owa = [SELECT Address FROM OrgWideEmailAddress WHERE DisplayName = :MAJBLOMMAN_ORG_WIDE_ADDRESS_NAME];
        Map<String, String> replacements = new Map<String, String> {
                '{Results}' => results
        };
        emails.add(EmailGenerator.getNew()
                .addRecipient(owa.Address)
                .usingTemplate([SELECT DeveloperName, HtmlValue, Subject FROM EmailTemplate WHERE DeveloperName = :BATCH_TEMPLATE_NAME])
                .replace(replacements)
                .usingOrgWideAddress(owa)
                .getEmail());
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails, false);
        }
    }


    public void execute(SchedulableContext ctx) {
        Database.executeBatch(new XC_OrderStagingCleanupBatch(-90));
    }
}