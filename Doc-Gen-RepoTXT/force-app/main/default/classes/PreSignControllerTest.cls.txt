@IsTest
private class PreSignControllerTest {
    @IsTest static void testRunPreSignNull() {
        Test.startTest();
        Map<String,Object> r = PreSignController.runPreSign(null);
        Test.stopTest();
        System.assertEquals(false, (Boolean)r.get('ok'));
    }
}