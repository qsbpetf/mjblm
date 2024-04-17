public with sharing class XC_AffiliationService {
    
    public static void updateHistoriskRollAndDatum(Map<Id, npe5__Affiliation__c> newAffiliation, Map<Id, npe5__Affiliation__c> oldAffiliation) {

        for (npe5__Affiliation__c newAff : newAffiliation.values()) {
            if (oldAffiliation.containsKey(newAff.Id)) {
                npe5__Affiliation__c oldAff = oldAffiliation.get(newAff.Id);
                if (newAff.XC_Medlemskategorier__c != oldAff.XC_Medlemskategorier__c) {
                    Datetime lastModified = newAff.LastModifiedDate;
                    String oldRole = oldAff.XC_Medlemskategorier__c;
                    if (oldRole != null) {
                        List<String> oldRoles = oldRole.split(';');
                        String dateAndRole = '';
                        for (String role : oldRoles) {
                            List<String> roles = role.split('-');
                            if (dateAndRole == '') {
                                dateAndRole = lastModified.format('YYYY-MM-dd') + ' - ' + roles[0];
                            } else {
                                dateAndRole = dateAndRole + ';' + lastModified.format('YYYY-MM-dd') + ' - ' + roles[0];
                            }
                        }
                        if (oldAff.Historisk_Roll_Datum__c == null) {
                            newAffiliation.get(newAff.Id).Historisk_Roll_Datum__c = dateAndRole;
                        } else {
                            newAffiliation.get(newAff.Id).Historisk_Roll_Datum__c = oldAff.Historisk_Roll_Datum__c + ';' + dateAndRole;
                        }
                    }
                }
            }
        }
    }
}