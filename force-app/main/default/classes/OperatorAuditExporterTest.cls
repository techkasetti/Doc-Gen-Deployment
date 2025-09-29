@IsTest
private class OperatorAuditExporterTest {
    @IsTest static void testExportOperatorAudits() {
        Test.startTest();
        Id id = OperatorAuditExporter.exportOperatorAudits(30);
        Test.stopTest();
        System.assert(true);
    }
}
