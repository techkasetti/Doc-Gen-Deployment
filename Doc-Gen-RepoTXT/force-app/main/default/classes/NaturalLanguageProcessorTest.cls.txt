@IsTest
private class NaturalLanguageProcessorTest {
    @IsTest static void testProcess_invalid() {
        Test.startTest();
        Map<String,Object> r = NaturalLanguageProcessor.process('');
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }
}
