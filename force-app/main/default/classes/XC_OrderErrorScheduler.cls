public with sharing class XC_OrderErrorScheduler implements Schedulable{

    public static String schedule00 = '0 00 * * * ?';
    public static String schedule15 = '0 15 * * * ?';
    public static String schedule30 = '0 30 * * * ?';
    public static String schedule45 = '0 45 * * * ?';

    public void execute(SchedulableContext param1) {
        Database.executeBatch(new XC_Aino_OrderErrorCallout());
    }

    public static String scheduleMe() {
        XC_OrderErrorScheduler scheduler = new XC_OrderErrorScheduler();
        String job;

        if (Test.isRunningTest()){
            job = System.schedule('XC_Aino_OrderErrorCallout' + Date.today(), schedule15, scheduler);
        }
        else {
            job = System.schedule('XC_Aino_OrderErrorCallout00', schedule00, scheduler);
            String job1 = System.schedule('XC_Aino_OrderErrorCallout15', schedule15, scheduler);
            String job2 = System.schedule('XC_Aino_OrderErrorCallout30', schedule30, scheduler);
            String job3 = System.schedule('XC_Aino_OrderErrorCallout45', schedule45, scheduler);
        }
        return job;
    }
}