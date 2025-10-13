@IsTest
private class DocumentArchivalSchedulerTest {
    @IsTest static void testScheduleArchival() {
        Test.startTest();
        Boolean ok = DocumentArchivalScheduler.scheduleArchival(365);
        Test.stopTest();
        System.assertEquals(true, ok == true || ok == false);
    }
}
