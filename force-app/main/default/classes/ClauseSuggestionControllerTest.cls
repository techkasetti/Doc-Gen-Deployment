@IsTest
private class ClauseSuggestionControllerTest {
    @IsTest static void testGetSuggestions_null() {
        Test.startTest();
        Map<String,Object> r = ClauseSuggestionController.getSuggestions(null, 3);
        Test.stopTest();
        System.assertEquals(false, (Boolean)r.get('ok'));
    }
}