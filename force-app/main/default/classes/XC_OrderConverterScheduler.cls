public with sharing class XC_OrderConverterScheduler implements Schedulable{

    public static String schedule00 = '0 0 * * * ?';
    public static String schedule30 = '0 30 * * * ?';

    public void execute(SchedulableContext param1) {
        Database.executeBatch(new XC_Aino_OrderConverter());
    }

    public static String scheduleMe() {
        XC_OrderConverterScheduler converter = new XC_OrderConverterScheduler();
        String job;
        String job1;
        
        if (Test.isRunningTest()){
            job = System.schedule('XC_Aino_OrderConverter' + Date.today(), schedule00, converter);
        }
        else {
            job = System.schedule('XC_Aino_OrderConverter1', schedule00, converter);
            job1 = System.schedule('XC_Aino_OrderConverter2', schedule30, converter);
        }
        return job;
    }
}