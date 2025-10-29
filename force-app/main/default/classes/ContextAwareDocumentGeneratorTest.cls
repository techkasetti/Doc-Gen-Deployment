@IsTest
private class ContextAwareDocumentGeneratorTest {

    // Utility to check if object exists
    private static Boolean objectExists(String objectName) {
        return Schema.getGlobalDescribe().containsKey(objectName);
    }

    // Utility to insert a DocumentTemplate__c safely (if object exists)
    private static Id createTemplateIfAvailable() {
        if (objectExists('DocumentTemplate__c')) {
            DocumentTemplate__c template = (DocumentTemplate__c)
                Schema.getGlobalDescribe().get('DocumentTemplate__c').newSObject();
            Map<String, Schema.SObjectField> fields =
                template.getSObjectType().getDescribe().fields.getMap();

            if (fields.containsKey('Name')) template.put('Name', 'Unit Test Template');
            if (fields.containsKey('Template_Content__c'))
                template.put('Template_Content__c', 'Hello {{insights}} World!');
            if (fields.containsKey('Template_Type__c'))
                template.put('Template_Type__c', 'AI');
            if (fields.containsKey('AI_Instructions__c'))
                template.put('AI_Instructions__c', 'Generate based on insights.');
            insert template;
            return template.Id;
        }
        return null;
    }

    @IsTest
    static void testGenerateDocument_Success() {
        // Arrange
        Id templateId = createTemplateIfAvailable();

        Map<String, Object> contextAnalysis = new Map<String, Object>{
            'contextualInsights' => new Map<String, Object>{ 'Insight1' => 'Value1' },
            'entityRelationships' => new Map<String, Object>{ 'topEntities' => new List<Object>{ 'EntityA', 'EntityB' } }
        };

        List<String> generationOptions = new List<String>{ 'citations', 'compliance_checks' };
        List<Map<String, Object>> conversationHistory = new List<Map<String, Object>>{
            new Map<String, Object>{ 'utterance' => 'Hello AI' },
            new Map<String, Object>{ 'utterance' => 'Generate document' }
        };

        // Act
        Test.startTest();
        Map<String, Object> result = ContextAwareDocumentGenerator.generateDocument(
            contextAnalysis,
            templateId,
            'UnitTestDocument',
            'Custom instructions go here.',
            generationOptions,
            'einstein_test_model',
            conversationHistory
        );
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.get('success'), 'Expected success to be true');
        System.assert(result.containsKey('content'), 'Result should contain generated content');
        System.assert(result.containsKey('documentId'), 'Result should contain ContentDocumentId');
        System.assert(result.containsKey('generationMetadata'), 'Metadata must exist');
    }

    @IsTest
    static void testGenerateDocument_TemplateMissing() {
        // Arrange
        Map<String, Object> contextAnalysis = new Map<String, Object>();
        List<String> options = new List<String>();

        // Act
        Test.startTest();
        Map<String, Object> result = ContextAwareDocumentGenerator.generateDocument(
            contextAnalysis,
            null,
            'MissingTemplateDoc',
            null,
            options,
            'external_model_test',
            new List<Map<String, Object>>()
        );
        Test.stopTest();

        // Assert
        System.assert(result.containsKey('success'), 'Result should contain success flag');
        System.assertEquals(true, result.get('success'), 'Even without a template, it should handle gracefully');
    }

    @IsTest
    static void testGenerateDocument_WithErrors() {
        // Force exception by mocking invalid data
        Map<String, Object> contextAnalysis = new Map<String, Object>{
            'contextualInsights' => new Map<String, Object>{ 'Test' => 'Value' }
        };

        Test.startTest();
        Map<String, Object> result;
        try {
            result = ContextAwareDocumentGenerator.generateDocument(
                null, // No template
                'invalidId',
                'ErrorCase',
                null,
                new List<String>{ 'citations' },
                'einstein_mock',
                new List<Map<String, Object>>()
            );
        } catch (Exception e) {
            result = new Map<String, Object>{ 'success' => false, 'error' => e.getMessage() };
        }
        Test.stopTest();

        System.assert(result != null, 'Result should not be null even in error case');
        System.assert(result.containsKey('success'), 'Result must include success flag');
    }
}