@isTest
private class BusinessIntelligenceControllerTest {
    @isTest static void testExportReport_invalid() {
        Test.startTest();
        Map<String,Object> r = BusinessIntelligenceController.exportReport('');
        Test.stopTest();
        System.assertEquals('error', r.get('status'));
    }
}