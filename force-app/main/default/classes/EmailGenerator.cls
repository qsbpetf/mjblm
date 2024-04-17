public inherited sharing class EmailGenerator {
    private Messaging.SingleEmailMessage emailTobeSent;
    private EmailTemplate template;
    private Map<String, String> replacements;
    private List<String> recipients;

    public static EmailGenerator getNew() {
        return new EmailGenerator();
    }

    public EmailGenerator() {
        this.emailTobeSent = new Messaging.SingleEmailMessage();
        this.recipients = new List<String>();
        this.replacements = new Map<String, String>();
    }

    public EmailGenerator usingTemplate(EmailTemplate template) {
        this.template = template;
        return this;
    }

    public EmailGenerator addRecipient(String email) {
        this.recipients.add(email);
        return this;
    }

    public EmailGenerator replace(Map<String, String> replacements) {
        this.replacements = replacements;
        return this;
    }

    public EmailGenerator usingOrgWideAddress(OrgWideEmailAddress address) {
        this.emailTobeSent.setOrgWideEmailAddressId(address.Id);
        return this;
    }

    public Messaging.SingleEmailMessage getEmail() {
        this.emailTobeSent.setToAddresses(this.recipients);
        String html = this.template.HtmlValue;
        String subject = this.template.Subject;
        if (!this.replacements.isEmpty()) {
            for (String key : this.replacements.keySet()) {
                String val = this.replacements.get(key);
                html = html.replace(key, val == null ? 'N/A' : val);
                subject = subject.replace(key, val == null ? 'N/A' : val);
            }
        }

        System.debug('what is subject? ' + this.emailTobeSent.getSubject());
        this.emailTobeSent.setHtmlBody(html);
        this.emailTobeSent.setSubject(subject);
        this.emailTobeSent.setSaveAsActivity(false);
        return this.emailTobeSent;
    }

}