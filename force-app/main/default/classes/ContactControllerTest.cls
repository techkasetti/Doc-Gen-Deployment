@isTest
private class ContactControllerTest {
    
    @testSetup
    static void setupData() {
        // Create a test Account (Contacts need an AccountId)
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create sample Contacts
        List<Contact> conList = new List<Contact>();
        conList.add(new Contact(FirstName = 'John', LastName = 'Doe', Title = 'Manager', Phone = '1234567890', Email = 'john.doe@test.com', AccountId = acc.Id));
        conList.add(new Contact(FirstName = 'Jane', LastName = 'Smith', Title = 'Developer', Phone = '9876543210', Email = 'jane.smith@test.com', AccountId = acc.Id));
        conList.add(new Contact(FirstName = 'Test', LastName = 'User', Title = 'Tester', Phone = '5555555555', Email = 'test.user@test.com', AccountId = acc.Id));
        insert conList;
    }
    
    @isTest
    static void testGetContactList() {
        Test.startTest();
        List<Contact> results = ContactController.getContactList();
        Test.stopTest();
        
        System.assertNotEquals(0, results.size(), 'Expected at least one contact');
        System.assert(results.size() <= 10, 'Should return at most 10 contacts');
    }
    
    @isTest
    static void testFindContacts_Positive() {
        Test.startTest();
        List<Contact> results = ContactController.findContacts('John');
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one matching contact');
        System.assertEquals('John Doe', results[0].Name, 'Contact name should match expected');
    }
    
    @isTest
    static void testFindContacts_NoResults() {
        Test.startTest();
        List<Contact> results = ContactController.findContacts('NotExist');
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'No contacts should be returned for a non-matching searchKey');
    }
    
    @isTest
    static void testGetSingleContact() {
        Test.startTest();
        Contact c = ContactController.getSingleContact();
        Test.stopTest();
        
        System.assertNotEquals(null, c, 'Expected a contact record');
        System.assertNotEquals(null, c.Id, 'Contact should have an Id');
    }
}