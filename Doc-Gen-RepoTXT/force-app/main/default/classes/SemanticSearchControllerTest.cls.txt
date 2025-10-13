@IsTest
private class SemanticSearchControllerTest {
    @IsTest static void testSemanticSearch_empty() {
        Test.startTest();
        List<Map<String,Object>> r = SemanticSearchController.semanticSearch('', 5);
        Test.stopTest();
        System.assertEquals(0, r.size());
    }
}
