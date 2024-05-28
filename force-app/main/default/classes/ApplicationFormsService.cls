public inherited sharing class ApplicationFormsService {

    private static final String STATUS_TEMPORARY = 'Temporary';
    private static final String STATUS_NEW = 'New';
    private static final String STATUS_READY_FOR_DECISION = 'Ready for Decision';
    private static final String STATUS_APPROVED = 'Approved';
    private static final String STATUS_REJECTED = 'Rejected';
    private static final String LF_STATUS_ACTIVE = 'Aktiv';
    private static final String MEMBER_STATUS_CURRENT = 'Current';
    private static final String ACCOUNT_RIKS = 'RIKS';
    private static final String ADDED_BY_CERTIFIER = 'Certifier';


    private static final Set<String> excludedStatuses = new Set<String>{
            STATUS_TEMPORARY, STATUS_NEW, STATUS_APPROVED, STATUS_REJECTED
    };

    private static final String TEMP_APP_RT = 'Temp';

    public static Application__c getApplication(String formId) {
        return [
                SELECT
                        Id,
                        Name,
                        XC_Vardnadshavare__c,
                        XC_Vardnadshavare1__c,
                        XC_BorVardnadshavareTillsammans__c,
                        XC_IntygsskrivarensNamn__c,
                        XC_IntygsskrivarensEpost__c,
                        XC_IntygsskrivarensTelefonnummer__c,
                        XC_Bostadsadress__c,
                        XC_C_O_Adress__c,
                        XC_Lagenhetsnummer__c,
                        XC_Postnummer__c,
                        XC_Ort__c,
                        XC_Barnbidrag_kr__c,
                        XC_Underhall_kr__c,
                        XC_Bostadsbidrag_kr__c,
                        XC_Lon_kr__c,
                        XC_Foraldrapenning_kr__c,
                        XC_Omvardnadsbidrag_kr__c,
                        XC_Sjukpenning_kr__c,
                        XC_Forsorjningsstod_kr__c,
                        XC_Studiebidrag_kr__c,
                        XC_A_kassa_kr__c,
                        XC_Ovrigt_kr__c,
                        XC_Totalsumma_kr__c,
                        XC_RequestedAmount__c,
                        XC_Request__c,
                        XC_BankensNamn__c,
                        XC_Clearingnummer__c,
                        XC_Kontonummer__c,
                        XC_Kontoinnehavarens__c,
                        XC_IntygsskrivarensInfo__c,
                        XC_SiblingsAge__c,
                        XC_Epost__c,
                        XC_Telefonnummer__c,
                        XC_YrkeRoll__c,
                        XC_ArbetsplatsForening__c,
                        XC_ApprovedByCertifier__c,
                        XC_CertifierRejectionInfo__c,
                        XC_Status__c,
                        (SELECT
                                Id,
                                Name,
                                XC_Fornamn__c,
                                XC_Efternamn__c,
                                XC_Fodelsear__c,
                                XC_Personnummer__c
                        FROM Barnen__r),
                        (SELECT
                                Id,
                                Name,
                                Barnet_ApplicationEntry__c,
                                Barnet_ApplicationEntry__r.XC_Fornamn__c,
                                Barnet_ApplicationEntry__r.XC_Efternamn__c,
                                Kategori__c,
                                Underkategori__c,
                                Beviljat_V_rde_Presentkort_Kontanter__c,
                                Ans_kt_V_rde_Kontanter_Presentkort__c,
                                Kontanter_Presentkort__c,
                                Annat_Beskrivning__c
                        FROM Bidragsrader__r)
                FROM Application__c
                WHERE XC_FormId__c = :formId OR Id = :formId
        ];
    }

    public static String apply(Application__c application, List<XC_ApplicationEntryChild__c> children) {
        String formId = [SELECT Name FROM Application__c WHERE Id = :application.Id].Name;
        application.XC_LinkValidDate__c = Date.today().addDays(7);
        application.XC_Status__c = STATUS_NEW;
        application.XC_FormId__c = formId;
        update application;
        for (XC_ApplicationEntryChild__c child : children) {
            child.XC_Application__c = application.Id;
        }
        insert children;
        return application.XC_FormId__c;
    }

    public static String createApplication(Application__c application, List<Map<String, Object>> children, List<Map<String, Object>> requests) {
        String formId = [SELECT Name FROM Application__c WHERE Id = :application.Id].Name;
        application.XC_LinkValidDate__c = Date.today().addDays(7);
        application.XC_Status__c = STATUS_NEW;
        application.XC_FormId__c = formId;
        update application;

        Map<Integer, XC_ApplicationEntryChild__c> childrenToInsert = new Map<Integer, XC_ApplicationEntryChild__c>();
        for (Map<String, Object> child : children) {
            System.debug('CHILD: ' + JSON.serializePretty(child));
            XC_ApplicationEntryChild__c childToInsert = new XC_ApplicationEntryChild__c();
            childToInsert.XC_Application__c = application.Id;
            childToInsert.XC_Fornamn__c = (String) child.get('firstName');
            childToInsert.XC_Efternamn__c = (String) child.get('lastName');
            childToInsert.XC_Fodelsear__c = (String) child.get('year');
            childToInsert.XC_Personnummer__c = (String) child.get('ssn');
            childrenToInsert.put(Integer.valueOf(child.get('id')), childToInsert);
        }
        insert childrenToInsert.values();

        List<Bidragsrader__c> requestsToInsert = new List<Bidragsrader__c>();
        for (Map<String, Object> request : requests) {
            System.debug('REQUEST: ' + JSON.serializePretty(request));
            Bidragsrader__c requestToInsert = new Bidragsrader__c();
            requestToInsert.Application__c = application.Id;
            requestToInsert.Kategori__c = (String) request.get('category');
            requestToInsert.Underkategori__c = (String) request.get('subcategory');
            requestToInsert.Ans_kt_V_rde_Kontanter_Presentkort__c = (Decimal) request.get('amount');
            requestToInsert.Annat_Beskrivning__c = (String) request.get('description');
            if (request.get('child') != null) {
                Object val = request.get('child');
                System.debug('CHILD: ' + request.get('child'));
                XC_ApplicationEntryChild__c child = childrenToInsert.get(Integer.valueOf(request.get('child')));
                requestToInsert.Barnet_ApplicationEntry__c = child?.Id;
            }
            System.debug('OBJ=' + requestToInsert);
            requestsToInsert.add(requestToInsert);
        }
        insert requestsToInsert;
        return application.XC_FormId__c;
    }

    public static void updateApplication(Application__c form) {
        update form;
    }

    public static void updateApplicationsBulk(List<Application__c> forms) {
        update forms;
        System.debug('*** Updated applications:' + forms);
    }

    public static Id createTemporary() {
        Application__c app = new Application__c(
                XC_Status__c = STATUS_TEMPORARY,
                RecordTypeId = Schema.SObjectType.Application__c.getRecordTypeInfosByDeveloperName().get(TEMP_APP_RT).getRecordTypeId()
        );
        insert app;

        return app.Id;
    }

    public static List<XC_Kommun__c> getKommuns() {
        return [SELECT Name, XC_Lan__c FROM XC_Kommun__c ORDER BY Name];
    }

    public static List<Account> getLfs(String kommun) {
        Id defaultId = [SELECT XC_DefaultLF__c FROM XC_Kommun__c WHERE Name = :kommun].XC_DefaultLF__c;
        List<Account> accs = [
                SELECT
                        XC_CertifierRequired__c,
                        XC_CurrentApplicationDate__c,
                        XC_NextApplicationDate__c,
                        XC_NextApplicationDate1__c,
                        XC_NextApplicationDate2__c,
                        L_pande_ans_kningsdatum__c,
                        Name FROM Account
                WHERE (XC_Kommun__r.Name = :kommun OR Id = :defaultId)
                AND LF_Status__c = :LF_STATUS_ACTIVE];

        return accs.isEmpty()
                ? [
                        SELECT
                                XC_CertifierRequired__c,
                                XC_CurrentApplicationDate__c,
                                XC_NextApplicationDate__c,
                                L_pande_ans_kningsdatum__c,
                                Name
                        FROM
                                Account
                        WHERE
                                Name = :ACCOUNT_RIKS]
                : accs;
    }

    public static List<Contact> getApplicationContacts(String applicationId) {
        Id lfID = [SELECT XC_LF__c FROM Application__c WHERE Id = :applicationId].XC_LF__c; 
        List<npe5__Affiliation__c> affiliations = [
                SELECT
                        npe5__Contact__r.Name,
                        npe5__Contact__r.Id
                FROM
                        npe5__Affiliation__c
                WHERE
                        npe5__Organization__c = :lfID
                AND
                        npe5__Status__c = :MEMBER_STATUS_CURRENT];
        Set<Contact> contacts = new Set<Contact>();
        for (npe5__Affiliation__c aff : affiliations) {
            contacts.add(aff.npe5__Contact__r);
        }
        return new List<Contact> (contacts);
    }

    //** Get current users Approvers*/
    public static List<Contact> getApproversForCurrentUser() {
        User currentUser = [SELECT Contact.AccountId, Contact.Account.Name FROM User WHERE Id = :UserInfo.getUserId()];
        List<npe5__Affiliation__c> affiliations = [
                SELECT
                        npe5__Contact__r.Name,
                        npe5__Contact__r.Id
                FROM
                        npe5__Affiliation__c
                WHERE
                        npe5__Organization__c = :currentUser.Contact.AccountId
                AND
                        npe5__Status__c = :MEMBER_STATUS_CURRENT];
        Set<Contact> contacts = new Set<Contact>();
        for (npe5__Affiliation__c aff : affiliations) {
            contacts.add(aff.npe5__Contact__r);
        }
        return new List<Contact> (contacts);
    }

    public static List<Application__c> getLatestApplications(Id appId, Integer monthsOld) {
        Application__c app = [
            SELECT
                Id,
                XC_FormId__c,
                (
                    SELECT XC_Personnummer__c
                    FROM Barnen__r
                    WHERE XC_Personnummer__c != NULL
                )
            FROM
                Application__c
            WHERE
                Id = :appId];

        Set<String> childrenSSN = new Set<String>();
        for (XC_ApplicationEntryChild__c child : app.Barnen__r) {
            childrenSSN.add(child.XC_Personnummer__c);
        }

        List<XC_ApplicationEntryChild__c> children = new List<XC_ApplicationEntryChild__c>([
            SELECT
                XC_Application__c
            FROM
                XC_ApplicationEntryChild__c
            WHERE
                XC_Personnummer__c IN :childrenSSN]);

        Set<Id> applications = new Set<Id>();
        for (XC_ApplicationEntryChild__c child : children) {
            applications.add(child.XC_Application__c);
        }
        applications.remove(appId);

        Date lastMonthsDate = Date.today().addMonths(-monthsOld);
        List<Application__c> apps = new List<Application__c>([
            SELECT
                Id,
                Name,
                XC_Vardnadshavare__c,
                XC_Vardnadshavare1__c,
                (SELECT
                    Id,
                    Name,
                    XC_Fornamn__c,
                    XC_Efternamn__c,
                    XC_Fodelsear__c,
                    XC_Personnummer__c
                FROM Barnen__r),
                (SELECT
                    Id,
                    Name,
                    Barnet_ApplicationEntry__c,
                    Kategori__c,
                    Underkategori__c,
                    Beviljat_V_rde_Presentkort_Kontanter__c,
                    Ans_kt_V_rde_Kontanter_Presentkort__c,
                    Kontanter_Presentkort__c,
                    Annat_Beskrivning__c
                FROM Bidragsrader__r)
            FROM Application__c
            WHERE Id IN :applications
            AND XC_Status__c = :STATUS_APPROVED
            AND CreatedDate >= :lastMonthsDate]);

        return apps;
    }

    public static List<Application__c> getAllApplications() {
        User currentUser = [SELECT Contact.AccountId, Contact.Account.Name FROM User WHERE Id = :UserInfo.getUserId()];
        System.debug('*** Info: ' + currentUser.Contact.AccountId + ' ' + currentUser.Contact.Account.Name + ' ***');
        List<Application__c> applications = new List<Application__c>([
            SELECT
                Id,
                Name,
                XC_Status__c,
                XC_Vardnadshavare__c,
                XC_Vardnadshavare1__c,
                XC_Approver1__c,
                XC_Approver2__c,
                (SELECT
                    Id,
                    Name,
                    XC_Fornamn__c,
                    XC_Efternamn__c,
                    XC_Fodelsear__c,
                    XC_Personnummer__c,
                    XC_Application__c
                FROM Barnen__r),
                (SELECT
                    Id,
                    Name,
                    Barnet_ApplicationEntry__c,
                    Kategori__c,
                    Underkategori__c,
                    Beviljat_V_rde_Presentkort_Kontanter__c,
                    Ans_kt_V_rde_Kontanter_Presentkort__c,
                    Kontanter_Presentkort__c,
                    Annat_Beskrivning__c,
                    Application__c
                FROM Bidragsrader__r)
            FROM Application__c
            WHERE
                XC_LF__c = :currentUser.Contact.AccountId AND
                XC_Status__c = :STATUS_READY_FOR_DECISION]);
        return applications;
    }

    public static List<Application__c> getDuplicated(Id appId) {
        Application__c app = [
                SELECT
                        Id,
                        XC_FormId__c,
                        (SELECT XC_Personnummer__c FROM Barnen__r WHERE XC_Personnummer__c != NULL)
                FROM
                        Application__c
                WHERE
                        Id = :appId];

        Set<String> childrensPersonNummers = new Set<String>();
        Set<String> childrensIds = new Set<String>();
        for (XC_ApplicationEntryChild__c child : app.Barnen__r) {
            childrensPersonNummers.add(child.XC_Personnummer__c);
            childrensIds.add(child.Id);
        }

        List<XC_ApplicationEntryChild__c> children = [
                SELECT
                        XC_Application__c
                FROM
                        XC_ApplicationEntryChild__c
                WHERE
                        XC_Personnummer__c IN :childrensPersonNummers AND Id NOT IN :childrensIds];
        Set<Id> applications = new Set<Id>();
        for (XC_ApplicationEntryChild__c child : children) {
            applications.add(child.XC_Application__c);
        }
        applications.addAll(getDuplicatedFromDuplicateRules(appId));
        return [SELECT Id, XC_FormId__c FROM Application__c WHERE Id IN :applications];
    }

    private static Set<Id> getDuplicatedFromDuplicateRules(Id appId) {
        try {
            List<Datacloud.FindDuplicatesResult> l = Datacloud.FindDuplicatesByIds.findDuplicatesByIds(new List<Id> {appId});
            Set<Id> ids = new Set<Id> ();
            if (l.isEmpty()) {
                return ids;
            }

            for (Datacloud.MatchRecord res : l[0].getDuplicateResults()[0].getMatchResults()[0].getMatchRecords()) {
                ids.add(((Application__c) res.getRecord()).Id);
            }

            for (Datacloud.DuplicateResult res : l[0].getDuplicateResults()) {
                for (Datacloud.MatchResult matchRes : res.getMatchResults()) {
                    for (Datacloud.MatchRecord matchRec : matchRes.getMatchRecords()) {
                        ids.add(((Application__c) matchRec.getRecord()).Id);
                    }
                }
            }
            return ids;
        } catch (Exception e) {
            return new Set<Id> ();
        }

    }

    public static Id getCurrentUserAccountId() {
        Id accId = [SELECT AccountId FROM User WHERE Id = :UserInfo.getUserId()].AccountId;
        if (accId == null) {
            throw new NullPointerException();
        }
        return accId;
    }

    public static List<PicklistEntryWrapper> getApplicationStatuses() {
        List<PicklistEntryWrapper> pickListValuesList = new List<PicklistEntryWrapper>();
        Schema.DescribeFieldResult fieldResult = Application__c.XC_Status__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry pickListVal : ple) {
            if (!excludedStatuses.contains(pickListVal.getValue())) {
                pickListValuesList.add(new PicklistEntryWrapper(pickListVal));
            }
        }
        return pickListValuesList;
    }

    public static Application__c getApplicationBySfId(String appId) {
        return [SELECT XC_Status__c, XC_Hanteras_av__r.Id, XC_Hanteras_av__r.Name FROM Application__c WHERE Id = :appId];
    }

    public static List<PicklistEntryWrapper> getRejectionReasons() {
        List<PicklistEntryWrapper> pickListValuesList = new List<PicklistEntryWrapper>();
        Schema.DescribeFieldResult fieldResult = Application__c.XC_CertifierRejectionReason__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry pickListVal : ple) {
            pickListValuesList.add(new PicklistEntryWrapper(pickListVal));
        }
        return pickListValuesList;
    }

    public static Boolean checkLinkValidity(String formId) {
        Application__c app = [SELECT XC_UpdatedByCertifier__c, XC_LinkValidDate__c FROM Application__c WHERE XC_FormId__c = :formId LIMIT 1];
        if (app.XC_LinkValidDate__c == null) {
            return false;
        }
        return !app.XC_UpdatedByCertifier__c && Date.today().daysBetween(app.XC_LinkValidDate__c) >= 0;
    }

    public static Account getPreselectedLf(String lfNumber) {
        Decimal lfNum = Decimal.valueOf(lfNumber);
        Account lf = [
                SELECT
                        XC_CertifierRequired__c,
                        XC_CurrentApplicationDate__c,
                        XC_NextApplicationDate__c,
                        Name
                FROM
                        Account
                WHERE
                        XC_LF_Nummer2__c = :lfNum
                LIMIT 1];
        return lf;
    }

    private static List<Schema.FieldSetMember> getFields() {
        return SObjectType.Application__c.fieldSets.Application_Form_Fieldst.getFields();
    }

    public static Application__c initEmptyApp() {
        Map<DisplayType, Object> typeToDefaultValue = new Map<DisplayType, Object> {
                Schema.DisplayType.CURRENCY => null,
                Schema.DisplayType.TEXTAREA => '',
                Schema.DisplayType.DATE => null,
                Schema.DisplayType.STRING => '',
                Schema.DisplayType.EMAIL => '',
                Schema.DisplayType.PHONE => '',
                Schema.DisplayType.ID => '',
                Schema.DisplayType.PICKLIST => '',
                Schema.DisplayType.BOOLEAN => false

        };
        Application__c app = new Application__c();
        Set<DisplayType> tpyes = new Set<DisplayType>();
        for (Schema.FieldSetMember member : getFields()) {
            tpyes.add(member.getType());
            app.put(member.getFieldPath(), typeToDefaultValue.get(member.getType()));
        }
        return app;
    }

    public static void removeOldFiles(String formId) {
        List<ContentVersion> relatedFiles = [SELECT ContentDocumentId FROM ContentVersion WHERE XC_Form_fileupload__c = :formId AND XC_AddedBy__c = :ADDED_BY_CERTIFIER];
        if (relatedFiles.isEmpty()) {
            return;
        }
        Set<ContentDocument> contentDocuments = new Set<ContentDocument> ();
        for (ContentVersion cv : relatedFiles) {
            contentDocuments.add(new ContentDocument(Id = cv.ContentDocumentId));
        }
        delete new List<ContentDocument> (contentDocuments);
    }

    public static Map<Object,List<String>> getDependentPicklistValues( Schema.sObjectField dependToken )
    {
        Schema.DescribeFieldResult depend = dependToken.getDescribe();
        Schema.SObjectField controlToken = depend.getController();
        if ( controlToken == null ) return null;
        Schema.DescribeFieldResult control = controlToken.getDescribe();
        List<Schema.PicklistEntry> controlEntries =
            (   control.getType() == Schema.DisplayType.Boolean
                ?   null
                :   control.getPicklistValues()
            );

        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        Map<Object,List<String>> dependentPicklistValues = new Map<Object,List<String>>();
        for ( Schema.PicklistEntry entry : depend.getPicklistValues() ) {
            if ( entry.isActive() ) {
                List<String> base64chars =
                    String.valueOf
                        (   ((Map<String,Object>) JSON.deserializeUntyped( JSON.serialize( entry ) )).get( 'validFor' )
                        ).split( '' );
                for ( Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++ ) {
                    Object controlValue =
                        (   controlEntries == null
                            ?   (Object) (index == 1)
                            :   (Object) (controlEntries[ index ].isActive() ? controlEntries[ index ].getLabel() : null)
                        );
                    Integer bitIndex = index / 6, bitShift = 5 - Math.mod( index, 6 );
                    if (   controlValue == null
                        ||  (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)) == 0
                    ) {
                        continue;
                    }
                    if ( !dependentPicklistValues.containsKey( controlValue ) )
                    {
                        dependentPicklistValues.put( controlValue, new List<String>() );
                    }
                    dependentPicklistValues.get( controlValue ).add( entry.getLabel() );
                }
            }
        }
        return dependentPicklistValues;
    }

    public static List<PicklistValue> getPicklistHierarchy() {
        List<PicklistValue> hierarchy = new List<PicklistValue>();

        // Retrieve picklist values for Kategori__c and Underkategori__c fields
        Schema.DescribeFieldResult categoryField = Schema.SObjectType.Bidragsrader__c.fields.Kategori__c.getSobjectField().getDescribe();
        Schema.DescribeFieldResult subcategoryField = Schema.SObjectType.Bidragsrader__c.fields.Underkategori__c.getSobjectField().getDescribe();

        Map<Object,List<String>> dependValuesByControlValue = getDependentPicklistValues( Bidragsrader__c.Underkategori__c );

        System.debug(dependValuesByControlValue);

        // Loop through the dependValuesByControlValue and print the result
        for (Object controlValue : dependValuesByControlValue.keySet()) {
            PicklistValue grp = new PicklistValue(String.valueOf(controlValue));
            List<String> dependentValues = dependValuesByControlValue.get(controlValue);
            List<PicklistValue> subcategories = grp.options;
            for (String dependentValue : dependentValues) {
                subcategories.add(new PicklistValue(dependentValue, dependentValue));
            }
            hierarchy.add(grp);
            System.debug('*** Control value: ' + controlValue + ' ***');
            System.debug('*** Dependent values: ' + dependentValues + ' ***');
        }

        // Retrieve picklist values for Kategori__c field
        return hierarchy;
    }

    public class PicklistValue {
        @AuraEnabled public String label;
        @AuraEnabled public String text;
        @AuraEnabled public String value;
        @AuraEnabled public List<PicklistValue> options;

        public PicklistValue(String label) {
            this.label = label;
            this.options = new List<PicklistValue>();
        }

        public PicklistValue(String text, String value) {
            this.text = text;
            this.value = value;
        }
    }

    public class PicklistEntryWrapper {
        @AuraEnabled public String value { get; set; }
        @AuraEnabled public String label { get; set; }

        public PicklistEntryWrapper(Schema.PicklistEntry ple) {
            this.value = ple.getValue();
            this.label = ple.getLabel();
        }
    }

}