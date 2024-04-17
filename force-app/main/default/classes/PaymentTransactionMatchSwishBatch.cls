/**
     * 
     * Betalningar som sker spontant via swish, så vi har inga opportunities som ligger och väntar
     * vi skapar opportunities
     * fast innan vi skapar Oppar är att vi har Swish Admin records -> Config för användare att välja campagn/produkt för swishen
     * Skapa ett lookup fält på Swish admin för att kunna koppla en produkt
     * Swish admin används för att sätta Campaign, Produkt, donation type på opp/oppLine
     * Om vi inte hittar träff på en swish admin så är det bara en vanlig donation (ingen campaign sätts, ingen produkt heller)
     * 
     * 
     * Vi letar Kontakt via telefonnumret -> om vi inte hittar så skapar vi en ny kontakt annars använder vi den kontakte
     * 
     * Vi skapar Opp/OppLineItem
     * 
     * Efter att vi skapat upp ett Opp, så skapar npsp upp ett payment
     * 
     * Vi försöker sen match payment med payment transaction (axnpsp__Payment_Reference_ID__c, npe01__Check_Reference_Number__c, axnpsp__Transaction_ID_OCR_Bankgiro_Reference__c)
     * 
     * Vi har ingen axnpsp__Transaction_ID_OCR_Bankgiro_Reference__c (payment transaction, ej unik)
     * 
     * 1. Hitta match mot swish Admin via swish nummer och swish ref / 
     *      Prio Ordning Swish Admin Match
     *          1. Nummer && Ref != null
     *          2. Nummer && Ref == null
     *          3. No match on swish admin (No specific campaign or product)
     *          
     * 2. Hitta Kontakt via MobilePhone, (om ingen träff, skapa Kontakt)
     * 3. Skapa Opp, OppLineItem
     * 4. Queria Payments
     * 5. Match Payments med Payment Transactions.
     * 
     */

public class PaymentTransactionMatchSwishBatch implements Database.Batchable<sObject> {

    Utils utils; 
    Product2 donationProduct;

    public PaymentTransactionMatchSwishBatch(){

        this.utils = new Utils();
        this.donationProduct = getDonationProduct();
    }


    public Database.QueryLocator start(Database.BatchableContext BC) {

        return database.getQueryLocator([
            SELECT 
                Id, 
                axnpsp__Swish_Amount__c, 
                axnpsp__Payment__c, 
                axnpsp__Campaign__c, 
                axnpsp__Swish_Payment_Reference__c,
                axnpsp__Swish_Payer_mobile__c, 
                axnpsp__Swish_number__c,  
                axnpsp__Swish_Payer_Name__c,
                axnpsp__Swish_Payment_Date__c,
                axnpsp__Payment_Transaction_Origin__c, 
                axnpsp__Match_Method__c, 
                axnpsp__Match_Status__c, 
                axnpsp__Transaction_ID_OCR_Bankgiro_Reference__c
            FROM axnpsp__Payment_Transaction__c
            WHERE axnpsp__Match_Status__c IN('No Match', null) 
            AND axnpsp__Swish_number__c != null
            AND axnpsp__Payment_Transaction_Origin__c IN('Swish Handel','Swish Foretag') 
            AND axnpsp__Swish_Amount__c > 0
        ]);

    
    }

    public void execute(Database.BatchableContext BC, List<axnpsp__Payment_Transaction__c> paymentTransactionList) {

        //Create a set of swishReferences
        Set<String> swishIds = utils.createStringSet(paymentTransactionList, 'axnpsp__Transaction_ID_OCR_Bankgiro_Reference__c');
        Set<String> swishReferences = utils.createStringSet(paymentTransactionList, 'axnpsp__Swish_Payment_Reference__c');

        //Match against exising opportunities before creating new ones
        List<npe01__OppPayment__c> paymentToUpd = new List<npe01__OppPayment__c>();
        
        List<axnpsp__Payment_Transaction__c> matchedPaymentTransactionsToUpd = new List<axnpsp__Payment_Transaction__c>();

        List<Contact> contactsToUpdate = new List<Contact>();

        List<npe01__OppPayment__c> existingPayments = getPaymentsByReference(swishIds);

        Map<String, SObject> existingPaymentsMap = utils.createStringToObjMap(existingPayments, 'npe01__Check_Reference_Number__c');

        for(axnpsp__Payment_Transaction__c paymentTransaction: paymentTransactionList){

            String paymentRef = paymentTransaction.axnpsp__Transaction_ID_OCR_Bankgiro_Reference__c;

            npe01__OppPayment__c existingPayment = (npe01__OppPayment__c) existingPaymentsMap.get(paymentRef);

            if(existingPayment != null){

                paymentTransaction.axnpsp__Match_Method__c = 'Automatic';
                paymentTransaction.axnpsp__Match_Status__c = 'Matched';
                paymentTransaction.axnpsp__Payment__c = existingPayment.Id;
                existingPayment.npe01__Paid__c = true;
                existingPayment.npe01__Payment_Date__c = paymentTransaction.axnpsp__Swish_Payment_Date__c;

                paymentToUpd.add(existingPayment);
                matchedPaymentTransactionsToUpd.add(paymentTransaction);

                if(existingPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.FirstName == 'Swish' && existingPayment.npe01__Opportunity__r.npsp__Primary_Contact__r.LastName == 'Swish'){

                    Map<String, String> nameMap = getName(paymentTransaction.axnpsp__Swish_Payer_Name__c);
                    
                    Contact con = new Contact(Id=existingPayment.npe01__Opportunity__r.npsp__Primary_Contact__c);

                    con.FirstName = nameMap.get('firstName') != null ? nameMap.get('firstName') : con.FirstName;
                    con.LastName = nameMap.get('lastName') != null ? nameMap.get('lastName') : con.LastName;
                    contactsToUpdate.add(con);
                }
            }
        }
        if(paymentToUpd.size() > 0){
            update paymentToUpd;
            update matchedPaymentTransactionsToUpd;
            Set<axnpsp__Payment_Transaction__c> allPaymenttransactions = new Set<axnpsp__Payment_Transaction__c>(paymentTransactionList);
            allPaymenttransactions.removeAll(matchedPaymentTransactionsToUpd);
            paymentTransactionList.clear();
            paymentTransactionList.addAll(allPaymenttransactions);
            if(!contactsToUpdate.isEmpty()){
                update contactsToUpdate;
            }
        }

        //Create new Opportunities and payments for new transactions

        //Create a set of merchant swishNumber
        Set<String> swishNumbers = utils.createStringSet(paymentTransactionList, 'axnpsp__Swish_number__c');
        

        //Create a set of payer phones to find contacts
        Set<String> formatedSwishPayerPhones = formatSwishPhoneNumbers(paymentTransactionList);

        //get swish admins
        List<axnpsp__AXSP_Swish_Admin__c> swishAdmins = getSwishAdmins(swishNumbers, swishReferences);

        //Create a map of Swish Admins where number + ref is the key
        Map<String, axnpsp__AXSP_Swish_Admin__c> swishAdminsMap = createSwishAdminMap(swishAdmins);

        //get contacts
        List<Contact> relatedContacts = getContactsByMobilePhone(formatedSwishPayerPhones);

        //Create a map for the contacts
        Map<String, SObject> relatedContactsMap = utils.createStringToObjMap(relatedContacts, 'MobilePhone');
        
        //Create and update contacts for numbers that are without
        List<Contact> contactsToUpsert = new List<Contact>();

        for(axnpsp__Payment_Transaction__c paymentTransaction: paymentTransactionList){

            String phoneNumber = formatSwishPhoneNumber(paymentTransaction.axnpsp__Swish_Payer_mobile__c);
            Contact relatedContact = (Contact) relatedContactsMap.get(phoneNumber);

            if(relatedContact != null){

                if(relatedContact.FirstName == 'Swish' && relatedContact.LastName == 'Swish'){

                    Map<String, String> nameMap = getName(paymentTransaction.axnpsp__Swish_Payer_Name__c);
                    relatedContact.FirstName = nameMap.get('firstName') != null ? nameMap.get('firstName') : relatedContact.FirstName;
                    relatedContact.LastName = nameMap.get('lastName') != null ? nameMap.get('lastName') : relatedContact.LastName;
                    relatedContact.MobilePhone = phoneNumber;
                    contactsToUpsert.add(relatedContact);
                }
            } else {

                Contact con = createContact(paymentTransaction);
                contactsToUpsert.add(con);
                relatedContactsMap.put(con.MobilePhone, con); //Add contact to existing map to avoid quering again
            }
        }

        upsert contactsToUpsert;


        List<Opportunity> oppToInsert = new List<Opportunity>();
        List<Opportunity_Line_Item__c> oppLineItemToInsert = new List<Opportunity_Line_Item__c>();

        //Create Opp and oppLineItem
        for(axnpsp__Payment_Transaction__c paymentTransaction: paymentTransactionList){
            Contact con = (Contact) relatedContactsMap.get(formatSwishPhoneNumber(paymentTransaction.axnpsp__Swish_Payer_mobile__c));

            String swishAdminKey = createSwishAdminKey(paymentTransaction);
            axnpsp__AXSP_Swish_Admin__c swishAdmin = swishAdminsMap.get(swishAdminkey);

            Opportunity opp = createOpportunity(paymentTransaction, swishAdmin, con.Id);
            Opportunity_Line_Item__c oppLineItem = createOpportunityLineItem(opp, paymentTransaction, swishAdmin, con.Id);
            oppToInsert.add(opp);
            oppLineItemToInsert.add(oppLineItem);

        }

        insert oppToInsert;
        insert oppLineItemToInsert;


        //Payments are automatically created from Opps, need to query them
        List<npe01__OppPayment__c> payments = getPayments(oppToInsert);
        Map<String, npe01__OppPayment__c> paymentsMap = new Map<String, npe01__OppPayment__c>();
        for(npe01__OppPayment__c payment: payments){
            paymentsMap.put(payment.npe01__Opportunity__r.axnpsp__Payment_Reference_ID__c, payment);
        }

        List<npe01__OppPayment__c> paymentsToUpd = new List<npe01__OppPayment__c>();
        List<axnpsp__Payment_Transaction__c> paymentTransactionsToUpd = new List<axnpsp__Payment_Transaction__c>();

        for(axnpsp__Payment_Transaction__c paymentTransaction: paymentTransactionList){
            npe01__OppPayment__c payment = (npe01__OppPayment__c) paymentsMap.get(paymentTransaction.Id);
            if(payment != null){
                payment.npe01__Paid__c = true;
                payment.npe01__Payment_Date__c = paymentTransaction.axnpsp__Swish_Payment_Date__c;
                paymentTransaction.axnpsp__Match_Method__c = 'Automatic';
                paymentTransaction.axnpsp__Match_Status__c = 'Matched';
                paymentTransaction.axnpsp__Payment__c = payment.Id;
                paymentsToUpd.add(payment);
                paymentTransactionsToUpd.add(paymentTransaction);
            }
        }

        update paymentsToUpd;
        update paymentTransactionsToUpd;
    }

    public void finish(Database.BatchableContext BC) {
    }

    

    public String createSwishAdminKey(axnpsp__Payment_Transaction__c paymentTransaction){
        String swishAdminkey = '';
        swishAdminkey += paymentTransaction.axnpsp__Swish_number__c;
        swishAdminkey += paymentTransaction.axnpsp__Swish_Payment_Reference__c != null ? paymentTransaction.axnpsp__Swish_Payment_Reference__c : '';
        return swishAdminkey;
    }

    public Opportunity createOpportunity(axnpsp__Payment_Transaction__c paymentTransaction, axnpsp__AXSP_Swish_Admin__c swishAdmin, String contactId) {
        Id OpportunityDonationId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('AXSP Donation').getRecordTypeId();
        Opportunity newOpp = new Opportunity();
        newOpp.Name = 'Default Name';
        newOpp.axnpsp__Donor_Type__c = 'Private';
        newOpp.StageName = 'Pledged';
        newOpp.RecordTypeId = OpportunityDonationId;
        newOpp.Amount = paymentTransaction.axnpsp__Swish_Amount__c;
        newOpp.CloseDate = paymentTransaction.axnpsp__Swish_Payment_Date__c;
        newOpp.axnpsp__Payment_Method__c = 'Swish';
        newOpp.CampaignId = swishAdmin?.axnpsp__Campaign__c;
        newOpp.npsp__Primary_Contact__c  = contactId;
        newOpp.axnpsp__Payment_Reference_ID__c = paymentTransaction.Id; //External Id used for matching later
        newOpp.axnpsp__Payment_Transaction_External_ID__c = paymentTransaction.Id; //External Id used for matching later
        return newOpp;
    }
    
    public Opportunity_Line_Item__c createOpportunityLineItem(opportunity newOpp, axnpsp__Payment_Transaction__c paymentTransaction, axnpsp__AXSP_Swish_Admin__c swishAdmin, String contactId) {
        Opportunity_Line_Item__c oppLine = new Opportunity_Line_Item__c ();
        oppLine.Opportunity__r = new Opportunity(axnpsp__Payment_Transaction_External_ID__c = newOpp.axnpsp__Payment_Transaction_External_ID__c);
        oppLine.Amount__c = paymentTransaction.axnpsp__Swish_Amount__c;
        oppLine.Quantity__c = 1;
        oppLine.Type__c = swishAdmin?.axnpsp__Donation_Type__c;
        oppLine.Product__c = swishAdmin?.Product__c != null ? swishAdmin.Product__c : this.donationProduct?.Id;
        return oppLine;
    }

    public Contact createContact(axnpsp__Payment_Transaction__c paymentTransaction) {
        Contact newContact = new Contact();
        Map<String, String> nameMap = getName(paymentTransaction.axnpsp__Swish_Payer_Name__c);
        newContact.FirstName = nameMap.get('firstName') != null ? nameMap.get('firstName') : 'Swish';
        newContact.LastName = nameMap.get('lastName') != null ? nameMap.get('lastName') : 'Swish';
        newContact.Mobilephone = formatSwishPhoneNumber(paymentTransaction.axnpsp__Swish_Payer_mobile__c);   
        return newContact;
    }

    public Map<String, axnpsp__AXSP_Swish_Admin__c> createSwishAdminMap(List<axnpsp__AXSP_Swish_Admin__c> swishAdmins){
        
        Map<String, axnpsp__AXSP_Swish_Admin__c> swishAdminMap = new Map<String, axnpsp__AXSP_Swish_Admin__c>();
        for(axnpsp__AXSP_Swish_Admin__c swishAdmin: swishAdmins){
            String key = '';
            key += swishAdmin.axnpsp__Swish_Number__c;
            key += swishAdmin.axnpsp__Swish_Number_Reference__c != null ? swishAdmin.axnpsp__Swish_Number_Reference__c : '';
            swishAdminMap.put(key, swishAdmin);
        }
        return swishAdminMap;
    }


    public Map<String, String> getName(String payerName){
        Map<String, String> nameMap = new Map<String, String>{
            'firstName' => null,
            'lastname' => null
        };
        List<String> splitPayerName;        
        if(payerName.contains(',')){
            splitPayerName =  payerName.split(',');       
            nameMap.put('firstName', splitPayerName[1].trim());
            nameMap.put('lastName', splitPayerName[0].trim());
        }
        else {
            splitPayerName =  payerName.split(' ');
            if(splitPayerName.size() > 1){
                nameMap.put('firstName',  payerName.substring(0, payerName.indexOf(' ')).trim());
                nameMap.put('lastName', payerName.substring(payerName.indexOf(' ') + 1).trim());
            }   
            else {
                nameMap.put('lastName', splitPayerName[0].trim());
            }   
        }
        return nameMap;
    }



    public Set<String> formatSwishPhoneNumbers(List<axnpsp__Payment_Transaction__c> paymentTransactions){
        Set<String> formatedPhones = new Set<String>();
        for(axnpsp__Payment_Transaction__c paymentTransaction: paymentTransactions){
            String phoneNumber = paymentTransaction.axnpsp__Swish_Payer_mobile__c;
            String formatedPhoneNumber = PhoneValidatorUtil.generateFormatedPhoneNumber(phoneNumber);
            formatedPhones.add(formatedPhoneNumber);
            }
        return formatedPhones;
    }


    public String formatSwishPhoneNumber(String phoneNumber){
            String formatedPhoneNumber = PhoneValidatorUtil.generateFormatedPhoneNumber(phoneNumber);
            return formatedPhoneNumber;
    }

    private Product2 getDonationProduct(){
        List<Product2> product = [
            SELECT 
                Id
            FROM Product2 
            WHERE Name = 'Donation'
            LIMIT 1
        ];
        return product.isEmpty() ? null : product[0];
    }

    private List<npe01__OppPayment__c> getPayments(List<Opportunity> createdOpportunities) {
        return [
            SELECT 
                Id,
                npe01__Payment_Date__c,
                npe01__Paid__c,
                npe01__Check_Reference_Number__c,
                npe01__Opportunity__r.axnpsp__Payment_Reference_ID__c
            FROM npe01__OppPayment__c 
            WHERE npe01__Opportunity__c IN :createdOpportunities
        ];
    }

    public List<npe01__OppPayment__c> getPaymentsByReference(Set<String> swishReferences) {
        return [
            SELECT 
                Id,
                npe01__Payment_Date__c,
                npe01__Paid__c,
                npe01__Check_Reference_Number__c,
                npe01__Opportunity__r.npsp__Primary_Contact__c,
                npe01__Opportunity__r.npsp__Primary_Contact__r.FirstName,
                npe01__Opportunity__r.npsp__Primary_Contact__r.LastName
            FROM npe01__OppPayment__c
            WHERE npe01__Check_Reference_Number__c IN :swishReferences
        ];
    }

    public List<axnpsp__AXSP_Swish_Admin__c> getSwishAdmins(Set<String> swishNumbers, Set<String> swishReferences) {
        
        List<axnpsp__AXSP_Swish_Admin__c> swishAdmin = [
            SELECT 
                Id, 
                axnpsp__Swish_Number__c, 
                axnpsp__Swish_Number_Reference__c, 
                axnpsp__Campaign__c,  
                axnpsp__Donation_Type__c,
                Product__c
            FROM axnpsp__AXSP_Swish_Admin__c 
            WHERE axnpsp__Active__c = true 
            AND axnpsp__Swish_Number__c IN: swishNumbers  
            AND (
                axnpsp__Swish_Number_Reference__c IN :swishReferences
                OR axnpsp__Swish_Number_Reference__c = null
            )
        ];
        return swishAdmin;
    }

    private List<Contact> getContactsByMobilePhone(Set<String> phoneNumbers) {
        return [
            SELECT 
                Id, 
                MobilePhone, 
                FirstName, 
                LastName,
                CreatedDate
            FROM Contact 
            WHERE MobilePhone IN :phoneNumbers
            ORDER BY CreatedDate ASC
        ];
     }

}