@RestResource(urlMapping = '/createOrders')
global with sharing class XC_Aino_OrderService {

    public static final String CONVERSION_STATUS_NEW = 'New';

    @HttpPost
    global static String process() {

        RestRequest request = RestContext.request;
        String requestBody = request.requestBody.toString();

        //replacing restricted names
        requestBody.replace('"currency"', '"currency_x"');
        System.debug('>>> Request_Body:  ' + requestBody);

        List<XC_OrderStagingTable__c> orderStagingTables = new List<XC_OrderStagingTable__c>();
        List<OrderStagingTableWrapper> orderWrappers = new OrderStagingTableWrapper().parse(requestBody);

        for (OrderStagingTableWrapper orderStagingTableWrapper : orderWrappers){
            XC_OrderStagingTable__c orderStagingTable = new XC_OrderStagingTable__c();
            orderStagingTable.XC_OrderNumber__c = orderStagingTableWrapper.orderNumber;
            orderStagingTable.XC_OrderInformation__c = orderStagingTableWrapper.orderInformation;
            orderStagingTable.XC_ConversionStatus__c = CONVERSION_STATUS_NEW;

            orderStagingTables.add(orderStagingTable);
        }

        insert orderStagingTables;

        return 'success';
    }

    public class OrderStagingTableWrapper {
        public String orderNumber;
        public String orderInformation;

        public List<OrderStagingTableWrapper> parse(String json) {
            List<OrderStagingTableWrapper> orderStagingTableWrappers = new List<XC_Aino_OrderService.OrderStagingTableWrapper>();
            Map<String, Object> deserialized = (Map<String, Object>) System.JSON.deserializeUntyped(json);
            List<Map<String, Object>> ainoOrders = new List<Map<String, Object>>();

            for (Object instance : (List<Object>)deserialized.get('orders')) {
                ainoOrders.add((Map<String, Object>) instance);
            }

            for (Integer i = 0; i < ainoOrders.size(); i++){
                OrderStagingTableWrapper orderStagingTableWrapper = new OrderStagingTableWrapper();
                orderStagingTableWrapper.orderNumber = (String) (ainoOrders.get(i)).get('orderNumber');
                orderStagingTableWrapper.orderInformation = System.JSON.serialize(ainoOrders.get(i));

                orderStagingTableWrappers.add(orderStagingTableWrapper);
            }
            return orderStagingTableWrappers;
        }
    }
}