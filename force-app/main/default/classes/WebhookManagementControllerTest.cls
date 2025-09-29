@IsTest
private class WebhookManagementControllerTest {
    @IsTest static void testRegisterWebhook_invalid() {
        Test.startTest();
        Map<String,Object> r = WebhookManagementController.registerWebhook('', '');
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }

    @IsTest static void testDeleteWebhook_invalid() {
        Test.startTest();
        Boolean ok = WebhookManagementController.deleteWebhook('');
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}
