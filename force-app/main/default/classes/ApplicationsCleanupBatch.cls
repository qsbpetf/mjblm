public without sharing class ApplicationsCleanupBatch implements Database.Batchable<SObject>, Schedulable, Database.Stateful {

    private static final String MAJBLOMMAN_ORG_WIDE_ADDRESS_NAME = 'Majblomman Ansökningar';
    private static final String BATCH_ERROR_TEMPLATE_NAME = 'XC_BatchError';

    @TestVisible private List<String> errors = new List<String>();
    private static final String STATUS_TEMPORARY = 'Temporary';
    private static final String CRON_EVERY_HOUR = '0 0 * ? * *';

    public List<Application__c> start(Database.BatchableContext ctx) {
        Integer timeToAdd = Test.isRunningTest() ? 1 : -1;
        DateTime oneHourAgo = DateTime.now().addHours(timeToAdd);
        return [SELECT XC_FormId__c FROM Application__c WHERE CreatedDate < :oneHourAgo AND XC_Status__c = :STATUS_TEMPORARY];
    }

    public void execute(Database.BatchableContext ctx, List<Application__c> apps) {
        List<Database.DeleteResult> results = Database.delete(apps, false);
        for (Database.DeleteResult res : results) {
            if (!res.isSuccess()) {
                String error = '';
                for(Database.Error err : res.getErrors()) {
                    error += res.getId() + ': ' + err.getStatusCode() + ': ' + err.getMessage();
                }
                this.errors.add(error);
            }
        }
    }

    public void finish(Database.BatchableContext ctx) {
        if (this.errors.isEmpty()) {
            return;
        }
        this.sendErrorEmail(String.join(this.errors, '\n'));
    }

    private void sendErrorEmail(String errors) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        OrgWideEmailAddress owa = [SELECT Address FROM OrgWideEmailAddress WHERE DisplayName = :MAJBLOMMAN_ORG_WIDE_ADDRESS_NAME];
        Map<String, String> replacements = new Map<String, String> {
                '{Errors}' => errors
        };
        emails.add(EmailGenerator.getNew()
                .addRecipient(owa.Address)
                .usingTemplate([SELECT DeveloperName, HtmlValue, Subject FROM EmailTemplate WHERE DeveloperName = :BATCH_ERROR_TEMPLATE_NAME])
                .replace(replacements)
                .usingOrgWideAddress(owa)
                .getEmail());
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails, false);
        }
    }

    public static void schedule() {
        System.schedule('Applications cleanup batch ' + Request.getCurrent().getRequestId(), CRON_EVERY_HOUR ,new ApplicationsCleanupBatch());
    }

    public static void execute(SchedulableContext ctx) {
        Database.executeBatch(new ApplicationsCleanupBatch());
    }
}