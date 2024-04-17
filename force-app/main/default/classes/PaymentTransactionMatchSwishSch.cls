public class PaymentTransactionMatchSwishSch implements Schedulable {

    public void execute(SchedulableContext SC) {
        Database.executeBatch(new PaymentTransactionMatchSwishBatch());
    }

}