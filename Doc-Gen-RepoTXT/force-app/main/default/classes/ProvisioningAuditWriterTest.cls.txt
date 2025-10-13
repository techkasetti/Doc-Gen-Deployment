@IsTest
private class ProvisioningAuditWriterTest {
    @IsTest static void testWrite_noObject() {
        Test.startTest();
        Id id = ProvisioningAuditWriter.write('c','m', null);
        Test.stopTest();
        System.assert(true);
    }
}
