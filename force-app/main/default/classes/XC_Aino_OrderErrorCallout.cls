public with sharing class XC_Aino_OrderErrorCallout implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {

    public static final String CONVERSION_STATUS_FAILED = 'Failed';
    public static final String CONTENT_TYPE_JSON = 'application/json';
    public static final String HTTP_METHOD_POST = 'POST';

    public Iterable<SObject> start(Database.BatchableContext param1) {
        return Database.getQueryLocator('SELECT XC_OrderNumber__c, XC_ConversionErrors__c ' +
                'FROM XC_OrderStagingTable__c WHERE XC_ConversionStatus__c = :CONVERSION_STATUS_FAILED');
    }

    public void execute(Database.BatchableContext param1, List<XC_OrderStagingTable__c> orderStagingTables) {
        Http http = new Http();
        List<OrderErrorWrapper> orderErrorWrappers = new OrderErrorWrapper().parseErrors(orderStagingTables);
        HttpRequest httpRequest = prepareRequest(orderErrorWrappers);
        HttpResponse httpResponse = new HttpResponse();
        try {
            httpResponse = http.send(httpRequest);
        }
        catch (Exception e) {
            System.debug('Callout Error: ' + e.getMessage());
        }
        if (httpResponse.getStatusCode() == 200) {
            delete orderStagingTables;
        }
    }

    public void finish(Database.BatchableContext param1) {
    }

    private HttpRequest prepareRequest(List<OrderErrorWrapper> orderErrorWrappers) {
        XC_AinoIntegration__c endpoint = [
                SELECT Endpoint_URL__c, Token__c
                FROM XC_AinoIntegration__c
                WHERE Call_Identifier__c = 'ordererrors'
        ];
        String requestBody = JSON.serialize(orderErrorWrappers);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint.Endpoint_URL__c);
        req.setHeader('Authorization', 'Bearer ' + endpoint.Token__c);
        req.setMethod(HTTP_METHOD_POST);
        req.setHeader('Content-Type', CONTENT_TYPE_JSON);
        req.setHeader('Content-Length', String.valueOf(requestBody.length()));
        req.setBody(requestBody);

        return req;
    }

    public class OrderErrorWrapper {
        public String orderNumber;
        public String errors;

        public List<OrderErrorWrapper> parseErrors(List<XC_OrderStagingTable__c> failedRecords) {
            List<OrderErrorWrapper> orderErrors = new List<XC_Aino_OrderErrorCallout.OrderErrorWrapper>();
            for (XC_OrderStagingTable__c ost : failedRecords) {
                OrderErrorWrapper orderErrorWrapper = new OrderErrorWrapper();
                orderErrorWrapper.orderNumber = ost.XC_OrderNumber__c;
                orderErrorWrapper.errors = ost.XC_ConversionErrors__c;
                orderErrors.add(orderErrorWrapper);

                System.debug('>>>OrderNumber: ' + ost.XC_OrderNumber__c);
                System.debug('>>>Errors: ' + ost.XC_ConversionErrors__c);
            }
            return orderErrors;
        }
    }

}