@isTest
private class AccountControllerTest {
    
    @isTest
    static void testFindAccounts() {
        // Test data setup
        List<Account> accList = new List<Account>();
        accList.add(new Account(Name = 'Test Account 1', AccountNumber = 'A001'));
        accList.add(new Account(Name = 'Sample Account 2', AccountNumber = 'A002'));
        accList.add(new Account(Name = 'Another Account 3', AccountNumber = 'A003'));
        insert accList;
        
        Test.startTest();
        // Call the controller method
        List<Account> results = AccountController.findAccounts('Test');
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(0, results.size(), 'At least one account should be returned');
        System.assertEquals('Test Account 1', results[0].Name, 'Expected account name not found');
    }
    
    @isTest
    static void testFindAccounts_NoResults() {
        Test.startTest();
        List<Account> results = AccountController.findAccounts('DoesNotExist');
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'No accounts should be returned for a non-matching searchKey');
    }
}