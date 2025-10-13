@IsTest
private class QuantumCryptographyControllerTest {
    @IsTest static void testValidateQuantumKey_invalid() {
        Test.startTest();
        Boolean ok = QuantumCryptographyController.validateQuantumKey('');
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}
