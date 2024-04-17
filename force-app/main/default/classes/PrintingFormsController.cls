public with sharing class PrintingFormsController {

    private final Account acc;
    private List<AffiliationWrapper> affiliations;

    public PrintingFormsController(ApexPages.StandardController stdController) {
        this.acc = (Account) stdController.getRecord();
        this.queryAffiliations();
    }

    public void queryAffiliations(){
        List<npe5__Affiliation__c> affiliations = [SELECT Name, XC_Adress__c, npe5__Contact__r.Name, npe5__Contact__r.Foretagsnamn__c, XC_Jobbtelefon__c, XC_Hemtelefon__c, XC_Mobil__c, XC_E_post__c, XC_Medlemskategorier__c, XC_Fodelsear__c, XC_Yrke__c FROM npe5__Affiliation__c WHERE npe5__Organization__c = :this.acc.Id AND npe5__Status__c = 'Current'];
        List<AffiliationWrapper> wrappers = new List<AffiliationWrapper>();
        for (npe5__Affiliation__c aff : affiliations) {
            wrappers.add(new AffiliationWrapper(aff));
        }
        wrappers.sort();
        this.affiliations = wrappers;
    }

    public List<String> getHeaders(){
        return new List<String> { 'Name and Address', 'Telefon', 'Email', 'Medlemskategori', 'Födelseår', 'Yrke'};
    }

    public List<AffiliationWrapper> getAffiliations() {
        return this.affiliations;
    }

    public String getYear() {
        return String.valueOf(Date.today().year());
    }

    public String getLfNamePretty() {
        Account accc = [SELECT XC_LF_Nummer2__c, Name FROM Account WHERE Id = :this.acc.Id];
        return accc.XC_LF_Nummer2__c + ' - ' + accc.Name;
    }

    public class AffiliationWrapper implements Comparable {
        public String affName { get; set; }
        public String address { get; set; }
        public String contactName { get; set; }
        public String companyName { get; set; }
        public String jobbTelefon { get; set; }
        public String hemTelefon { get; set; }
        public String mobil { get; set; }
        public String phones { get; set; }
        public String epost { get; set; }
        public String medlemsKategorier { get; set; }
        public String fodelsear { get; set; }
        public String yrke { get; set; }
        public String nameAndAddress { get; set; }

        public AffiliationWrapper (npe5__Affiliation__c aff) {
            this.affName = aff.Name;
            this.address = aff.XC_Adress__c.substring(0, aff.XC_Adress__c.lastIndexOf('<br>'));
            this.contactName = aff.npe5__Contact__r.Name;
            this.companyName = aff.npe5__Contact__r.Foretagsnamn__c;
            this.jobbTelefon = aff.XC_Jobbtelefon__c;
            this.hemTelefon = aff.XC_Hemtelefon__c;
            this.mobil = aff.XC_Mobil__c;
            this.epost = getEmail(aff.XC_E_post__c);
            List<String> categories = String.isEmpty(aff.XC_Medlemskategorier__c) ? new List<String>() : aff.XC_Medlemskategorier__c.split(';');
            this.medlemsKategorier = categories.isEmpty() ? '' : String.join(categories, '\n');
            this.fodelsear = aff.XC_Fodelsear__c == null ? '' : String.valueOf(aff.XC_Fodelsear__c);
            this.yrke = aff.XC_Yrke__c;
            this.phones = String.format('{0}: {1}<br>{2}: {3}<br>{4}: {5}',
                    new List<String> {
                            'JobbTelefon',
                            this.jobbTelefon,
                            'HemTelefon',
                            this.hemTelefon,
                            'Mobil',
                            this.mobil
                    });
            System.debug('AAAAAAADRES ' + this.address);
            this.nameAndAddress = 'Name: ' + this.affName + '<br/>' + this.address;
        }

        public Integer compareTo(Object compared) {
            AffiliationWrapper wrapper = (AffiliationWrapper) compared;
            Integer firstLetterThis = this.medlemsKategorier.length() == 0 ? null : this.medlemsKategorier.toUpperCase().charAt(0);
            Integer firstLetterCompared = wrapper.medlemsKategorier.length() == 0 ? null : wrapper.medlemsKategorier.toUpperCase().charAt(0);
            if (firstLetterThis == firstLetterCompared) {
                return 0;
            } else if (firstLetterThis == null && firstLetterCompared != null) {
                return 1;
            } else if (firstLetterThis != null && firstLetterCompared == null) {
                return -1;
            } else {
                return firstLetterThis < firstLetterCompared ? -1 : 1;
            }
        }

        private String getEmail(String emailInput) {
            if (emailInput == null || emailInput.length() == 0) {
                return emailInput;
            }
            Integer emailLength = emailInput.length();
            if (emailLength > 40) {
                String resultEmail = emailInput.substring(0, 40) + '<br/>' + emailInput.substring(40, emailLength);
                return resultEmail;
            }
            return emailInput;
        }

    }

}