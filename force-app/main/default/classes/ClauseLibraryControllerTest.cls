@isTest
public with sharing class ClauseLibraryControllerTest {

    @isTest
    static void testGetClauses() {
        Test.startTest();
        List<Clause__c> clauses = ClauseLibraryController.getClauses();
        Test.stopTest();

        System.assertNotEquals(null, clauses, 'Clauses list should not be null');
    }

    @isTest
    static void testSearchClauses() {
        Test.startTest();
        List<Clause__c> results = ClauseLibraryController.searchClauses('Agreement');
        Test.stopTest();

        System.assertNotEquals(null, results, 'Search results should not be null');
    }
}
