public with sharing class XC_AinoOrderUtils {

    public class OrderWrapper {
        public Datetime created;
        public PaymentDataWrapper paymentData;
        public String serviceType;
        public String paymentType;
        public String locale;
        public String orderNumber;
        public String sellerId;
        public CustomerWrapper customer;
        public CartWrapper cart;
    }

    public class CustomerWrapper {
        public String email;
        public String lastName;
        public String firstName;
        public Boolean acceptShowName;
        public String address1;
        public String address2;
        public String zipCode;
        public String city;
        public String country;
        public String state;
        public Boolean acceptTerms;
        public String phoneNumber;
    }

    public class PaymentDataWrapper {
        public Datetime datePaid;
        public Integer amount;
        public String payeePaymentReference;
        public String status;
        public String callbackUrl;
        public String id;
        public String errorMessage;
        public String paymentReference;
        public Integer errorCode;
        public String message;
        public String currency_x;
        public Datetime dateCreated;
        public String payerAlias;
        public String payeeAlias;
    }

    public class CartWrapper {
        public List<CartItemWrapper> items;
        public Double tip;
        public Double grandTotal;
        public Double total;
    }

    public class CartItemWrapper {
        public Integer quantity;
        public Double price;
        public Double totalPrice;
        public String image;
        public CartItemNameWrapper name;
        public String sku;
        public Boolean isGift;
    }

    public class CartItemNameWrapper {
        public String en;
        public String sv;
    }
}