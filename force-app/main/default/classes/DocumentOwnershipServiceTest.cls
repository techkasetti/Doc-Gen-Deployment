@IsTest
private class DocumentOwnershipServiceTest {
    @IsTest static void testTransferOwnership_null() {
        Test.startTest();
        Boolean ok = DocumentOwnershipService.transferOwnership(null, null);
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}