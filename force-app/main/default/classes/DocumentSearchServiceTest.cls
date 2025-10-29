@IsTest
private class DocumentSearchServiceTest {
    @IsTest static void testSemanticSearch_empty() {
        Test.startTest();
        List<DocumentSearchService.SearchResult> res = DocumentSearchService.semanticSearch('', 5);
        Test.stopTest();
        System.assertEquals(0, res.size());
    }
}