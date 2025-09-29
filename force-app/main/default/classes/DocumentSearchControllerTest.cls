@IsTest
private class DocumentSearchControllerTest {
    @IsTest static void testSearchNull() {
        Test.startTest();
        List<Id> r = DocumentSearchController.searchDocuments('');
        Test.stopTest();
        System.assertEquals(0, r.size());
    }
}