@isTest
public class LeadTriggerHandlerTest {

    @testSetup
    static void setupData() {
        // Create sample leads for testing
        Lead lead1 = new Lead(FirstName='Test', LastName='Lead1', Company='Test Company', Title='vp', 
                                LeadSource='Website', Email='test1@example.com', Phone='1234567890', Industry='Technology');
        Lead lead2 = new Lead(FirstName='Test', LastName='Lead2', Company='Test Company', Title='mgr', 
                                LeadSource='Website', Email='test2@example.com');
        insert new List<Lead>{lead1, lead2};
    }

    @isTest
    static void leadTriggerHandler_HandleTitleNormalization() {
        List<Lead> leads = [SELECT Id, Title FROM Lead WHERE Title IN ('vp', 'mgr')];
        
        Test.startTest();
        LeadTriggerHandler.handleTitleNormalization(leads);
        Test.stopTest();
        
        // Assert that titles have been normalized
        for (Lead ld : leads) {
            if (ld.Title == 'vp') {
                System.assertEquals('Vice President', ld.Title);
            } else if (ld.Title == 'mgr') {
                System.assertEquals('Manager', ld.Title);
            }
        }
    }

    @isTest
    static void leadTriggerHandler_HandleAutoLeadScoring() {
        // Retrieve the necessary fields: LeadSource, Phone, Industry, Email
        List<Lead> leads = [SELECT Id, LeadSource, Phone, Industry, Email, Lead_Score__c FROM Lead];
        
        Test.startTest();
        LeadTriggerHandler.handleAutoLeadScoring(leads);
        Test.stopTest();
        
        // Assert lead scores
        for (Lead ld : leads) {
            if (ld.Email != null && ld.Industry == 'Technology') {
                System.assertEquals(18, ld.Lead_Score__c);
            } else if (ld.Phone != null) {
                System.assert(ld.Lead_Score__c > 0);
            }
        }
    }
    

    @isTest
    static void leadTriggerHandler_HandleLeadAutoConvert() {
        // Create an Account for the Contact
        Account account = new Account(Name = 'Test Account');
        insert account;
    
        // Create a Contact associated with the Account
        Contact contact = new Contact(FirstName = 'Convert', LastName = 'Test', Email = 'convert@example.com', AccountId = account.Id);
        insert contact;
    
        // Create a Lead with the same email as the Contact, ensuring it is not converted
        Lead lead = new Lead(FirstName = 'Convert', LastName = 'Test', Company = 'Test Company', Email = 'convert@example.com', Phone = '9876543210', IsConverted = false);
        insert lead;
    
        Test.startTest();
        LeadTriggerHandler.handleLeadAutoConvert(new List<Lead>{lead});
        Test.stopTest();
    
        // Query the lead to verify it was converted
        Lead convertedLead = [SELECT IsConverted FROM Lead WHERE Id = :lead.Id];
        System.assertEquals(true, convertedLead.IsConverted, 'Lead should be converted.');
    }    
}    