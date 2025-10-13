@IsTest
private class SimilarityQueryServiceTest {
    @IsTest static void testFindSimilarEmpty() {
        Test.startTest();
        List<Id> res = SimilarityQueryService.findSimilarDocuments(null, 5);
        Test.stopTest();
        System.assertEquals(0, res.size());
    }
}