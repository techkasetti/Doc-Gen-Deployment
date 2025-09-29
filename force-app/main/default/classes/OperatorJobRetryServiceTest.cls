@IsTest
private class OperatorJobRetryServiceTest {
    @IsTest static void testMarkRetry_null() {
        Test.startTest();
        Boolean ok = OperatorJobRetryService.markRetry(null, 1);
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}
