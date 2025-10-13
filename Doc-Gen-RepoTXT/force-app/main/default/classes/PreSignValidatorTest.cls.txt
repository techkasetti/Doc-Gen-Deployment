@IsTest
private class PreSignValidatorTest {
    @IsTest static void testValidateNull() {
        Test.startTest();
        Map<String,Object> r = PreSignValidator.validateReadyForSign(null);
        Test.stopTest();
        System.assertEquals(false, (Boolean)r.get('ok'));
    }
}