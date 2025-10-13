@isTest
private class AccessibilityControllerTest {
    @isTest static void testGetAccessibilityGuidelines() {
        Test.startTest();
        Map<String,Object> r = AccessibilityController.getAccessibilityGuidelines();
        Test.stopTest();
        System.assert(r.containsKey('wcag'));
    }
}
