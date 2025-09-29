@IsTest
private class UserTrainingControllerTest {
    @IsTest static void testEnrollUserInCourse_invalid() {
        Test.startTest();
        Map<String,Object> r = UserTrainingController.enrollUserInCourse(null, '');
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }

    @IsTest static void testListAvailableCourses() {
        Test.startTest();
        List<String> c = UserTrainingController.listAvailableCourses();
        Test.stopTest();
        System.assert(c.size() > 0);
    }
}
