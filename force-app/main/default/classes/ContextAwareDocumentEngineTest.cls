@isTest
public with sharing class ContextAwareDocumentEngineTest {

    @isTest
    static void testAnalyzeFolderContext() {
        Test.startTest();
        Map<String, Object> result = ContextAwareDocumentEngine.analyzeFolderContext('001xx000003DHPb', 'einstein_intent');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey('documents'), 'Result should contain documents');
    }

    @isTest
    static void testAnalyzeFolderContext_InvalidModel() {
        Test.startTest();
        Map<String, Object> result = ContextAwareDocumentEngine.analyzeFolderContext('001xx000003DHPb', 'invalid_model');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey('documents'), 'Result should contain documents');
    }
     
        @TestSetup
        static void makeData() {
            // Create test AI model
            AI_Model_Configuration__c einsteinModel = new AI_Model_Configuration__c(
                Name = 'Einstein GPT',
                Model_ID__c = 'einstein_gpt_latest',
                Provider__c = 'Salesforce',
                Is_Active__c = true,
                Capabilities__c = 'text_generation,sentiment_analysis,entity_extraction',
                Model_Type__c = 'Large Language Model'
            );
            insert einsteinModel;
            
            // Create test folder
            Folder__c testFolder = new Folder__c(
                Name = 'Test Analysis Folder',
                Description__c = 'Test folder for context analysis',
                Is_Active__c = true
            );
            insert testFolder;

            // Create test documents
            List<ContentVersion> testDocs = new List<ContentVersion>();
            testDocs.add(new ContentVersion(
                Title = 'Contract Template',
                PathOnClient = 'contract.pdf',
                VersionData = Blob.valueOf('Sample contract content with compliance clauses'),
                ContentLocation = 'S'
            ));
            testDocs.add(new ContentVersion(
                Title = 'Legal Guidelines',
                PathOnClient = 'guidelines.docx',
                VersionData = Blob.valueOf('Legal guidelines for document generation and compliance requirements'),
                ContentLocation = 'S'
            ));
            testDocs.add(new ContentVersion(
                Title = 'Business Requirements',
                PathOnClient = 'requirements.txt',
                VersionData = Blob.valueOf('Business requirements for automated document generation with AI capabilities'),
                ContentLocation = 'S'
            ));
            insert testDocs;

            // Create folder context analysis record
            Folder_Context_Analysis__c contextAnalysis = new Folder_Context_Analysis__c(
                Folder_Id__c = testFolder.Id,
                AI_Model__c = 'einstein_gpt_latest',
                Analysis_Status__c = 'COMPLETED',
                Document_Count__c = 3,
                Quality_Score__c = 85,
                Common_Themes__c = 'contract,compliance,legal,automation',
                Entity_Frequency__c = '{"contract":15,"compliance":12,"legal":8,"automation":6}',
                Analysis_Timestamp__c = DateTime.now()
            );
            insert contextAnalysis;
        }

        @IsTest
        static void testAnalyzeFolderContext() {
            Test.startTest();
            Folder__c testFolder = [SELECT Id FROM Folder__c LIMIT 1];
            
            ContextAwareDocumentEngine.FolderAnalysisResult result = 
                ContextAwareDocumentEngine.analyzeFolderContext(testFolder.Id, 'einstein_gpt_latest');
            
            System.assertNotEquals(null, result, 'Analysis result should not be null');
            System.assertEquals('SUCCESS', result.status, 'Analysis should be successful');
            System.assert(result.documentCount > 0, 'Should find documents in folder');
            System.assert(result.qualityScore > 0, 'Should have quality score');
            Test.stopTest();
        }

        @IsTest
        static void testAnalyzeFolderContextError() {
            Test.startTest();
            try {
                ContextAwareDocumentEngine.analyzeFolderContext('invalid_id', 'einstein_gpt_latest');
                System.assert(false, 'Should throw exception for invalid folder');
            } catch (Exception e) {
                System.assert(e.getMessage().contains('Invalid folder'), 'Should contain error message');
            }
            Test.stopTest();
        }

        @IsTest
        static void testGenerateContextAwareDocument() {
            Test.startTest();
            Folder__c testFolder = [SELECT Id FROM Folder__c LIMIT 1];
            Folder_Context_Analysis__c analysis = [SELECT Id FROM Folder_Context_Analysis__c LIMIT 1];
            
            ContextAwareDocumentEngine.DocumentGenerationRequest request = 
                new ContextAwareDocumentEngine.DocumentGenerationRequest();
            request.folderId = testFolder.Id;
            request.analysisId = analysis.Id;
            request.aiModel = 'einstein_gpt_latest';
            request.template = 'Contract Template';
            request.customPrompt = 'Generate a comprehensive contract based on analyzed documents';
            request.outputFormat = 'HTML';
            
            ContextAwareDocumentEngine.DocumentGenerationResult result = 
                ContextAwareDocumentEngine.generateContextAwareDocument(request);
            
            System.assertNotEquals(null, result, 'Generation result should not be null');
            System.assertEquals('SUCCESS', result.status, 'Generation should be successful');
            System.assert(result.content.length() > 0, 'Should generate content');
            System.assert(result.wordCount > 0, 'Should calculate word count');
            Test.stopTest();
        }

        @IsTest
        static void testAskContextualQuestion() {
            Test.startTest();
            Folder__c testFolder = [SELECT Id FROM Folder__c LIMIT 1];
            
            ContextAwareDocumentEngine.QuestionAnswerResult result = 
                ContextAwareDocumentEngine.askContextualQuestion(
                    testFolder.Id,
                    'What are the main compliance requirements mentioned?',
                    'einstein_gpt_latest'
                );
            
            System.assertNotEquals(null, result, 'Q&A result should not be null');
            System.assertEquals('SUCCESS', result.status, 'Q&A should be successful');
            System.assert(result.answer.length() > 0, 'Should provide an answer');
            System.assert(result.sources.size() > 0, 'Should include sources');
            Test.stopTest();
        }

        @IsTest
        static void testBulkAnalysis() {
            Test.startTest();
            List<Folder__c> folders = new List<Folder__c>();
            for (Integer i = 0; i < 5; i++) {
                folders.add(new Folder__c(
                    Name = 'Test Folder ' + i,
                    Description__c = 'Bulk test folder ' + i,
                    Is_Active__c = true
                ));
            }
            insert folders;
            
            List<String> folderIds = new List<String>();
            for (Folder__c folder : folders) {
                folderIds.add(folder.Id);
            }
            
            List<ContextAwareDocumentEngine.FolderAnalysisResult> results = 
                ContextAwareDocumentEngine.bulkAnalyzeFolders(folderIds, 'einstein_gpt_latest');
            
            System.assertEquals(5, results.size(), 'Should analyze all folders');
            for (ContextAwareDocumentEngine.FolderAnalysisResult result : results) {
                System.assertNotEquals(null, result, 'Each result should not be null');
            }
            Test.stopTest();
        }

        @IsTest
        static void testPerformanceMetrics() {
            Test.startTest();
            Folder__c testFolder = [SELECT Id FROM Folder__c LIMIT 1];
            
            DateTime startTime = DateTime.now();
            ContextAwareDocumentEngine.FolderAnalysisResult result = 
                ContextAwareDocumentEngine.analyzeFolderContext(testFolder.Id, 'einstein_gpt_latest');
            DateTime endTime = DateTime.now();
            
            Long processingTime = endTime.getTime() - startTime.getTime();
            
            System.assert(processingTime < 30000, 'Analysis should complete within 30 seconds');
            System.assertNotEquals(null, result.processingTime, 'Should track processing time');
            Test.stopTest();
        }

        @IsTest
        static void testErrorHandling() {
            Test.startTest();
            try {
                ContextAwareDocumentEngine.analyzeFolderContext(null, 'einstein_gpt_latest');
                System.assert(false, 'Should handle null folder ID');
            } catch (Exception e) {
                System.assert(e.getMessage().contains('Folder ID cannot be null'));
            }
            
            try {
                ContextAwareDocumentEngine.analyzeFolderContext('valid_id', null);
                System.assert(false, 'Should handle null AI model');
            } catch (Exception e) {
                System.assert(e.getMessage().contains('AI Model cannot be null'));
            }
            Test.stopTest();
        }

        @IsTest
        static void testSecurityAndPermissions() {
            Test.startTest();
            User testUser = new User(
                FirstName = 'Test',
                LastName = 'User',
                Email = 'testuser@example.com',
                Username = 'testuser@example.com.test',
                Alias = 'tuser',
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id
            );
            insert testUser;
            
            System.runAs(testUser) {
                Folder__c testFolder = [SELECT Id FROM Folder__c LIMIT 1];
                try {
                    ContextAwareDocumentEngine.analyzeFolderContext(testFolder.Id, 'einstein_gpt_latest');
                } catch (Exception e) {
                    // Expected for users without proper permissions
                }
            }
            Test.stopTest();
        }
}
