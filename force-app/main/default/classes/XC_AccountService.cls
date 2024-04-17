public with sharing class XC_AccountService {

    private static final String RT_LF = [SELECT Id FROM RecordType WHERE DeveloperName = 'XC_Lokalforening'].Id;
    private static final String STATUS_UPPHORD ='Upphörd';

    public static void setMembersInactiveWhenAccountCanceled(List<Account> accounts) {
        if (isAsyncContext()) {
            return;
        }
        Map<Id, Account> oldAccounts = (Map<Id, Account>) Trigger.oldMap;
        List<Id> accountIdsToConsider = new List<Id>();
        for (Account acc : accounts) {
            if (acc.RecordTypeId == RT_LF && acc.LF_Status__c == STATUS_UPPHORD && oldAccounts.get(acc.Id).LF_Status__c != STATUS_UPPHORD) {
                accountIdsToConsider.add(acc.Id);
            }
        }
        if (!accountIdsToConsider.isEmpty()) {
            Database.executeBatch(new XC_SetLFMembersInactive(accountIdsToConsider));
        }
    }

    public static void setLfNumber(List<Account> accounts) {
        Integer highestLf = Integer.valueOf(getHighestLf());
        for (Account acc : accounts) {
            if (acc.RecordTypeId == RT_LF) {
                acc.XC_LF_Nummer2__c = ++highestLf;
            }
        }
    }


    private static Boolean isAsyncContext() {
        return System.isFuture() || System.isBatch();
    }

    private static Decimal getHighestLf() {
        List<Account> mostRecentProjects = [SELECT XC_LF_Nummer2__c FROM Account WHERE XC_LF_Nummer2__c != null ORDER BY XC_LF_Nummer2__c DESC LIMIT 1];
        if (mostRecentProjects.isEmpty()) {
            return 0;
        }
        return mostRecentProjects[0].XC_LF_Nummer2__c;
    }

}