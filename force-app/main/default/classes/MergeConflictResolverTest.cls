@IsTest
private class MergeConflictResolverTest {
    @IsTest static void testResolve() {
        Test.startTest();
        String s = MergeConflictResolver.resolveConflicts(new Map<String,String>{'k'=>'v'}, new Map<String,String>{'k'=>'x','a'=>'b'});
        Test.stopTest();
        System.assert(s != null);
    }
}