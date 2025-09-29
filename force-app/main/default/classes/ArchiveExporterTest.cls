@IsTest
private class ArchiveExporterTest {
    @IsTest static void testExportNull() {
        Test.startTest();
        String u = ArchiveExporter.exportBundle(null);
        Test.stopTest();
        System.assertEquals(null, u);
    }
}