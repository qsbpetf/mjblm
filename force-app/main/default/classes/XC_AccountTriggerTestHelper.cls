@IsTest
public with sharing class XC_AccountTriggerTestHelper {

    public static Map<String, Id> getRecordTypes() {
        Map<String, Id> result = new Map<String, Id>();
        for (RecordType rt : [SELECT DeveloperName FROM RecordType WHERE DeveloperName = :XC_Constants.MEMBER_RECORD_TYPE OR DeveloperName = :XC_Constants.CONTACT_RECORD_TYPE]) {
            result.put(rt.DeveloperName, rt.Id);
        }
        return result;
    }

    public static String getRecordTypeId(String name) {
        return [SELECT Id FROM RecordType WHERE DeveloperName = :name].Id;
    }

}