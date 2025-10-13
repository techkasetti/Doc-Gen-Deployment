@IsTest
private class MobileDocumentControllerTest {
    @IsTest static void testFetchForMobile_invalid() {
        Test.startTest();
        Map<String,Object> r = MobileDocumentController.fetchForMobile(null);
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }
}
