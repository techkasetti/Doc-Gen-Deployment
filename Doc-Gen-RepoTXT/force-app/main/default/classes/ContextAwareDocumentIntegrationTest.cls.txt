// =========================================================
// Step 4.2: Integration Test Suite
// =========================================================
@IsTest
public class ContextAwareDocumentIntegrationTest {
    
    @TestSetup
    static void setupIntegrationData() {
        // Create complete test ecosystem
        
        // AI Models
        List<AI_Model_Configuration__c> models = new List<AI_Model_Configuration__c>();
        AI_Model_Configuration__c model = [
            SELECT Model_ID__c 
            FROM AI_Model_Configuration__c 
            WHERE Name = 'GPT-4 Turbo' 
            LIMIT 1
        ];

        // Test series of contextual questions
        List<String> questions = new List<String>{
            'What are the main compliance requirements mentioned in the documents?',
            'How should we handle data breaches according to these policies?',
            'What are the audit procedures outlined in the SOX compliance guidelines?',
            'What training requirements are specified for HIPAA compliance?',
            'How often should compliance monitoring be conducted?'
        };

        List<ContextAwareDocumentEngine.QuestionAnswerResult> qaResults = 
            new List<ContextAwareDocumentEngine.QuestionAnswerResult>();

        for (String question : questions) {
            ContextAwareDocumentEngine.QuestionAnswerResult result = 
                ContextAwareDocumentEngine.askContextualQuestion(
                    complianceFolder.Id, 
                    question, 
                    model.Model_ID__c
                );
            
            qaResults.add(result);
            
            System.assertEquals('SUCCESS', result.status, 'Q&A should succeed for: ' + question);
            System.assert(result.answer.length() > 0, 'Should provide answer for: ' + question);
            System.assert(result.sources.size() > 0, 'Should cite sources for: ' + question);
            System.assert(result.confidenceScore > 60, 'Should have reasonable confidence for: ' + question);
        }

        // Test conversation continuity
        ContextAwareDocumentEngine.ConversationContext context = 
            new ContextAwareDocumentEngine.ConversationContext();
        
        context.folderId = complianceFolder.Id;
        context.previousQuestions = qaResults;
        context.conversationId = 'test_conversation_' + DateTime.now().getTime();

        ContextAwareDocumentEngine.QuestionAnswerResult followUpResult = 
            ContextAwareDocumentEngine.askContextualQuestionWithContext(
                'Based on the previous answers, what would be a comprehensive compliance checklist?',
                model.Model_ID__c,
                context
            );

        System.assertEquals('SUCCESS', followUpResult.status, 'Follow-up Q&A should succeed');
        System.assert(
            followUpResult.answer.contains('checklist') || followUpResult.answer.contains('compliance'), 
            'Should provide relevant follow-up answer'
        );

        Test.stopTest();
    }

    // =========================================================
    // Advanced Analytics Test
    // =========================================================
    @IsTest
    static void testAdvancedDocumentAnalytics() {
        Test.startTest();

        List<Folder__c> folders = [
            SELECT Id, Name 
            FROM Folder__c 
            WHERE Parent_Folder__c != null
        ];
        
        AI_Model_Configuration__c model = [
            SELECT Model_ID__c 
            FROM AI_Model_Configuration__c 
            WHERE Name = 'Einstein GPT Production' 
            LIMIT 1
        ];

        ContextAwareDocumentEngine.DocumentAnalyticsRequest analyticsRequest = 
            new ContextAwareDocumentEngine.DocumentAnalyticsRequest();
        
        analyticsRequest.folderIds = new List<String>();
        for (Folder__c folder : folders) {
            analyticsRequest.folderIds.add(folder.Id);
        }
        analyticsRequest.aiModel = model.Model_ID__c;
        analyticsRequest.includeEntityAnalysis = true;
        analyticsRequest.includeThemeAnalysis = true;
        analyticsRequest.includeQualityMetrics = true;
        analyticsRequest.includeTrendAnalysis = true;

        ContextAwareDocumentEngine.DocumentAnalyticsResult analyticsResult = 
            ContextAwareDocumentEngine.generateDocumentAnalytics(analyticsRequest);

        System.assertEquals('SUCCESS', analyticsResult.status, 'Analytics generation should succeed');
        System.assert(analyticsResult.totalDocuments > 0, 'Should count documents');
        System.assert(analyticsResult.averageQuality > 0, 'Should calculate average quality');
        System.assert(analyticsResult.commonThemes.size() > 0, 'Should identify common themes');
        System.assert(analyticsResult.entityFrequencies.size() > 0, 'Should extract entity frequencies');
        System.assert(analyticsResult.crossFolderInsights.size() > 0, 'Should provide cross-folder insights');
        
        Test.stopTest();
    }

    // =========================================================
    // Error Handling & Recovery
    // =========================================================
    @IsTest
    static void testErrorHandlingAndRecovery() {
        Test.startTest();

        // Invalid folder
        try {
            ContextAwareDocumentEngine.analyzeFolderContext('invalid_folder_id', 'einstein_gpt_prod');
            System.assert(false, 'Should throw exception for invalid folder');
        } catch (ContextAwareDocumentEngine.DocumentEngineException e) {
            System.assert(e.getMessage().contains('Invalid folder'), 'Should contain appropriate error message');
        }

        // Invalid model
        Folder__c testFolder = [SELECT Id FROM Folder__c LIMIT 1];
        try {
            ContextAwareDocumentEngine.analyzeFolderContext(testFolder.Id, 'invalid_ai_model');
            System.assert(false, 'Should throw exception for invalid AI model');
        } catch (ContextAwareDocumentEngine.DocumentEngineException e) {
            System.assert(e.getMessage().contains('Invalid AI model'), 'Should contain appropriate error message');
        }

        // Empty folder
        Folder__c emptyFolder = new Folder__c(
            Name = 'Empty Test Folder',
            Description__c = 'Empty folder for testing',
            Is_Active__c = true
        );
        insert emptyFolder;

        ContextAwareDocumentEngine.FolderAnalysisResult emptyResult = 
            ContextAwareDocumentEngine.analyzeFolderContext(emptyFolder.Id, 'einstein_gpt_prod');
        
        System.assertEquals('WARNING', emptyResult.status, 'Should handle empty folder gracefully');
        System.assertEquals(0, emptyResult.documentCount, 'Should report zero documents');

        // Bulk operations (mixed)
        List<String> mixedFolderIds = new List<String>{ testFolder.Id, 'invalid_id', emptyFolder.Id };
        List<ContextAwareDocumentEngine.FolderAnalysisResult> bulkResults = 
            ContextAwareDocumentEngine.bulkAnalyzeFolders(mixedFolderIds, 'einstein_gpt_prod');

        System.assertEquals(3, bulkResults.size(), 'Should return results for all requests');
        System.assertEquals('SUCCESS', bulkResults[0].status, 'First should succeed');
        System.assertEquals('ERROR', bulkResults[1].status, 'Second should fail');
        System.assertEquals('WARNING', bulkResults[2].status, 'Third should warn');

        Test.stopTest();
    }

    // =========================================================
    // Security & Access Control
    // =========================================================
    @IsTest
    static void testSecurityAndAccessControl() {
        Test.startTest();

        // Limited user
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User limitedUser = new User(
            FirstName = 'Limited',
            LastName = 'User',
            Email = 'limiteduser@example.com',
            Username = 'limiteduser@example.com.test',
            Alias = 'luser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );
        insert limitedUser;

        Folder__c testFolder = [SELECT Id FROM Folder__c LIMIT 1];

        // Access control check
        System.runAs(limitedUser) {
            try {
                ContextAwareDocumentEngine.analyzeFolderContext(testFolder.Id, 'einstein_gpt_prod');
            } catch (Exception e) {
                System.assert(
                    e.getMessage().contains('permission') || e.getMessage().contains('access'), 
                    'Should indicate permission issue'
                );
            }
        }

        // Admin should succeed
        User adminUser = [
            SELECT Id 
            FROM User 
            WHERE Profile.Name = 'System Administrator' AND IsActive = true 
            LIMIT 1
        ];
        
        System.runAs(adminUser) {
            ContextAwareDocumentEngine.FolderAnalysisResult result = 
                ContextAwareDocumentEngine.analyzeFolderContext(testFolder.Id, 'einstein_gpt_prod');
            System.assertNotEquals('ERROR', result.status, 'Admin should have access');
        }

        Test.stopTest();
    }

    // =========================================================
    // (Other test methods continue...)
    // =========================================================
}
