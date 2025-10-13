@IsTest
private class TemplateSearchControllerTest {
    @IsTest static void testSearchTemplates_empty() {
        Test.startTest();
        List<Template__c> r = TemplateSearchController.searchTemplates('');
        Test.stopTest();
        System.assertNotEquals(null, r);
    }
}
