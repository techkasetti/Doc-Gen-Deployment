@IsTest
private class CompliancePacketGeneratorTest {
    @IsTest static void testGeneratePacket_noObject() {
        Test.startTest();
        Id id = CompliancePacketGenerator.generatePacket(null);
        Test.stopTest();
        System.assertEquals(null, id);
    }
}