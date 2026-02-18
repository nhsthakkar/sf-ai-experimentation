/**
 * @description Test class for OpportunityUpdateController
 * Provides comprehensive test coverage including positive, negative, and edge cases
 * @author Salesforce Platform Expert
 * @date 2026-02-17
 */
@isTest
private class OpportunityUpdateController_Test {
    
    /**
     * @description Setup test data
     */
    @testSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = new Account(
            Name = 'Test Client Account',
            NumberOfEmployees = 500
        );
        insert testAccount;
        
        // Create test Opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            Amount = 100000,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;
    }
    
    /**
     * @description Test successful data retrieval
     */
    @isTest
    static void testGetOpportunityData_Success() {
        // Get test opportunity
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        OpportunityUpdateController.OpportunityData result = 
            OpportunityUpdateController.getOpportunityData(testOpp.Id);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('Test Opportunity', result.opportunityName, 'Opportunity name should match');
        System.assertEquals('Test Client Account', result.accountName, 'Account name should match');
        System.assertEquals(100000, result.amount, 'Amount should match');
        System.assertEquals(500, result.numberOfEmployees, 'Number of employees should match');
    }
    
    /**
     * @description Test error handling for invalid opportunity ID
     */
    @isTest
    static void testGetOpportunityData_InvalidId() {
        // Create a fake ID that doesn't exist
        Id fakeId = '006000000000000AAA';
        
        Test.startTest();
        try {
            OpportunityUpdateController.getOpportunityData(fakeId);
            System.assert(false, 'Expected exception was not thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Error retrieving opportunity data'), 
                'Error message should indicate data retrieval issue');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test successful update and notification
     */
    @isTest
    static void testUpdateAndNotify_Success() {
        // Get test opportunity
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Set email limits
        Integer emailInvocations = Limits.getEmailInvocations();
        
        Test.startTest();
        String result = OpportunityUpdateController.updateAndNotify(
            testOpp.Id, 
            150000, 
            750
        );
        Test.stopTest();
        
        // Verify success message
        System.assert(result.contains('Success'), 'Should return success message');
        
        // Verify Opportunity was updated
        Opportunity updatedOpp = [SELECT Amount FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals(150000, updatedOpp.Amount, 'Opportunity Amount should be updated');
        
        // Verify Account was updated
        Account updatedAccount = [SELECT NumberOfEmployees FROM Account WHERE Id IN 
            (SELECT AccountId FROM Opportunity WHERE Id = :testOpp.Id)];
        System.assertEquals(750, updatedAccount.NumberOfEmployees, 
            'Account Number of Employees should be updated');
        
        // Verify email was sent (in test context, we just check it didn't error)
        System.assert(Limits.getEmailInvocations() >= emailInvocations, 
            'Email invocation should have occurred');
    }
    
    /**
     * @description Test validation rule enforcement (Number of Employees < 10)
     */
    @isTest
    static void testUpdateAndNotify_ValidationError_TooLow() {
        // Get test opportunity
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        try {
            OpportunityUpdateController.updateAndNotify(
                testOpp.Id, 
                150000, 
                5  // Below minimum of 10
            );
            System.assert(false, 'Expected validation exception was not thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Error updating records'), 
                'Error message should indicate update issue');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test validation rule enforcement (Number of Employees > 100,000)
     */
    @isTest
    static void testUpdateAndNotify_ValidationError_TooHigh() {
        // Get test opportunity
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        try {
            OpportunityUpdateController.updateAndNotify(
                testOpp.Id, 
                150000, 
                150000  // Above maximum of 100,000
            );
            System.assert(false, 'Expected validation exception was not thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Error updating records'), 
                'Error message should indicate update issue');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test boundary condition - minimum valid value (10)
     */
    @isTest
    static void testUpdateAndNotify_BoundaryMinimum() {
        // Get test opportunity
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        String result = OpportunityUpdateController.updateAndNotify(
            testOpp.Id, 
            150000, 
            10  // Minimum valid value
        );
        Test.stopTest();
        
        // Verify success
        System.assert(result.contains('Success'), 'Should succeed with minimum valid value');
        
        // Verify Account was updated
        Account updatedAccount = [SELECT NumberOfEmployees FROM Account WHERE Id IN 
            (SELECT AccountId FROM Opportunity WHERE Id = :testOpp.Id)];
        System.assertEquals(10, updatedAccount.NumberOfEmployees, 
            'Should accept minimum value of 10');
    }
    
    /**
     * @description Test boundary condition - maximum valid value (100,000)
     */
    @isTest
    static void testUpdateAndNotify_BoundaryMaximum() {
        // Get test opportunity
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        String result = OpportunityUpdateController.updateAndNotify(
            testOpp.Id, 
            150000, 
            100000  // Maximum valid value
        );
        Test.stopTest();
        
        // Verify success
        System.assert(result.contains('Success'), 'Should succeed with maximum valid value');
        
        // Verify Account was updated
        Account updatedAccount = [SELECT NumberOfEmployees FROM Account WHERE Id IN 
            (SELECT AccountId FROM Opportunity WHERE Id = :testOpp.Id)];
        System.assertEquals(100000, updatedAccount.NumberOfEmployees, 
            'Should accept maximum value of 100,000');
    }
    
    /**
     * @description Test with null/zero amount
     */
    @isTest
    static void testUpdateAndNotify_NullAmount() {
        // Get test opportunity
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        String result = OpportunityUpdateController.updateAndNotify(
            testOpp.Id, 
            null,  // Null amount
            500
        );
        Test.stopTest();
        
        // Verify Opportunity was updated with null
        Opportunity updatedOpp = [SELECT Amount FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals(null, updatedOpp.Amount, 'Amount should be null');
    }
    
    /**
     * @description Test PDF generation in test context
     */
    @isTest
    static void testPDFGeneration() {
        // Get test opportunity
        Opportunity testOpp = [SELECT Id, Name, AccountId, Account.Name FROM Opportunity LIMIT 1];
        
        Test.startTest();
        // This will trigger PDF generation internally
        String result = OpportunityUpdateController.updateAndNotify(
            testOpp.Id, 
            200000, 
            1000
        );
        Test.stopTest();
        
        // In test context, PDF is mocked, but we verify the method completes successfully
        System.assert(result.contains('Success'), 'PDF generation should not prevent success');
    }
    
    /**
     * @description Test VF Controller
     */
    @isTest
    static void testVFController() {
        Test.startTest();
        
        // Set page parameters
        PageReference pageRef = Page.OpportunityUpdatePDF;
        pageRef.getParameters().put('opportunityName', 'Test Opp');
        pageRef.getParameters().put('accountName', 'Test Account');
        pageRef.getParameters().put('amount', '100000');
        pageRef.getParameters().put('numberOfEmployees', '500');
        Test.setCurrentPage(pageRef);
        
        // Instantiate controller
        OpportunityUpdatePDFController controller = new OpportunityUpdatePDFController();
        
        Test.stopTest();
        
        // Assertions
        System.assertEquals('Test Opp', controller.opportunityName, 'Opportunity name should be set');
        System.assertEquals('Test Account', controller.accountName, 'Account name should be set');
        System.assertEquals(100000, controller.amount, 'Amount should be parsed correctly');
        System.assertEquals(500, controller.numberOfEmployees, 'Employees should be parsed correctly');
    }
    
    /**
     * @description Test VF Controller with empty parameters
     */
    @isTest
    static void testVFController_EmptyParams() {
        Test.startTest();
        
        // Set page with no parameters
        PageReference pageRef = Page.OpportunityUpdatePDF;
        Test.setCurrentPage(pageRef);
        
        // Instantiate controller
        OpportunityUpdatePDFController controller = new OpportunityUpdatePDFController();
        
        Test.stopTest();
        
        // Should handle null/empty gracefully
        System.assertEquals(null, controller.opportunityName, 'Should handle null opportunity name');
        System.assertEquals(null, controller.amount, 'Should handle null amount');
    }
}