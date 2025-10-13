@IsTest
private class TerraformControllerTest {
    @IsTest static void testApplyPlan_invalid() {
        Test.startTest();
        Boolean ok = TerraformController.applyPlan('');
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}
