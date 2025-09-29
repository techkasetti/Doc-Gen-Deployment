@isTest
public class SystemHealthDashboardControllerTest {
    
    @TestSetup
    static void makeData() {
        // Create system alerts
        List<System_Alert__c> alerts = new List<System_Alert__c>();
        alerts.add(new System_Alert__c(
            Alert_Type__c = 'PERFORMANCE',
            Severity__c = 'HIGH',
            Message__c = 'High response time detected',
            Component__c = 'Document Generation',
            Status__c = 'ACTIVE',
            Impact_Level__c = 'MEDIUM'
        ));
        alerts.add(new System_Alert__c(
            Alert_Type__c = 'ERROR',
            Severity__c = 'CRITICAL',
            Message__c = 'Database connection failed',
            Component__c = 'Data Storage',
            Status__c = 'ACTIVE',
            Impact_Level__c = 'HIGH'
        ));
        insert alerts;
        
        // Create performance snapshots
        List<Performance_Snapshot__c> snapshots = new List<Performance_Snapshot__c>();
        for (Integer i = 0; i < 10; i++) {
            snapshots.add(new Performance_Snapshot__c(
                Snapshot_Date__c = DateTime.now().addHours(-i),
                Response_Time__c = 2500 + (i * 100),
                Error_Rate__c = 2.5 + (i * 0.5),
                Throughput__c = 450 - (i * 10),
                System_Load__c = 65 + (i * 2),
                Memory_Usage__c = 45 + (i * 3),
                CPU_Usage__c = 35 + (i * 2),
                Storage_Usage__c = 58 + i
            ));
        }
        insert snapshots;
        
        // Create compliance check results
        List<Compliance_Check_Result__c> complianceResults = new List<Compliance_Check_Result__c>();
        for (Integer i = 0; i < 5; i++) {
            complianceResults.add(new Compliance_Check_Result__c(
                Check_Date__c = DateTime.now().addDays(-i),
                Compliance_Score__c = 95 - (i * 2),
                Status__c = i < 3 ? 'COMPLIANT' : 'NON_COMPLIANT',
                Check_Type__c = 'AUTOMATED',
                Component__c = 'Document Generation'
            ));
        }
        insert complianceResults;
        
        // Create document generation logs
        List<Document_Generation_Log__c> docLogs = new List<Document_Generation_Log__c>();
        for (Integer i = 0; i < 15; i++) {
            docLogs.add(new Document_Generation_Log__c(
                Status__c = i < 12 ? 'COMPLETED' : 'FAILED',
                Processing_Time__c = 2000 + (i * 200),
                Document_Type__c = 'Contract',
                Template_Used__c = 'Standard_Template_' + i
            ));
        }
        insert docLogs;
        
        // Create signature requests
        List<Signature_Request__c> sigRequests = new List<Signature_Request__c>();
        for (Integer i = 0; i < 8; i++) {
            sigRequests.add(new Signature_Request__c(
                Status__c = i < 6 ? 'COMPLETED' : 'PENDING',
                Document_Type__c = 'Employment Agreement',
                Signer_Email__c = 'test' + i + '@example.com'
            ));
        }
        insert sigRequests;
        
        // Create AI processing logs
        List<AI_Processing_Log__c> aiLogs = new List<AI_Processing_Log__c>();
        for (Integer i = 0; i < 12; i++) {
            aiLogs.add(new AI_Processing_Log__c(
                Processing_Status__c = i < 10 ? 'SUCCESS' : 'FAILED',
                Model_Used__c = 'GPT-4',
                Processing_Time_Ms__c = 3500 + (i * 150),
                Created_Date__c = DateTime.now().addHours(-i)
            ));
        }
        insert aiLogs;
        
        // Create integration logs
        List<Integration_Log__c> intLogs = new List<Integration_Log__c>();
        for (Integer i = 0; i < 10; i++) {
            intLogs.add(new Integration_Log__c(
                Status__c = i < 8 ? 'SUCCESS' : 'FAILED',
                Service_Name__c = 'DocuSign_API',
                Response_Time_Ms__c = 1500 + (i * 100),
                Call_Date__c = DateTime.now().addHours(-i)
            ));
        }
        insert intLogs;
    }
    
    
    @isTest
    static void testGetDashboardData() {
        Test.startTest();
        Map<String, Object> result = SystemHealthDashboardController.getDashboardData('7_DAYS');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Dashboard data should not be null');
        System.assert(result.containsKey('healthSummary'));
        System.assert(result.containsKey('componentHealth'));
        System.assert(result.containsKey('recentAlerts'));
        System.assert(result.containsKey('performanceCharts'));
        System.assert(result.containsKey('systemResources'));
        System.assert(result.containsKey('complianceStatus'));
    }
    
    
    @isTest
    static void testExecuteSystemHealthCheck() {
        Test.startTest();
        Map<String, Object> result = SystemHealthDashboardController.executeSystemHealthCheck();
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assert(result.containsKey('success'));
        System.assert(result.containsKey('healthScore'));
        System.assert(result.containsKey('message'));
        System.assert(result.containsKey('recommendedActions'));
        System.assertNotEquals(null, (Boolean) result.get('success'));
    }
    
    
    @isTest
    static void testAcknowledgeSystemAlert() {
        System_Alert__c alert = [SELECT Id FROM System_Alert__c WHERE Status__c = 'ACTIVE' LIMIT 1];
        
        Test.startTest();
        Map<String, Object> result = SystemHealthDashboardController.acknowledgeSystemAlert(alert.Id, 'Acknowledged for testing');
        Test.stopTest();
        
        System.assertEquals(true, result.get('success'));
        
        // Verify alert updated
        System_Alert__c updatedAlert = [SELECT Status__c, Acknowledged_By__c FROM System_Alert__c WHERE Id = :alert.Id];
        System.assertEquals('ACKNOWLEDGED', updatedAlert.Status__c);
        System.assertEquals(UserInfo.getUserId(), updatedAlert.Acknowledged_By__c);
    }
    
    
    @isTest
    static void testDismissAlert() {
        System_Alert__c alert = [SELECT Id FROM System_Alert__c WHERE Status__c = 'ACTIVE' LIMIT 1];
        
        Test.startTest();
        Map<String, Object> result = SystemHealthDashboardController.dismissAlert(alert.Id, 'Dismissed for testing');
        Test.stopTest();
        
        System.assertEquals(true, result.get('success'));
        
        // Verify alert updated
        System_Alert__c updatedAlert = [SELECT Status__c, Dismissed_By__c FROM System_Alert__c WHERE Id = :alert.Id];
        System.assertEquals('DISMISSED', updatedAlert.Status__c);
        System.assertEquals(UserInfo.getUserId(), updatedAlert.Dismissed_By__c);
    }
    
    
    @isTest
    static void testGenerateHealthReport() {
        Test.startTest();
        Map<String, Object> result = SystemHealthDashboardController.generateHealthReport('7_DAYS', true);
        Test.stopTest();
        
        System.assertEquals(true, result.get('success'));
        System.assertNotEquals(null, result.get('report'));
        
        String reportContent = (String) result.get('report');
        System.assert(reportContent.contains('SYSTEM HEALTH REPORT'));
        System.assert(reportContent.contains('EXECUTIVE SUMMARY'));
        System.assert(reportContent.contains('COMPONENT STATUS'));
        System.assert(reportContent.contains('PERFORMANCE METRICS'));
    }
    
    
    @isTest
    static void testGetPerformanceHistory() {
        Test.startTest();
        List<Map<String, Object>> result = SystemHealthDashboardController.getPerformanceHistory(7);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assert(result.size() > 0);
        
        // Verify structure
        Map<String, Object> firstEntry = result[0];
        System.assert(firstEntry.containsKey('timestamp'));
        System.assert(firstEntry.containsKey('responseTime'));
        System.assert(firstEntry.containsKey('errorRate'));
        System.assert(firstEntry.containsKey('throughput'));
    }
    
    
    @isTest
    static void testComponentHealthChecks() {
        Test.startTest();
        SystemHealthDashboardController controller = new SystemHealthDashboardController();
        
        SystemHealthDashboardController.ComponentHealthResult docGen = controller.checkDocumentGenerationHealth();
        SystemHealthDashboardController.ComponentHealthResult sig = controller.checkESignatureHealth();
        SystemHealthDashboardController.ComponentHealthResult compliance = controller.checkComplianceEngineHealth();
        SystemHealthDashboardController.ComponentHealthResult ai = controller.checkAIProcessingHealth();
        SystemHealthDashboardController.ComponentHealthResult integration = controller.checkIntegrationServicesHealth();
        SystemHealthDashboardController.ComponentHealthResult storage = controller.checkDataStorageHealth();
        
        Test.stopTest();
        
        System.assertNotEquals(null, docGen.status);
        System.assertNotEquals(null, sig.status);
        System.assertNotEquals(null, compliance.status);
        System.assertNotEquals(null, ai.status);
        System.assertNotEquals(null, integration.status);
        System.assertNotEquals(null, storage.status);
    }
    
    
    @isTest
    static void testErrorHandling() {
        Test.startTest();
        try {
            SystemHealthDashboardController.acknowledgeSystemAlert('invalid_id', 'Test notes');
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Failed to acknowledge alert'));
        }
        
        try {
            SystemHealthDashboardController.dismissAlert('invalid_id', 'Test reason');
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Failed to dismiss alert'));
        }
        Test.stopTest();
    }
    
    
    @isTest
    static void testUtilityMethods() {
        Test.startTest();
        
        // Timeframe conversions
        DateTime result24h = SystemHealthDashboardController.getStartTimeForTimeframe('24_HOURS');
        DateTime result7d = SystemHealthDashboardController.getStartTimeForTimeframe('7_DAYS');
        DateTime result30d = SystemHealthDashboardController.getStartTimeForTimeframe('30_DAYS');
        DateTime result90d = SystemHealthDashboardController.getStartTimeForTimeframe('90_DAYS');
        DateTime resultDefault = SystemHealthDashboardController.getStartTimeForTimeframe('INVALID');
        
        // Status variants
        String successVariant = SystemHealthDashboardController.getStatusVariant('HEALTHY');
        String warningVariant = SystemHealthDashboardController.getStatusVariant('WARNING');
        String errorVariant = SystemHealthDashboardController.getStatusVariant('CRITICAL');
        String neutralVariant = SystemHealthDashboardController.getStatusVariant('UNKNOWN');
        
        // Severity variants
        String highSeverity = SystemHealthDashboardController.getSeverityVariant('CRITICAL');
        String mediumSeverity = SystemHealthDashboardController.getSeverityVariant('MEDIUM');
        String lowSeverity = SystemHealthDashboardController.getSeverityVariant('LOW');
        
        Test.stopTest();
        
        // Assertions
        System.assert(result24h > DateTime.now().addHours(-25));
        System.assert(result7d > DateTime.now().addDays(-8));
        System.assert(result30d > DateTime.now().addDays(-31));
        System.assert(result90d > DateTime.now().addDays(-91));
        
        System.assertEquals('success', successVariant);
        System.assertEquals('warning', warningVariant);
        System.assertEquals('error', errorVariant);
        System.assertEquals('neutral', neutralVariant);
        
        System.assertEquals('error', highSeverity);
        System.assertEquals('warning', mediumSeverity);
        System.assertEquals('success', lowSeverity);
    }
}
