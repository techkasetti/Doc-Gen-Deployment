@IsTest
private class DocumentProvenanceExporterTest {
    @IsTest static void testExportProvenance_null() {
        Test.startTest();
        Id id = DocumentProvenanceExporter.exportProvenance(null);
        Test.stopTest();
        System.assertEquals(null, id);
    }
}