/**
 * Test class for AI Model Manager
 */
@IsTest
public class AIModelManagerTest {
    
    @TestSetup
    static void makeData() {
        List<AI_Model_Configuration__c> models = new List<AI_Model_Configuration__c>();
        models.add(new AI_Model_Configuration__c(
            Name = 'Einstein GPT',
            Model_ID__c = 'einstein_gpt_latest',
            Provider__c = 'Salesforce',
            Is_Active__c = true,
            Capabilities__c = 'text_generation,analysis',
            Context_Window_Size__c = 4096,
            Model_Type__c = 'Large Language Model'
        ));
        models.add(new AI_Model_Configuration__c(
            Name = 'Claude 3',
            Model_ID__c = 'claude_3_sonnet',
            Provider__c = 'Anthropic',
            Is_Active__c = true,
            Capabilities__c = 'text_generation,reasoning',
            Context_Window_Size__c = 200000,
            Model_Type__c = 'Large Language Model'
        ));
        insert models;
    }
    
    @IsTest
    static void testGetAvailableModels() {
        Test.startTest();
        List<AIModelManager.AIModelInfo> models = AIModelManager.getAvailableModels();
        System.assert(models.size() >= 2, 'Should return available models');
        System.assertEquals('Einstein GPT', models[0].modelName, 'Should return correct model name');
        Test.stopTest();
    }
    
    @IsTest
    static void testGetModelCapabilities() {
        Test.startTest();
        List<String> capabilities = AIModelManager.getModelCapabilities('einstein_gpt_latest');
        System.assert(capabilities.size() > 0, 'Should return capabilities');
        System.assert(capabilities.contains('text_generation'), 'Should include text generation');
        Test.stopTest();
    }
    
    @IsTest
    static void testValidateModelAccess() {
        Test.startTest();
        Boolean hasAccess = AIModelManager.validateModelAccess('einstein_gpt_latest');
        System.assertEquals(true, hasAccess, 'Should have access to active model');
        
        Boolean noAccess = AIModelManager.validateModelAccess('invalid_model');
        System.assertEquals(false, noAccess, 'Should not have access to invalid model');
        Test.stopTest();
    }
}
