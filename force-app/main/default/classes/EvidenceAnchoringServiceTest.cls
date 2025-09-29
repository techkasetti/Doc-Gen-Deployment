@IsTest
private class EvidenceAnchoringServiceTest {
    @IsTest static void testAnchorEvidence_null() {
        Test.startTest();
        Boolean ok = EvidenceAnchoringService.anchorEvidence(null, null);
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}
