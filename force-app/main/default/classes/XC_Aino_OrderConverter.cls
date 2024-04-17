public with sharing class XC_Aino_OrderConverter implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {

    public static final String CONVERSION_STATUS_NEW = 'New';
    public static final String CONVERSION_STATUS_FAILED = 'Failed';
    public static final String CONVERSION_STATUS_CONVERTED = 'Converted';
    public static final String PRIVATE_CUSTOMER_RT_DEV_NAME = 'XC_Privat_kund';
    public static final String SERVICE_TYPE_BAG = 'bag';
    public static final String SERVICE_TYPE_WEBSHOP = 'webshop';
    public static final String SERVICE_TYPE_CASH = 'cash';
    public static final String ORDER_STATUS_DRAFT = 'Draft';
    public static final String CUSTOMER_WITH_PHONE_ONLY_PREFIX = '[Endast telefonnummer] ';
    private Map<String, XC_OrderStagingTable__c> orderStagingTablesByOrderNumber;

    public Iterable<SObject> start(Database.BatchableContext param1) {
        return Database.getQueryLocator('SELECT Id, XC_OrderNumber__c, XC_OrderInformation__c, XC_ConversionStatus__c, XC_ConversionErrors__c ' +
                'FROM XC_OrderStagingTable__c WHERE XC_ConversionStatus__c = :CONVERSION_STATUS_NEW');
    }

    public void execute(Database.BatchableContext param1, List<XC_OrderStagingTable__c> orderStagingTables) {
        orderStagingTablesByOrderNumber = prepareOrderStagingTablesByOrderNumber(orderStagingTables);
        List<XC_AinoOrderUtils.OrderWrapper> orderWrappers = deserializeOrderInformation(orderStagingTables);
        Map<String, Id> sellersMap = mapSellerIdsToPrivateSellers(orderWrappers);
        Map<String, Id> phoneToPrivateCustomerMap = parseCustomers(orderWrappers);
        Map<String, Id> ordersByOrderNumber = parseWrappersToOrders(orderWrappers, sellersMap, phoneToPrivateCustomerMap);
        parseOrderItems(orderWrappers, ordersByOrderNumber);
        markRemainingAsConverted(orderStagingTables);
    }

    public void finish(Database.BatchableContext param1) {
    }

/*
 ******** PRIVATE METHODS ********
*/
    private Map<String, XC_OrderStagingTable__c> prepareOrderStagingTablesByOrderNumber(List<XC_OrderStagingTable__c> orderStagingTables) {
        Map<String, XC_OrderStagingTable__c> orderStagingTablesByOrderNumber = new Map<String, XC_OrderStagingTable__c>();

        for (XC_OrderStagingTable__c ost : orderStagingTables) {
            orderStagingTablesByOrderNumber.put(ost.XC_OrderNumber__c, ost);
        }

        return orderStagingTablesByOrderNumber;
    }

    private List<XC_AinoOrderUtils.OrderWrapper> deserializeOrderInformation(List<XC_OrderStagingTable__c> orderStagingTables) {
        List<XC_AinoOrderUtils.OrderWrapper> orderWrappers = new List<XC_AinoOrderUtils.OrderWrapper>();

        for (XC_OrderStagingTable__c ost : orderStagingTables) {
            XC_AinoOrderUtils.OrderWrapper wrapper = (XC_AinoOrderUtils.OrderWrapper) System.JSON.deserialize(ost.XC_OrderInformation__c, XC_AinoOrderUtils.OrderWrapper.class);
            orderWrappers.add(wrapper);
        }

        return orderWrappers;
    }

    private Map<String, Id> mapSellerIdsToPrivateSellers(List<XC_AinoOrderUtils.OrderWrapper> orderWrappers) {
        List<String> sellerIDs = new List<String>();
        Map<String, Id> sellerToPrivateSellerMap = new Map<String, Id>();
        for (XC_AinoOrderUtils.OrderWrapper wrapper : orderWrappers) {
            if (SERVICE_TYPE_BAG.equalsIgnoreCase(wrapper.serviceType) || SERVICE_TYPE_WEBSHOP.equalsIgnoreCase(wrapper.serviceType)) {
                sellerIDs.add(wrapper.sellerId);
            }
        }

        List<Contact> matchingSellers = [
                SELECT Id, XC_Webshop_ID__c, XC_Bag_ID__c
                FROM Contact
                WHERE XC_Bag_ID__c IN :sellerIDs OR XC_Webshop_ID__c IN :sellerIDs
        ];

        for (Contact con : matchingSellers) {
            sellerToPrivateSellerMap.put(con.XC_Webshop_ID__c, con.Id);
            sellerToPrivateSellerMap.put(con.XC_Bag_ID__c, con.Id);
        }

        return sellerToPrivateSellerMap;
    }

    private Map<String, Id> parseCustomers(List<XC_AinoOrderUtils.OrderWrapper> orderWrappers) {
        List<String> customerPhones = new List<String>();
        Map<String, XC_AinoOrderUtils.CustomerWrapper> customersByPhoneMap = new Map<String, XC_AinoOrderUtils.CustomerWrapper>();
        Map<String, String> customerPhoneToRelatedOrderNumber = new Map<String, String>();

        for (XC_AinoOrderUtils.OrderWrapper wrapper : orderWrappers) {
            if (wrapper.customer != null) {
                customerPhones.add(wrapper.customer.phoneNumber);
                customersByPhoneMap.put(wrapper.customer.phoneNumber, wrapper.customer);
                customerPhoneToRelatedOrderNumber.put(wrapper.customer.phoneNumber, wrapper.orderNumber);
            }
            else {
                orderStagingTablesByOrderNumber.get(wrapper.orderNumber).XC_ConversionStatus__c = CONVERSION_STATUS_FAILED;
                orderStagingTablesByOrderNumber.get(wrapper.orderNumber).XC_ConversionErrors__c = orderStagingTablesByOrderNumber.get(wrapper.orderNumber).XC_ConversionErrors__c == null ? 'ORDER: customer is missing'
                        : orderStagingTablesByOrderNumber.get(wrapper.orderNumber).XC_ConversionErrors__c + ' ORDER: customer is missing';
            }
        }

        update orderStagingTablesByOrderNumber.values();

        Id privateCustomerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get(PRIVATE_CUSTOMER_RT_DEV_NAME).getRecordTypeId();

        List<Account> customerAccounts = [
                SELECT Id, Phone, XC_Epost__c, Name, XC_Acceptera_Visa_Namn__c, XC_Acceptera_Villkoren__c, ShippingStreet, ShippingPostalCode,
                        ShippingCity, ShippingCountry, ShippingState
                FROM Account
                WHERE Phone IN :customerPhones AND RecordTypeId = :privateCustomerRecordTypeId
        ];

        updateExistingCustomers(customerAccounts, customersByPhoneMap);

        for (Account acc : customerAccounts) {
            if (customersByPhoneMap.containsKey(acc.Phone)) {
                customersByPhoneMap.remove(acc.Phone);
            }
        }
        createMissingCustomers(customersByPhoneMap.values(), customerPhoneToRelatedOrderNumber);

        customerAccounts = [
                SELECT Id, Phone
                FROM Account
                WHERE Phone IN :customerPhones AND RecordTypeId = :privateCustomerRecordTypeId
        ];

        Map<String, Id> privateCustomers = new Map<String, Id>();
        for (Account acc : customerAccounts) {
            privateCustomers.put(acc.Phone, acc.Id);
        }

        return privateCustomers;
    }

    private void updateExistingCustomers(List<Account> customerAccounts, Map<String, XC_AinoOrderUtils.CustomerWrapper> customersByPhoneMap) {
        List<Account> customersToUpdate = new List<Account>();
        Boolean customerUpdatedFlag;
        for (Account customer : customerAccounts) {
            customerUpdatedFlag = false;
            if (String.isBlank(customer.XC_Epost__c) && String.isNotBlank(customersByPhoneMap.get(customer.Phone).email)) {
                customer.XC_Epost__c = customersByPhoneMap.get(customer.Phone).email;
                customerUpdatedFlag = true;
            }
            if ((String.isNotBlank(customersByPhoneMap.get(customer.Phone).firstName) || String.isNotBlank(customersByPhoneMap.get(customer.Phone).lastName))) {
                customer.Name = customersByPhoneMap.get(customer.Phone).firstName + ' ' + customersByPhoneMap.get(customer.Phone).lastName;
                customerUpdatedFlag = true;
            }
            if (String.isBlank(customer.ShippingStreet) && (String.isNotBlank(customersByPhoneMap.get(customer.Phone).address1)
                    || String.isNotBlank(customersByPhoneMap.get(customer.Phone).address2))) {
                customer.ShippingStreet = customersByPhoneMap.get(customer.Phone).address1 + ' ' + customersByPhoneMap.get(customer.Phone).address2;
                customerUpdatedFlag = true;
            }
            if (String.isBlank(customer.ShippingPostalCode) && String.isNotBlank(customersByPhoneMap.get(customer.Phone).zipCode)) {
                customer.ShippingPostalCode = customersByPhoneMap.get(customer.Phone).zipCode?.split(' ')[0].replaceAll('[^0-9]','');
                customerUpdatedFlag = true;
            }
            if (String.isBlank(customer.ShippingCity) && String.isNotBlank(customersByPhoneMap.get(customer.Phone).city)) {
                customer.ShippingCity = customersByPhoneMap.get(customer.Phone).city;
                customerUpdatedFlag = true;
            }
            if (String.isBlank(customer.ShippingCountry) && String.isNotBlank(customersByPhoneMap.get(customer.Phone).country)) {
                customer.ShippingCountry = customersByPhoneMap.get(customer.Phone).country;
                customerUpdatedFlag = true;
            }
            if (String.isBlank(customer.ShippingState) && String.isNotBlank(customersByPhoneMap.get(customer.Phone).state)) {
                customer.ShippingState = customersByPhoneMap.get(customer.Phone).state;
                customerUpdatedFlag = true;
            }
            if (customersByPhoneMap.get(customer.Phone).acceptShowName != null &&
                    customer.XC_Acceptera_Villkoren__c != customersByPhoneMap.get(customer.Phone).acceptShowName) {
                customer.XC_Acceptera_Villkoren__c = customersByPhoneMap.get(customer.Phone).acceptShowName;
                customerUpdatedFlag = true;
            }
            if (customersByPhoneMap.get(customer.Phone).acceptTerms != null &&
                    customer.XC_Acceptera_Visa_Namn__c != customersByPhoneMap.get(customer.Phone).acceptTerms) {
                customer.XC_Acceptera_Visa_Namn__c = customersByPhoneMap.get(customer.Phone).acceptTerms;
                customerUpdatedFlag = true;
            }

            if (customerUpdatedFlag) {
                customersToUpdate.add(customer);
            }
        }

        if (!customersToUpdate.isEmpty()) {
            update customersToUpdate;
        }
    }

    private void createMissingCustomers(List<XC_AinoOrderUtils.CustomerWrapper> customersToCreate,
            Map<String, String> customerPhoneToRelatedOrderNumber) {
        List<Account> customersToInsert = new List<Account>();
        Id privateCustomerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get(PRIVATE_CUSTOMER_RT_DEV_NAME).getRecordTypeId();

        for (XC_AinoOrderUtils.CustomerWrapper wrapper : customersToCreate) {
            Account acc = new Account();

            acc.RecordTypeId = privateCustomerRecordTypeId;
            acc.XC_Epost__c = wrapper.email;
            if (String.isBlank(wrapper.firstName) && String.isBlank(wrapper.lastName)) {
                acc.Name = CUSTOMER_WITH_PHONE_ONLY_PREFIX + wrapper.phoneNumber;
            }
            else {
                acc.Name = (wrapper.firstName == null ? '' : wrapper.firstName) + ' ' + (wrapper.lastName == null ? '' : wrapper.lastName);
            }
            acc.Phone = wrapper.phoneNumber;
            //this check is necessary in case those two parameters won't be send
            acc.XC_Acceptera_Visa_Namn__c = wrapper.acceptShowName == null ? false : wrapper.acceptShowName;
            acc.XC_Acceptera_Villkoren__c = wrapper.acceptTerms == null ? false : wrapper.acceptTerms;
            acc.ShippingStreet = wrapper.address1 + ' ' + wrapper.address2;
            acc.ShippingPostalCode = wrapper.zipCode;
            acc.ShippingCity = wrapper.city;
            acc.ShippingCountry = wrapper.country;
            acc.ShippingState = wrapper.state;
            acc.XC_Skapad_av_aino__c = true;

            customersToInsert.add(acc);
        }

        Database.SaveResult[] srList = Database.insert(customersToInsert, false);
        Integer i = 0;
        for (Account acc : customersToInsert) {
            if (!srList[i].isSuccess()) {
                orderStagingTablesByOrderNumber.get(customerPhoneToRelatedOrderNumber.get(acc.Phone)).XC_ConversionStatus__c = CONVERSION_STATUS_FAILED;
                for (Database.Error err : srList[i].getErrors()) {
                    orderStagingTablesByOrderNumber.get(customerPhoneToRelatedOrderNumber.get(acc.Phone)).XC_ConversionErrors__c =
                            orderStagingTablesByOrderNumber.get(customerPhoneToRelatedOrderNumber.get(acc.Phone)).XC_ConversionErrors__c == null ? 'CUSTOMER: ' + err.getMessage()
                                    : orderStagingTablesByOrderNumber.get(customerPhoneToRelatedOrderNumber.get(acc.Phone)).XC_ConversionErrors__c + ' CUSTOMER: ' + err.getMessage() ;
                }
            }
            i++;
        }

        update orderStagingTablesByOrderNumber.values();
    }

    private Map<String, Id> parseWrappersToOrders(List<XC_AinoOrderUtils.OrderWrapper> orderWrappers,
            Map<String, Id> sellersMap, Map<String, Id> phoneToPrivateCustomerMap) {
        List<Order> ordersToInsert = new List<Order>();
        Id standardPricebookId;
        if (Test.isRunningTest()) {
            standardPricebookId = Test.getStandardPricebookId();
        }
        else {
            standardPricebookId = [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE].Id;
        }
        for (XC_AinoOrderUtils.OrderWrapper wrapper : orderWrappers) {
            Order order = populateOrder(wrapper, phoneToPrivateCustomerMap);
            order.Pricebook2Id = standardPricebookId;
            if (SERVICE_TYPE_BAG.equalsIgnoreCase(wrapper.serviceType) || SERVICE_TYPE_WEBSHOP.equalsIgnoreCase(wrapper.serviceType) || SERVICE_TYPE_CASH.equalsIgnoreCase(wrapper.serviceType)) {
                if (sellersMap.containsKey(wrapper.sellerId)) {
                    order.XC_Privat_Saljare__c = sellersMap.get(wrapper.sellerId);
                }
            }
            ordersToInsert.add(order);
        }

        Database.SaveResult[] srList = Database.insert(ordersToInsert, false);

        Integer i = 0;
        for (Order ord : ordersToInsert) {
            if (srList[i].isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully inserted order. Order ID: ' + srList[i].getId());
                orderStagingTablesByOrderNumber.get(ord.XC_OrderNumber__c).XC_ConversionStatus__c = CONVERSION_STATUS_CONVERTED;
            }
            else {
                // Operation failed, so get all errors
                orderStagingTablesByOrderNumber.get(ord.XC_OrderNumber__c).XC_ConversionStatus__c = CONVERSION_STATUS_FAILED;
                for (Database.Error err : srList[i].getErrors()) {
                    orderStagingTablesByOrderNumber.get(ord.XC_OrderNumber__c).XC_ConversionErrors__c =
                            orderStagingTablesByOrderNumber.get(ord.XC_OrderNumber__c).XC_ConversionErrors__c == null ? 'ORDER: ' + err.getMessage()
                                    : orderStagingTablesByOrderNumber.get(ord.XC_OrderNumber__c).XC_ConversionErrors__c + ' ORDER: ' + err.getMessage() ;
                }
            }
            i++;
        }

        update orderStagingTablesByOrderNumber.values();

        return mapOrdersByOrderNumber(ordersToInsert);
    }

    private Order populateOrder(XC_AinoOrderUtils.OrderWrapper wrapper, Map<String, Id> phoneToPrivateCustomerMap) {
        Order order = new Order();
        order.XC_OrderNumber__c = wrapper.orderNumber;
        order.XC_ServiceTyp__c = wrapper.serviceType;
        order.XC_BetalningsTyp__c = wrapper.paymentType;
        order.XC_Plats__c = wrapper.locale;
        order.XC_Skapad_i_Aino__c = wrapper.created;
        order.XC_SaljarId__c = wrapper.sellerId;

        if (wrapper.cart != null) {
            order.XC_Varukorg_Total__c = wrapper.cart.total;
            order.XC_Varukorg_Totalsumma__c = wrapper.cart.grandTotal;
            order.XC_Varukorg_Dricks__c = wrapper.cart.tip;
        }

        if (wrapper.customer != null) {
            order.XC_Privat_kund__c = phoneToPrivateCustomerMap.get(wrapper.customer.phoneNumber);
            order.AccountId = phoneToPrivateCustomerMap.get(wrapper.customer.phoneNumber);
            order.ShippingStreet = wrapper.customer.address1 + ' ' + wrapper.customer.address2;
            order.ShippingPostalCode = wrapper.customer.zipCode;
            order.ShippingCity = wrapper.customer.city;
            order.ShippingCountry = wrapper.customer.country;
            order.ShippingState = wrapper.customer.state;
        }

        if (wrapper.paymentData != null) {
            order.EffectiveDate = wrapper.created.date();
            order.Status = ORDER_STATUS_DRAFT;
            order.XC_Betaldatum__c = wrapper.paymentData.datePaid;
            order.XC_Belopp__c = wrapper.paymentData.amount;
            order.XC_MottagareBetalningsreferens__c = wrapper.paymentData.payeePaymentReference;
            order.XC_Betalningsreferens__c = wrapper.paymentData.paymentReference;
            order.XC_Betalningsstatus__c = wrapper.paymentData.status;
            order.XC_Callback_URL__c = wrapper.paymentData.callbackUrl;
            order.XC_Betalnings_ID__c = wrapper.paymentData.id;
            order.XC_Felmeddelande__c = wrapper.paymentData.errorMessage;
            order.XC_Felkod__c = wrapper.paymentData.errorCode;
            order.XC_Meddelande__c = wrapper.paymentData.message;
            order.XC_Valuta__c = wrapper.paymentData.currency_x;
            order.XC_Betalarens_Alias__c = wrapper.paymentData.payerAlias;
            order.XC_Mottagare_Alias__c = wrapper.paymentData.payeeAlias;
        }

        return order;
    }

    private Map<String, Id> mapOrdersByOrderNumber(List<Order> orders) {
        Map<String, Id> orderNumberToOrderIdMap = new Map<String, Id>();

        if (!orders.isEmpty()) {
            for (Order order : orders) {
                if (order.Id != null) {
                    orderNumberToOrderIdMap.put(order.XC_OrderNumber__c, order.Id);
                }
            }
        }

        return orderNumberToOrderIdMap;
    }

    private void parseOrderItems(List<XC_AinoOrderUtils.OrderWrapper> orderWrappers, Map<String, Id> ordersByOrderNumber) {
        List<OrderItem> orderItemsToInsert = new List<OrderItem>();
        Map<String, Id> productsSKUbyId = mapProductSKUbyId();
        Map<Id, Id> pricebookEntriesByProductsIds = mapPBEsByProductId();

        for (XC_AinoOrderUtils.OrderWrapper orderWrapper : orderWrappers) {
            if (ordersByOrderNumber.containsKey(orderWrapper.orderNumber)) {
                for (XC_AinoOrderUtils.CartItemWrapper itemWrapper : orderWrapper.cart.items) {
                    OrderItem item = new OrderItem();
                    item.Quantity = itemWrapper.quantity;
                    item.OrderId = ordersByOrderNumber.get(orderWrapper.orderNumber);
                    item.XC_Order_Number__c = orderWrapper.orderNumber;
                    item.XC_BildUrl__c = itemWrapper.image;
                    item.XC_Namn_Sv__c = itemWrapper.name.sv;
                    item.XC_Namn_Eng__c = itemWrapper.name.en;
                    item.XC_Sku__c = itemWrapper.sku.trim();
                    //this check is necessary in case this parameter won't be send
                    item.XC_arGava__c = itemWrapper.isGift == null ? false : itemWrapper.isGift;
                    item.PricebookEntryId = pricebookEntriesByProductsIds.get(productsSKUbyId.get(itemWrapper.sku.trim()));
                    item.UnitPrice = itemWrapper.price;

                    orderItemsToInsert.add(item);
                }
            }
        }
        Database.SaveResult[] srList = Database.insert(orderItemsToInsert, false);

        Integer i = 0;
        List<Id> ordersFailedAtOrderItems = new List<Id>();
        for (OrderItem orderItem : orderItemsToInsert) {
            if (!srList[i].isSuccess()) {
                // Operation failed, so get all errors
                orderStagingTablesByOrderNumber.get(orderItem.XC_Order_Number__c).XC_ConversionStatus__c = CONVERSION_STATUS_FAILED;
                for (Database.Error err : srList[i].getErrors()) {
                    orderStagingTablesByOrderNumber.get(orderItem.XC_Order_Number__c).XC_ConversionErrors__c =
                            orderStagingTablesByOrderNumber.get(orderItem.XC_Order_Number__c).XC_ConversionErrors__c == null ? 'ORDER ITEM: ' + err.getMessage()
                                    : orderStagingTablesByOrderNumber.get(orderItem.XC_Order_Number__c).XC_ConversionErrors__c + ' ORDER ITEM: ' + err.getMessage() ;
                }
                ordersFailedAtOrderItems.add(orderItem.OrderId);
            }
            i++;
        }

        update orderStagingTablesByOrderNumber.values();
        Database.delete(ordersFailedAtOrderItems);
    }

    private Map<String, Id> mapProductSKUbyId() {
        List<Product2> products = [SELECT Id, StockKeepingUnit FROM Product2];
        Map<String, Id> skuById = new Map<String, Id>();
        
        for (Product2 p : products) {
            skuById.put(p.StockKeepingUnit, p.Id);
        }

        return skuById;
    }

    private Map<Id, Id> mapPBEsByProductId() {
        List<PricebookEntry> pricebookEntries = [SELECT Id, Product2.Id FROM PricebookEntry];
        Map<Id, Id> pricebookEntriesByProductIds = new Map<Id, Id>();

        for(PricebookEntry pbe : pricebookEntries) {
            pricebookEntriesByProductIds.put(pbe.Product2.Id, pbe.Id);
        }

        return pricebookEntriesByProductIds;
    }

    private void markRemainingAsConverted(List<XC_OrderStagingTable__c> orderStagingTables) {
        List<XC_OrderStagingTable__c> orderStagingTablesToUpdate = [
                SELECT Id, XC_ConversionStatus__c
                FROM XC_OrderStagingTable__c
                WHERE Id IN :orderStagingTables AND XC_ConversionStatus__c = :CONVERSION_STATUS_NEW
        ];

        for (XC_OrderStagingTable__c ost : orderStagingTablesToUpdate) {
            ost.XC_ConversionStatus__c = CONVERSION_STATUS_CONVERTED;
        }

        update orderStagingTablesToUpdate;
    }
}