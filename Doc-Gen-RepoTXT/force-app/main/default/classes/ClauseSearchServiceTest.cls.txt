@IsTest
private class ClauseSearchServiceTest {
    @IsTest static void testSearchEmpty() {
        Test.startTest();
        List<Id> res = ClauseSearchService.searchClauses('', 5);
        Test.stopTest();
        System.assertEquals(0, res.size());
    }
}