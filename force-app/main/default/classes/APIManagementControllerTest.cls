@isTest
private class APIManagementControllerTest {
    @isTest static void testListApis() {
        Test.startTest();
        List<String> l = APIManagementController.listApis();
        Test.stopTest();
        System.assert(l.size() > 0);
    }
    @isTest static void testSetQuota_invalid() {
        Test.startTest();
        Boolean ok = APIManagementController.setQuota('', null);
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}