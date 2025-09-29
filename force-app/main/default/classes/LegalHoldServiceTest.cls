@IsTest
private class LegalHoldServiceTest {
    @IsTest static void testPlaceLegalHold_null() {
        Test.startTest();
        Boolean ok = LegalHoldService.placeLegalHold(null, 'gm');
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}