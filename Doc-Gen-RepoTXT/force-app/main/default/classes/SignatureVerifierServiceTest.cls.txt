@IsTest
private class SignatureVerifierServiceTest {
    @IsTest static void testVerifySignatureHash_null() {
        Test.startTest();
        Boolean ok = SignatureVerifierService.verifySignatureHash(null, null);
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}
