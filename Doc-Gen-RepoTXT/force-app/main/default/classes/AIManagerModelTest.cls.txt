@isTest
public with sharing class AIManagerModelTest {

    @isTest
    static void testGetAvailableModels() {
        Test.startTest();
        List<AIManagerModel.AIModel> models = AIManagerModel.getAvailableModels();
        Test.stopTest();

        System.assertNotEquals(null, models, 'Model list should not be null');
        System.assert(models.size() > 0, 'Model list should not be empty');
    }

    @isTest
    static void testGetModelById_Valid() {
        Test.startTest();
        AIManagerModel.AIModel model = AIManagerModel.getModelById('einstein_intent');
        Test.stopTest();

        System.assertNotEquals(null, model, 'Model should not be null');
        System.assertEquals('einstein_intent', model.id, 'Model ID should match');
    }

    @isTest
    static void testGetModelById_Invalid() {
        Test.startTest();
        AIManagerModel.AIModel model = AIManagerModel.getModelById('invalid_id');
        Test.stopTest();

        System.assertEquals(null, model, 'Model should be null for invalid ID');
    }
}
