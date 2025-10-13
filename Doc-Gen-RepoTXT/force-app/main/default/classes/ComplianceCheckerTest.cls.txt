@IsTest
private class ComplianceCheckerTest {
    @IsTest static void testRunChecks() {
        Map<String,Object> res = ComplianceChecker.runChecks('doc-1');
        System.assertEquals(true, res.get('ok'));
        System.assert(((List<String>)res.get('messages')).contains('stub-rule-pass'));
        Map<String,Object> res2 = ComplianceChecker.runChecks('');
        System.assertEquals(false, res2.get('ok'));
    }
}
