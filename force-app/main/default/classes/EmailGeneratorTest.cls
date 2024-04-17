@IsTest
public with sharing class EmailGeneratorTest {

    @IsTest
    static void testEmailGenerator() {
        EmailTemplate template = new EmailTemplate(
                HtmlValue = 'test onetwothree test',
                Subject = 'test'
        );
        OrgWideEmailAddress address = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
        Messaging.SingleEmailMessage mail = EmailGenerator.getNew()
                .usingTemplate(template)
                .addRecipient('test@test.se')
                .replace(new Map<String, String> { 'onetwothree' => 'test' })
                .usingOrgWideAddress(address)
                .getEmail();
        Assert.areEqual('test test test', mail.getHtmlBody());
    }
}