@IsTest
private class PKIIntegrationServiceTest {
    @IsTest static void testSubmitForSigning_invalid() {
        Test.startTest();
        Boolean ok = PKIIntegrationService.submitForSigning(null, null);
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}
