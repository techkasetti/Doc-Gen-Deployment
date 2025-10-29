@isTest
private class AccessibilityComplianceControllerTest {
    @isTest static void testRunAccessibilityCheck_missing() {
        Test.startTest();
        Map<String,Object> r = AccessibilityComplianceController.runAccessibilityCheck('');
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }
    @isTest static void testRunAccessibilityCheck_ok() {
        Test.startTest();
        Map<String,Object> r = AccessibilityComplianceController.runAccessibilityCheck('componentX');
        Test.stopTest();
        System.assertEquals(true, r.get('ok'));
    }
}