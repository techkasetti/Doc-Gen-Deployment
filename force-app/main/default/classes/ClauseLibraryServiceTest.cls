@IsTest
private class ClauseLibraryServiceTest {
    @IsTest static void testUpsertClause_blankKey() {
        Test.startTest();
        Id id = ClauseLibraryService.upsertClause('', 't','b');
        Test.stopTest();
        System.assertEquals(null, id);
    }
}