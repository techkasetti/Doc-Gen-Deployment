@IsTest
private class Web3ControllerTest {
    @IsTest static void testSubmitOnChainProof_invalid() {
        Test.startTest();
        Map<String,Object> r = Web3Controller.submitOnChainProof('');
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }
}
