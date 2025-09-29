@IsTest
private class TemplatePublishServiceTest {
    @IsTest static void testPublishTemplate_null() {
        Test.startTest();
        Boolean ok = TemplatePublishService.publishTemplate(null);
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}
