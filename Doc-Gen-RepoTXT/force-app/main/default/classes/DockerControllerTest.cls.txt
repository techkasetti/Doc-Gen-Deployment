@IsTest
private class DockerControllerTest {
    @IsTest static void testGetContainerHealth() {
        Test.startTest();
        Map<String,Object> r = DockerController.getContainerHealth('faiss');
        Test.stopTest();
        System.assert(r.containsKey('ok'));
    }
}