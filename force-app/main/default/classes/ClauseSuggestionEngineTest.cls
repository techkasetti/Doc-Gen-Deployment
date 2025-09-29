@IsTest
private class ClauseSuggestionEngineTest {
    @IsTest static void testSuggestClauses_empty() {
        Test.startTest();
        List<String> s = ClauseSuggestionEngine.suggestClauses(null, 3);
        Test.stopTest();
        System.assertEquals(0, s.size());
    }
    @IsTest static void testSuggestClauses_flow() {
        Test.startTest();
        List<String> s = ClauseSuggestionEngine.suggestClauses('doc-x', 2);
        Test.stopTest();
        System.assert(s.size() >= 1);
    }
}