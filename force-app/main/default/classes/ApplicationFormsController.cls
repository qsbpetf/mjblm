public without sharing class ApplicationFormsController {

    @AuraEnabled
    public static Application__c getApplication(String formId) {
        try {
            Application__c app = ApplicationFormsService.getApplication(formId);
            return app;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String apply(Application__c application, List<XC_ApplicationEntryChild__c> children) {
        try {
            String res = ApplicationFormsService.apply(application, children);
            return res;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static void updateApplication(Application__c form) {
        try {
            Application__c form1 = form;
            ApplicationFormsService.updateApplication(form1);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static void updateApplicationsBulk(List<Application__c> forms) {
        try {
            List<Application__c> form1 = forms;
            ApplicationFormsService.updateApplicationsBulk(form1);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static Id createTemporary() {
        try {
            Id res;
            res = ApplicationFormsService.createTemporary();
            return res;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<XC_Kommun__c> getKommuns() {
        try {
            List<XC_Kommun__c> res;
            res = ApplicationFormsService.getKommuns();
            return res;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Account> getLfs(String kommun) {
        try {
            List<Account> accs = ApplicationFormsService.getLfs(kommun);
            return accs;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Contact> getApplicationContacts(String applicationId) {
        try {
            List<Contact> res = ApplicationFormsService.getApplicationContacts(applicationId);
            return res;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Application__c> getDuplicated(Id appId) {
        try {
            List<Application__c> apps = ApplicationFormsService.getDuplicated(appId);
            return apps;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Application__c> getAllApplications() {
        try {
            List<Application__c> apps = ApplicationFormsService.getAllApplications();
            return apps;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Contact> getApproversForCurrentUser(){
        try {
            List<Contact> approvers = ApplicationFormsService.getApproversForCurrentUser();
            return approvers;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Application__c> getLatestApplications(Id appId, Integer monthsOld) {
        try {
            List<Application__c> apps = ApplicationFormsService.getLatestApplications(appId, monthsOld);
            return apps;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Id getCurrentUserAccountId() {
        try {
            Id usrId = ApplicationFormsService.getCurrentUserAccountId();
            return usrId;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<ApplicationFormsService.PicklistEntryWrapper> getApplicationStatuses() {
        List<ApplicationFormsService.PicklistEntryWrapper> res = ApplicationFormsService.getApplicationStatuses();
        return res;
    }

    @AuraEnabled
    public static Application__c getApplicationBySfId(String appId) {
        try {
            Application__c app = ApplicationFormsService.getApplicationBySfId(appId);
            return app;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static List<ApplicationFormsService.PicklistEntryWrapper> getRejectionReasons() {
        List<ApplicationFormsService.PicklistEntryWrapper> res = ApplicationFormsService.getRejectionReasons();
        return res;
    }

    @AuraEnabled
    public static Boolean checkLinkValidity(String formId) {
        try {
            Boolean res = ApplicationFormsService.checkLinkValidity(formId);
            return res;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static Account getPreselectedLf(String lfNumber) {
        try {
            Account lf  = ApplicationFormsService.getPreselectedLf(lfNumber);
            return lf;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Application__c initEmptyApp() {
        try {
            Application__c app = ApplicationFormsService.initEmptyApp();
            return app;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void removeOldFiles(String formId) {
        try {
            ApplicationFormsService.removeOldFiles(formId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


}