@IsTest
private class LocalizationServiceTest {
    @IsTest static void testGetStrings_default() {
        Test.startTest();
        Map<String,String> s = LocalizationService.getStrings(null);
        Test.stopTest();
        System.assertEquals('Hello', s.get('hello'));
    }
}
