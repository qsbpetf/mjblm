public class Utils {

    public Set<String> createStringSet(List<sObject> recordList, String fieldAPIName){
        Set<String> newSet = new Set<String>();
        for(sObject record: recordList){
            if(record.get(fieldAPIName) != null){
                String value = (String) record.get(fieldAPIName);
                newSet.add(value);
            }
        }
        return newSet;
    }



    public Map<String, sObject> createStringToObjMap(List<sObject> recordList, String keyFieldAPIName){
        Map<String, sObject> newMap = new Map<String, sObject>();
        for(sObject record: recordList){
            String key = (String) record.get(keyFieldAPIName);
            newMap.put(key, record);
        }
        return newMap;
    }

}