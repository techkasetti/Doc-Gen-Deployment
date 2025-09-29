@IsTest
private class TemplateDeprecationServiceTest {
    @IsTest static void testDeprecateTemplate_null() {
        Test.startTest();
        Boolean ok = TemplateDeprecationService.deprecateTemplate(null, null);
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}
