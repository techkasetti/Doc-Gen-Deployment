@IsTest
private class MachineLearningModelManagerTest {
    @IsTest static void testRegisterModel_invalid() {
        Test.startTest();
        Map<String,Object> r = MachineLearningModelManager.registerModel('', null);
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }
}
