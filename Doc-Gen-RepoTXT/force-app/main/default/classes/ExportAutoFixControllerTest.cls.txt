@IsTest
private class ExportAutoFixControllerTest {
    @IsTest static void testApplyFix() {
        Test.startTest();
        Boolean ok = ExportAutoFixController.applyFix('ck1');
        Test.stopTest();
        System.assertEquals(true, ok);
    }
}
