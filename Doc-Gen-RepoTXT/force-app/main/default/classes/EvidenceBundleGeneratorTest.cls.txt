@IsTest
private class EvidenceBundleGeneratorTest {
    @IsTest static void testGenerateBundle_nullDoc() {
        Test.startTest();
        Id id = EvidenceBundleGenerator.generateBundle(null, new List<Id>{});
        Test.stopTest();
        System.assertEquals(null, id);
    }
}
