@IsTest
private class CompliancePacketExporterTest {
    @IsTest static void testGetExportUrl() {
        Test.startTest();
        String u = CompliancePacketExporter.getExportUrl(null);
        Test.stopTest();
        System.assertEquals(null, u);
    }
}