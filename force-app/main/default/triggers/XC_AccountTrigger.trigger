trigger XC_AccountTrigger on Account (before insert, after update) {


    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            List<Account> newAccounts = (List<Account>) Trigger.new;
            XC_AccountService.setLfNumber(newAccounts);
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            List<Account> newAccounts = (List<Account>) Trigger.new;
            XC_AccountService.setMembersInactiveWhenAccountCanceled(newAccounts);
        }
    }



}