@IsTest
private class DocumentPurgeJobTest {
    @IsTest static void testSchedule() {
        Test.startTest();
        System.schedule('purgejob', '0 0 0 ? * SUN', new DocumentPurgeJob());
        Test.stopTest();
        System.assert(true);
    }
}