public with sharing class XC_Daily_Order_Summary_Schedule implements Schedulable {

    public void execute(SchedulableContext ctx) {
        Database.executeBatch(new XC_Daily_Order_Summary_Batch());
    }

    public static Id scheduleMe() {
        String cron = '0 0 3 ? * * *';
        return System.schedule('Daily summary started: ' + Date.today(), cron, new XC_Daily_Order_Summary_Schedule());
    }
}