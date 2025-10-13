public class IntelligentWorkflowOrchestrator {
    
    // Master orchestration method for complete document lifecycle
    public static WorkflowExecutionResult executeIntelligentWorkflow(
        String documentId, 
        Map<String, Object> workflowParameters
    ) {
        WorkflowExecutionResult result = new WorkflowExecutionResult();
        result.documentId = documentId;
        result.startTime = DateTime.now();
        result.workflowSteps = new List<WorkflowStepResult>();

        try {
            // Step 1: Document Analysis and Classification
            result.workflowSteps.add(executeDocumentAnalysis(documentId));

            // Step 2: Security Assessment and Enhancement
            result.workflowSteps.add(executeSecurityEnhancement(documentId));

            // Step 3: Compliance Validation
            result.workflowSteps.add(executeComplianceValidation(documentId, workflowParameters));

            // Step 4: Risk Assessment
            result.workflowSteps.add(executeRiskAssessment(documentId));

            // Step 5: Collaborative Setup
            result.workflowSteps.add(executeCollaborativeSetup(documentId, workflowParameters));

            // Step 6: Audit Trail Initialization
            result.workflowSteps.add(executeAuditTrailSetup(documentId));

            // Step 7: Automated Monitoring Setup
            result.workflowSteps.add(executeMonitoringSetup(documentId));

            // Step 8: Notification and Alerting Configuration
            result.workflowSteps.add(executeNotificationSetup(documentId, workflowParameters));

            result.endTime = DateTime.now();
            result.totalExecutionTime = result.endTime.getTime() - result.startTime.getTime();
            result.overallStatus = determineOverallWorkflowStatus(result.workflowSteps);
            result.successRate = calculateSuccessRate(result.workflowSteps);

            // Create comprehensive workflow record
            createWorkflowExecutionRecord(result);

        } catch (Exception e) {
            result.endTime = DateTime.now();
            result.overallStatus = 'FAILED';
            result.errorMessage = e.getMessage();
            result.errorDetails = e.getStackTraceString();
            logWorkflowError(documentId, e);
        }
        return result;
    }

    // ------------------- Workflow Step Implementations -------------------

    private static WorkflowStepResult executeDocumentAnalysis(String documentId) {
        WorkflowStepResult stepResult = new WorkflowStepResult();
        stepResult.stepName = 'Document Analysis';
        stepResult.stepDescription = 'Analyze document content, structure, and metadata';
        stepResult.startTime = DateTime.now();

        try {
            // Analyze document content and structure
            DocumentAnalysisResult analysisResult = 
                DocumentIntelligenceEngine.performComprehensiveAnalysis(documentId);

            // Extract document metadata
            Map<String, Object> metadata = 
                DocumentMetadataExtractor.extractMetadata(documentId);

            // Classify document type and sensitivity
            String documentType = DocumentClassifier.classifyDocument(documentId);
            String sensitivityLevel = SensitivityAnalyzer.analyzeSensitivity(documentId);

            // Store analysis results
            DocumentAnalysisRecord__c analysisRecord = new DocumentAnalysisRecord__c(
                Document__c = documentId,
                Document_Type__c = documentType,
                Sensitivity_Level__c = sensitivityLevel,
                Content_Analysis__c = JSON.serialize(analysisResult),
                Metadata_Extracted__c = JSON.serialize(metadata),
                Analysis_Date__c = DateTime.now(),
                Analysis_Status__c = 'COMPLETED',
                Key_Topics__c = String.join(analysisResult.keyTopics, ';'),
                Language_Detected__c = analysisResult.primaryLanguage,
                Page_Count__c = analysisResult.pageCount,
                Word_Count__c = analysisResult.wordCount,
                Character_Count__c = analysisResult.characterCount
            );
            insert analysisRecord;

            stepResult.endTime = DateTime.now();
            stepResult.status = 'SUCCESS';
            stepResult.output = 
                'Document analyzed: Type=' + documentType + ', Sensitivity=' + sensitivityLevel;
            stepResult.details = JSON.serialize(analysisResult);

        } catch (Exception e) {
            stepResult.endTime = DateTime.now();
            stepResult.status = 'FAILED';
            stepResult.errorMessage = e.getMessage();
            stepResult.output = 'Document analysis failed';
        }
        return stepResult;
    }

    private static WorkflowStepResult executeSecurityEnhancement(String documentId) {
        WorkflowStepResult stepResult = new WorkflowStepResult();
        stepResult.stepName = 'Security Enhancement';
        stepResult.stepDescription = 'Apply security measures based on document classification';
        stepResult.startTime = DateTime.now();

        try {
            // Get document classification
            DocumentAnalysisRecord__c analysis = [
                SELECT Document_Type__c, Sensitivity_Level__c
                FROM DocumentAnalysisRecord__c
                WHERE Document__c = :documentId
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            // Apply appropriate security measures based on sensitivity
            String encryptionType = determineEncryptionType(analysis.Sensitivity_Level__c);
            AdvancedDocumentSecurity.enableEncryption(documentId, encryptionType);

            // Apply watermarking for sensitive documents
            if (analysis.Sensitivity_Level__c == 'HIGH' || 
                analysis.Sensitivity_Level__c == 'CRITICAL') {
                AdvancedDocumentSecurity.applyWatermarking(
                    documentId, 
                    'CONFIDENTIAL - ' + analysis.Sensitivity_Level__c
                );
            }

            // Enable tamper detection
            AdvancedDocumentSecurity.enableTamperDetection(documentId);

            // Set up access controls
            SecurityAccessController.configureDocumentAccess(
                documentId, 
                analysis.Document_Type__c
            );

            stepResult.endTime = DateTime.now();
            stepResult.status = 'SUCCESS';
            stepResult.output = 
                'Security measures applied: Encryption=' + encryptionType + 
                ', Classification=' + analysis.Sensitivity_Level__c;

        } catch (Exception e) {
            stepResult.endTime = DateTime.now();
            stepResult.status = 'FAILED';
            stepResult.errorMessage = e.getMessage();
            stepResult.output = 'Security enhancement failed';
        }
        return stepResult;
    }

    private static WorkflowStepResult executeComplianceValidation(
        String documentId, 
        Map<String, Object> workflowParameters
    ) {
        WorkflowStepResult stepResult = new WorkflowStepResult();
        stepResult.stepName = 'Compliance Validation';
        stepResult.stepDescription = 'Validate document against regulatory frameworks';
        stepResult.startTime = DateTime.now();

        try {
            // Determine applicable regulatory frameworks
            List<String> applicableFrameworks = 
                determineApplicableFrameworks(documentId, workflowParameters);

            // Execute compliance validation
            RegulatoryComplianceEngine.ComplianceValidationResult complianceResult = 
                RegulatoryComplianceEngine.validateDocumentCompliance(
                    documentId, 
                    applicableFrameworks
                );

            // Generate compliance report
            ComplianceReportGenerator.generateComplianceReport(documentId, complianceResult);

            stepResult.endTime = DateTime.now();
            stepResult.status = (complianceResult.overallStatus == 'NON_COMPLIANT') 
                ? 'WARNING' 
                : 'SUCCESS';
            stepResult.output = 
                'Compliance validation completed: ' + complianceResult.overallStatus + 
                ' (' + complianceResult.overallComplianceScore + '%)';
            stepResult.details = JSON.serialize(complianceResult);

        } catch (Exception e) {
            stepResult.endTime = DateTime.now();
            stepResult.status = 'FAILED';
            stepResult.errorMessage = e.getMessage();
            stepResult.output = 'Compliance validation failed';
        }
        return stepResult;
    }

    private static WorkflowStepResult executeRiskAssessment(String documentId) {
        WorkflowStepResult stepResult = new WorkflowStepResult();
        stepResult.stepName = 'Risk Assessment';
        stepResult.stepDescription = 'Assess and score document-related risks';
        stepResult.startTime = DateTime.now();

        try {
            // Perform comprehensive risk assessment
            RiskAssessmentResult riskResult = 
                DocumentRiskAssessor.assessDocumentRisks(documentId);

            // (Implementation continues...)

        } catch (Exception e) {
            stepResult.endTime = DateTime.now();
            stepResult.status = 'FAILED';
            stepResult.errorMessage = e.getMessage();
            stepResult.output = 'Risk assessment failed';
        }
        return stepResult;
    }

// ------------------- Risk Assessment -------------------
private static WorkflowStepResult executeRiskAssessment(String documentId) {
    WorkflowStepResult stepResult = new WorkflowStepResult();
    stepResult.stepName = 'Risk Assessment';
    stepResult.stepDescription = 'Assess and score document-related risks';
    stepResult.startTime = DateTime.now();

    try {
        // Perform comprehensive risk assessment
        RiskAssessmentResult riskResult = DocumentRiskAssessor.assessDocumentRisks(documentId);

        // Create risk assessment record
        DocumentRiskAssessment__c riskRecord = new DocumentRiskAssessment__c(
            Document__c               = documentId,
            Overall_Risk_Score__c     = riskResult.overallRiskScore,
            Risk_Level__c             = riskResult.riskLevel,
            Security_Risk_Score__c    = riskResult.securityRiskScore,
            Compliance_Risk_Score__c  = riskResult.complianceRiskScore,
            Operational_Risk_Score__c = riskResult.operationalRiskScore,
            Privacy_Risk_Score__c     = riskResult.privacyRiskScore,
            Assessment_Date__c        = DateTime.now(),
            Risk_Factors__c           = String.join(riskResult.riskFactors, ';'),
            Mitigation_Recommendations__c = String.join(riskResult.mitigationRecommendations, '\n'),
            Next_Review_Date__c       = Date.today().addDays(30),
            Assessment_Status__c      = 'COMPLETED'
        );
        insert riskRecord;

        stepResult.endTime = DateTime.now();
        stepResult.status  = (riskResult.riskLevel == 'HIGH') ? 'WARNING' : 'SUCCESS';
        stepResult.output  = 'Risk assessment completed: Level=' + riskResult.riskLevel +
                             ', Score=' + riskResult.overallRiskScore;
        stepResult.details = JSON.serialize(riskResult);

    } catch (Exception e) {
        stepResult.endTime = DateTime.now();
        stepResult.status = 'FAILED';
        stepResult.errorMessage = e.getMessage();
        stepResult.output = 'Risk assessment failed';
    }
    return stepResult;
}

// ------------------- Collaborative Setup -------------------
private static WorkflowStepResult executeCollaborativeSetup(
    String documentId, 
    Map<String, Object> workflowParameters
) {
    WorkflowStepResult stepResult = new WorkflowStepResult();
    stepResult.stepName = 'Collaborative Setup';
    stepResult.stepDescription = 'Configure document for collaborative editing';
    stepResult.startTime = DateTime.now();

    try {
        // Extract collaboration parameters
        List<String> collaboratorIds = (List<String>) workflowParameters.get('collaboratorIds');
        String collaborationType     = (String) workflowParameters.get('collaborationType');
        Boolean requiresApproval     = (Boolean) workflowParameters.get('requiresApproval');

        // Create collaborative session
        CollaborativeSession__c session = CollaborativeEditingManager.createCollaborativeSession(
            documentId, collaboratorIds, collaborationType, requiresApproval
        );

        // Configure collaborative permissions
        CollaborativePermissionManager.configureCollaborativePermissions(
            session.Id, collaboratorIds, workflowParameters
        );

        stepResult.endTime = DateTime.now();
        stepResult.status  = 'SUCCESS';
        stepResult.output  = 'Collaborative session created with ' + collaboratorIds.size() + ' collaborators';
        stepResult.details = 'Session ID: ' + session.Id;

    } catch (Exception e) {
        stepResult.endTime = DateTime.now();
        stepResult.status = 'FAILED';
        stepResult.errorMessage = e.getMessage();
        stepResult.output = 'Collaborative setup failed';
    }
    return stepResult;
}

// ------------------- Audit Trail Setup -------------------
private static WorkflowStepResult executeAuditTrailSetup(String documentId) {
    WorkflowStepResult stepResult = new WorkflowStepResult();
    stepResult.stepName = 'Audit Trail Setup';
    stepResult.stepDescription = 'Initialize comprehensive audit logging';
    stepResult.startTime = DateTime.now();

    try {
        // Initialize blockchain audit trail
        BlockchainAuditManager.initializeDocumentAuditChain(documentId);

        // Configure audit settings
        AuditConfiguration__c auditConfig = new AuditConfiguration__c(
            Document__c             = documentId,
            Audit_Level__c          = 'COMPREHENSIVE',
            Blockchain_Enabled__c   = true,
            Real_Time_Logging__c    = true,
            Compliance_Audit__c     = true,
            Security_Audit__c       = true,
            Access_Audit__c         = true,
            Modification_Audit__c   = true,
            Retention_Period_Days__c= 2555, // 7 years
            Archive_After_Days__c   = 365,
            Audit_Status__c         = 'ACTIVE'
        );
        insert auditConfig;

        stepResult.endTime = DateTime.now();
        stepResult.status  = 'SUCCESS';
        stepResult.output  = 'Audit trail initialized with blockchain support';

    } catch (Exception e) {
        stepResult.endTime = DateTime.now();
        stepResult.status = 'FAILED';
        stepResult.errorMessage = e.getMessage();
        stepResult.output = 'Audit trail setup failed';
    }
    return stepResult;
}

// ------------------- Monitoring Setup -------------------
private static WorkflowStepResult executeMonitoringSetup(String documentId) {
    WorkflowStepResult stepResult = new WorkflowStepResult();
    stepResult.stepName = 'Monitoring Setup';
    stepResult.stepDescription = 'Configure automated monitoring and alerts';
    stepResult.startTime = DateTime.now();

    try {
        // Set up document monitoring
        DocumentMonitoringConfig__c monitoringConfig = new DocumentMonitoringConfig__c(
            Document__c              = documentId,
            Monitor_Access__c        = true,
            Monitor_Modifications__c = true,
            Monitor_Downloads__c     = true,
            Monitor_Sharing__c       = true,
            Monitor_Compliance_Changes__c = true,
            Alert_Threshold_Minutes__c = 15,
            Anomaly_Detection_Enabled__c = true,
            Real_Time_Alerts__c      = true,
            Daily_Summary_Enabled__c = true,
            Weekly_Report_Enabled__c = true,
            Monitoring_Status__c     = 'ACTIVE'
        );
        insert monitoringConfig;

        // Initialize performance monitoring
        PerformanceMonitor.initializeDocumentMonitoring(documentId);

        stepResult.endTime = DateTime.now();
        stepResult.status  = 'SUCCESS';
        stepResult.output  = 'Monitoring configured with real-time alerts';

    } catch (Exception e) {
        stepResult.endTime = DateTime.now();
        stepResult.status = 'FAILED';
        stepResult.errorMessage = e.getMessage();
        stepResult.output = 'Monitoring setup failed';
    }
    return stepResult;
}

// ------------------- Notification Setup -------------------
private static WorkflowStepResult executeNotificationSetup(
    String documentId, 
    Map<String, Object> workflowParameters
) {
    WorkflowStepResult stepResult = new WorkflowStepResult();
    stepResult.stepName = 'Notification Setup';
    stepResult.stepDescription = 'Configure notification and alerting system';
    stepResult.startTime = DateTime.now();

    try {
        // Extract notification parameters
        List<String> notificationRecipients = 
            (List<String>) workflowParameters.get('notificationRecipients');
        String notificationFrequency = (String) workflowParameters.get('notificationFrequency');
        Boolean emergencyNotifications = (Boolean) workflowParameters.get('emergencyNotifications');

        // Configure notification settings
        NotificationConfiguration__c notificationConfig = new NotificationConfiguration__c(
            Document__c                = documentId,
            Email_Notifications__c     = true,
            SMS_Notifications__c       = emergencyNotifications,
            Slack_Notifications__c     = true,
            In_App_Notifications__c    = true,
            Notification_Frequency__c  = notificationFrequency,
            Emergency_Notifications__c = emergencyNotifications,
            Notification_Recipients__c = String.join(notificationRecipients, ';'),
            Document_Changes__c        = true,
            Compliance_Issues__c       = true,
            Security_Alerts__c         = true,
            Access_Violations__c       = true,
            Tamper_Detection__c        = true,
            Expiration_Warnings__c     = true,
            Workflow_Status__c         = true,
            Collaboration_Updates__c   = true,
            Notification_Status__c     = 'ACTIVE'
        );
        insert notificationConfig;

        // Set up notification templates
        NotificationTemplateManager.createDocumentNotificationTemplates(
            documentId, workflowParameters
        );

        stepResult.endTime = DateTime.now();
        stepResult.status  = 'SUCCESS';
        stepResult.output  = 'Notifications configured for ' + notificationRecipients.size() + ' recipients';

    } catch (Exception e) {
        stepResult.endTime = DateTime.now();
        stepResult.status = 'FAILED';
        stepResult.errorMessage = e.getMessage();
        stepResult.output = 'Notification setup failed';
    }
    return stepResult;
}

// ------------------- Utility Methods -------------------
private static String determineEncryptionType(String sensitivityLevel) {
    switch on sensitivityLevel {
        when 'CRITICAL' { return 'AES_256_GCM'; }
        when 'HIGH'     { return 'AES_256'; }
        when 'MEDIUM'   { return 'AES_128'; }
        when else       { return 'AES_128'; }
    }
}

private static List<String> determineApplicableFrameworks(
    String documentId, 
    Map<String, Object> workflowParameters
) {
    List<String> frameworks = new List<String>();

    // Get document type
    DocumentAnalysisRecord__c analysis = [
        SELECT Document_Type__c, Sensitivity_Level__c
        FROM DocumentAnalysisRecord__c
        WHERE Document__c = :documentId
        ORDER BY CreatedDate DESC
        LIMIT 1
    ];

    String documentType = analysis.Document_Type__c;
    String industry     = (String) workflowParameters.get('industry');
    String region       = (String) workflowParameters.get('region');

    // Add frameworks based on type/industry/region
    if (documentType.contains('FINANCIAL') || industry == 'FINANCIAL_SERVICES') {
        frameworks.add('SOX');
        frameworks.add('PCI_DSS');
    }
    if (documentType.contains('HEALTH') || industry == 'HEALTHCARE') {
        frameworks.add('HIPAA');
    }
    if (region == 'EU' || region == 'EUROPE') {
        frameworks.add('GDPR');
    }
    if (region == 'INDIA' || region == 'IN') {
        frameworks.add('UIDAI');
        frameworks.add('SEBI');
    }

    // Always add GDPR for sensitive docs
    if (analysis.Sensitivity_Level__c == 'HIGH' || analysis.Sensitivity_Level__c == 'CRITICAL') {
        if (!frameworks.contains('GDPR')) {
            frameworks.add('GDPR');
        }
    }
    return frameworks;
}

// private static String determineOverallWorkflowStatus(List<WorkflowStepResult> stepResults) {
//     Boolean hasFailure = false;
//     Boolean hasWarning = false;

//     for (WorkflowStepResult step : stepResults) {
//         if (step.status == 'FAILED') {
//             hasFailure = true;
//             break;
//         }
//         if (step.status == 'WARNING') {
//             hasWarning = true;
//         }
//     }

//     if (hasFailure) return 'FAILED';
//     if (hasWarning) return 'WARNING';
//     return 'SUCCESS';
// }
// else if (step.status == 'WARNING') {
//     hasWarning = true;
// }


// if (hasFailure) return 'FAILED';
// if (hasWarning) return 'COMPLETED_WITH_WARNINGS';
// return 'SUCCESS';
// }
private static String determineOverallWorkflowStatus(List<WorkflowStepResult> stepResults) {
    Boolean hasFailure = false;
    Boolean hasWarning = false;

    // Loop through all steps
    for (WorkflowStepResult step : stepResults) {
        if (step.status == 'FAILED') {
            hasFailure = true;
            break; // failure overrides everything
        }
        else if (step.status == 'WARNING') {
            hasWarning = true;
        }
    }

    // Final decision
    if (hasFailure) return 'FAILED';
    if (hasWarning) return 'COMPLETED_WITH_WARNINGS';
    return 'SUCCESS';
}

private static Decimal calculateSuccessRate(List<WorkflowStepResult> stepResults) {
    if (stepResults.isEmpty()) return 0;

    Integer successCount = 0;
    for (WorkflowStepResult step : stepResults) {
        if (step.status == 'SUCCESS') {
            successCount++;
        }
    }
    return (Decimal) successCount / stepResults.size() * 100;
}

private static void createWorkflowExecutionRecord(WorkflowExecutionResult result) {
    WorkflowExecution__c executionRecord = new WorkflowExecution__c(
        Document__c              = result.documentId,
        Start_Time__c            = result.startTime,
        End_Time__c              = result.endTime,
        Total_Execution_Time__c  = result.totalExecutionTime,
        Overall_Status__c        = result.overallStatus,
        Success_Rate__c          = result.successRate,
        Total_Steps__c           = result.workflowSteps.size(),
        Successful_Steps__c      = countSuccessfulSteps(result.workflowSteps),
        Failed_Steps__c          = countFailedSteps(result.workflowSteps),
        Warning_Steps__c         = countWarningSteps(result.workflowSteps),
        Error_Message__c         = result.errorMessage,
        Error_Details__c         = result.errorDetails,
        Execution_Summary__c     = generateExecutionSummary(result)
    );
    insert executionRecord;

    // Create detailed step records
    for (WorkflowStepResult step : result.workflowSteps) {
        createWorkflowStepRecord(executionRecord.Id, step);
    }
}

private static void createWorkflowStepRecord(String executionId, WorkflowStepResult step) {
    WorkflowStep__c stepRecord = new WorkflowStep__c(
        Workflow_Execution__c = executionId,
        Step_Name__c          = step.stepName,
        Step_Description__c   = step.stepDescription,
        Start_Time__c         = step.startTime,
        End_Time__c           = step.endTime,
        Execution_Time__c     = step.endTime.getTime() - step.startTime.getTime(),
        Status__c             = step.status,
        Output__c             = step.output,
        Error_Message__c      = step.errorMessage,
        Step_Details__c       = step.details,
        Step_Order__c         = getStepOrder(step.stepName)
    );
    insert stepRecord;
}

private static Integer countSuccessfulSteps(List<WorkflowStepResult> steps) {
    Integer count = 0;
    for (WorkflowStepResult step : steps) {
        if (step.status == 'SUCCESS') count++;
    }
    return count;
}

private static Integer countFailedSteps(List<WorkflowStepResult> steps) {
    Integer count = 0;
    for (WorkflowStepResult step : steps) {
        if (step.status == 'FAILED') count++;
    }
    return count;
}

private static Integer countWarningSteps(List<WorkflowStepResult> steps) {
    Integer count = 0;
    for (WorkflowStepResult step : steps) {
        if (step.status == 'WARNING') count++;
    }
    return count;
}

private static String generateExecutionSummary(WorkflowExecutionResult result) {
    String summary = 'Workflow execution completed with ' + result.overallStatus + ' status.\n';
    summary += 'Total execution time: ' + result.totalExecutionTime + 'ms\n';
    summary += 'Success rate: ' + result.successRate + '%\n';
    summary += 'Steps executed: ' + result.workflowSteps.size() + '\n';

    if (result.errorMessage != null) {
        summary += 'Error: ' + result.errorMessage;
    }
    return summary;
}

private static Integer getStepOrder(String stepName) {
    Map<String, Integer> stepOrder = new Map<String, Integer>{
        'Document Analysis'     => 1,
        'Security Enhancement'  => 2,
        'Compliance Validation' => 3,
        'Risk Assessment'       => 4,
        'Collaborative Setup'   => 5,
        'Audit Trail Setup'     => 6,
        'Monitoring Setup'      => 7,
        'Notification Setup'    => 8
    };
    return stepOrder.get(stepName);
}

private static void logWorkflowError(String documentId, Exception e) {
    WorkflowError__c errorRecord = new WorkflowError__c(
        Document__c             = documentId,
        Error_Message__c        = e.getMessage(),
        Error_Type__c           = e.getTypeName(),
        Stack_Trace__c          = e.getStackTraceString(),
        Error_Time__c           = DateTime.now(),
        Resolution_Status__c    = 'UNRESOLVED',
        Severity__c             = 'HIGH',
        Requires_Investigation__c = true
    );
    insert errorRecord;
}

// Wrapper classes for workflow results
public class WorkflowExecutionResult {
    public String documentId;
    public DateTime startTime;
    public DateTime endTime;
    public Long totalExecutionTime;
    public List<WorkflowStepResult> workflowSteps;
    public String overallStatus;
    public Decimal successRate;
    public String errorMessage;
    public String errorDetails;

    public WorkflowExecutionResult() {
        this.workflowSteps = new List<WorkflowStepResult>();
    }
}

// public class WorkflowStepResult {
//     public String stepName;
//     public String stepDescription;
//     public DateTime startTime;
//     public DateTime endTime;
//     public String status;
//     public String output;
//     public String errorMessage;
//     public String details;
// }
// switch on documentType {
//     case 'CONFIDENTIAL':
//         sensitivityScore += 40;
//         break;

//     case 'CONTRACT':
//         sensitivityScore += 20;
//         break;

//     case 'LEGAL':
//         sensitivityScore += 25;
//         break;

//     case 'BIOMETRIC':
//         sensitivityScore += 45;
//         break;

//     case 'INTELLECTUAL_PROPERTY':
//         sensitivityScore += 35;
//         break;

//     default:
//         sensitivityScore += 5;
//         break;
// }
//         // Additional scoring based on document content analysis
//         if (analysis.Content_Analysis__c != null) {
//             Map<String, Object> contentAnalysis = (Map<String, Object>) JSON.deserializeUntyped(analysis.Content_Analysis__c);
//             List<String> entities = (List<String>) contentAnalysis.get('extractedEntities');
            
//             if (entities != null) {
//                 for (String entity : entities) {
//                     if (entity.startsWith('EMAIL:') || entity.startsWith('SSN:') || entity.startsWith('PHONE:')) {
//                         sensitivityScore += 15;
//                     }
//                 }
//             }
//         }

//         // Classify sensitivity level
//         if (sensitivityScore >= 80) {
//             return 'CRITICAL';
//         } else if (sensitivityScore >= 60) {
//             return 'HIGH';
//         } else if (sensitivityScore >= 30) {
//             return 'MEDIUM';
//         } else {
//             return 'LOW';
//         }
        
//     } catch (Exception e) {
//         return 'UNKNOWN';
//     }
// }
// }
private static String determineOverallWorkflowStatus(List<WorkflowStepResult> stepResults) {
    Boolean hasFailure = false;
    Boolean hasWarning = false;

    // Loop through all steps
    for (WorkflowStepResult step : stepResults) {
        switch on step.status {
            when 'FAILED' {
                hasFailure = true;
                break; // failure overrides everything
            }
            when 'WARNING' {
                hasWarning = true;
            }
            when else {
                // SUCCESS or any other status → ignore
            }
        }
    }

    // Final decision
    if (hasFailure) return 'FAILED';
    if (hasWarning) return 'COMPLETED_WITH_WARNINGS';
    return 'SUCCESS';
}

public class DocumentRiskAssessor {
    public static RiskAssessmentResult assessDocumentRisks(String documentId) {
        RiskAssessmentResult result = new RiskAssessmentResult();
        
        try {
            // Get document analysis data
            DocumentAnalysisRecord__c analysis = [
                SELECT Document_Type__c, Sensitivity_Level__c, Key_Topics__c
                FROM DocumentAnalysisRecord__c 
                WHERE Document__c = :documentId 
                ORDER BY CreatedDate DESC 
                LIMIT 1
            ];
            
            // Assess different risk categories
            result.securityRiskScore = assessSecurityRisk(documentId, analysis);
            result.complianceRiskScore = assessComplianceRisk(documentId, analysis);
            result.operationalRiskScore = assessOperationalRisk(documentId, analysis);
            result.privacyRiskScore = assessPrivacyRisk(documentId, analysis);
            result.reputationalRiskScore = assessReputationalRisk(documentId, analysis);
            result.financialRiskScore = assessFinancialRisk(documentId, analysis);
            
            // Calculate overall risk score
            result.overallRiskScore = calculateOverallRiskScore(result);
            result.riskLevel = determineRiskLevel(result.overallRiskScore);
            
            // Identify risk factors
            result.riskFactors = identifyRiskFactors(documentId, analysis, result);
            
            // Generate mitigation recommendations
            result.mitigationRecommendations = generateMitigationRecommendations(result);
            
        } catch (Exception e) {
            result.assessmentError = e.getMessage();
            result.overallRiskScore = 100; // Maximum risk if assessment fails
            result.riskLevel = 'CRITICAL';
        }
        
        return result;
    }
    
    private static Decimal assessSecurityRisk(String documentId, DocumentAnalysisRecord__c analysis) {
        Decimal riskScore = 0;
        
        // Check encryption status
        DocumentSecurityConfig__c securityConfig = getSecurityConfig(documentId);
        if (securityConfig == null || !securityConfig.Encryption_Enabled__c) {
            riskScore += 30;
        }
        
        // Check access controls
        List<DocumentAccessControl__c> accessControls = [
            SELECT Id FROM DocumentAccessControl__c 
            WHERE Document__c = :documentId AND Status__c = 'ACTIVE'
        ];
        if (accessControls.isEmpty()) {
            riskScore += 25;
        }
        
        // Check tamper detection
        List<TamperDetectionLog__c> tamperLogs = [
            SELECT Id FROM TamperDetectionLog__c 
            WHERE Document__c = :documentId AND Tamper_Detected__c = true
        ];
        if (!tamperLogs.isEmpty()) {
            riskScore += 40;
        }
        
        // Sensitivity-based risk adjustment
        String sensitivity = analysis.Sensitivity_Level__c;
        if (sensitivity == 'CRITICAL') {
            riskScore *= 1.5;
        } else if (sensitivity == 'HIGH') {
            riskScore *= 1.3;
        }
        
        return Math.min(100, riskScore);
    }
    
    private static Decimal assessComplianceRisk(String documentId, DocumentAnalysisRecord__c analysis) {
        Decimal riskScore = 0;
        
        // Check compliance validation status
        List<ComplianceValidationRecord__c> complianceRecords = [
            SELECT Overall_Status__c, Overall_Compliance_Score__c 
            FROM ComplianceValidationRecord__c 
            WHERE Document__c = :documentId 
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
        
        if (complianceRecords.isEmpty()) {
            riskScore += 50; // No compliance validation performed
        } else {
            ComplianceValidationRecord__c record = complianceRecords[0];
            if (record.Overall_Status__c == 'NON_COMPLIANT') {
                riskScore += 60;
            } else if (record.Overall_Status__c == 'PARTIALLY_COMPLIANT') {
                riskScore += 30;
            }
            
            // Adjust based on compliance score
            if (record.Overall_Compliance_Score__c < 50) {
                riskScore += 40;
            } else if (record.Overall_Compliance_Score__c < 75) {
                riskScore += 20;
            }
        }
        
        // Check for regulatory requirement changes
        List<RegulatoryUpdate__c> recentUpdates = [
            SELECT Id FROM RegulatoryUpdate__c 
            WHERE Effective_Date__c >= :Date.today().addDays(-30)
            AND Impact_Level__c = 'HIGH'
        ];
        if (!recentUpdates.isEmpty()) {
            riskScore += 15;
        }
        
        return Math.min(100, riskScore);
    }
    
    // private static Decimal assessOperationalRisk(String documentId, DocumentAnalysisRecord__c analysis) {
    //     Decimal riskScore = 0;
        
    //     // Check document availability
    //     List<SystemDowntime__c> downtimeRecords = [
    //         SELECT Id FROM SystemDowntime__c 
    //         WHERE CreatedDate >= :DateTime.now().addDays(-7)
    //         AND Impact__c INCLUDES 'DOCUMENT_ACCESS'
    //     ];
    //     if (!downtimeRecords.isEmpty()) {
    //         riskScore += 25;
    //     }
        
    //     // Check backup status
    //     List<DocumentBackup__c> backupRecords = [
    //         SELECT Backup_Status__c FROM DocumentBackup__c 
    //         WHERE Document__c = :documentId 
    //         ORDER BY CreatedDate DESC 
    //         LIMIT 1
    //     ];
    //     if (backupRecords.isEmpty() || backupRecords[0].Backup_Status__c != 'SUCCESS') {
    //         riskScore += 30;
    //     }
        
    //     // Check version control
    //     List<ContentVersion> versions = [
    //         SELECT Id FROM ContentVersion 
    //         WHERE ContentDocumentId = :documentId
    //     ];
    //     if (versions.size() > 10) {
    //         riskScore += 15; // Too many versions might indicate chaos
    //     }
        
    //     // Check collaborative access
    //     List<CollaborativeSession__c> activeSessions = [
    //         SELECT Id FROM CollaborativeSession__c 
    //         WHERE Document__c = :documentId 
    //         AND Status__c = 'ACTIVE'
    //     ];
    //     if (activeSessions.size() > 5) {
    //         riskScore += 20; // Too many concurrent collaborators
    //     }
        
    //     return Math.min(100, riskScore);
    // }
    private static Decimal assessOperationalRisk(String documentId, DocumentAnalysisRecord__c analysis) {
    Decimal riskScore = 0;
    
    // Check document availability (downtime in last 7 days)
    List<SystemDowntime__c> downtimeRecords = [
        SELECT Id 
        FROM SystemDowntime__c 
        WHERE CreatedDate >= :DateTime.now().addDays(-7)
        AND Impact__c = 'DOCUMENT_ACCESS'   // or INCLUDES('DOCUMENT_ACCESS') if multi-picklist
    ];
    if (!downtimeRecords.isEmpty()) {
        riskScore += 25;
    }
    
    // Check backup status (latest record)
    List<DocumentBackup__c> backupRecords = [
        SELECT Backup_Status__c 
        FROM DocumentBackup__c 
        WHERE Document__c = :documentId 
        ORDER BY CreatedDate DESC 
        LIMIT 1
    ];
    if (backupRecords.isEmpty() || backupRecords[0].Backup_Status__c != 'SUCCESS') {
        riskScore += 30;
    }
    
    // Check version control
    List<ContentVersion> versions = [
        SELECT Id 
        FROM ContentVersion 
        WHERE ContentDocumentId = :documentId
    ];
    if (versions.size() > 10) {
        riskScore += 15; // Too many versions might indicate chaos
    }
    
    // Check collaborative access
    List<CollaborativeSession__c> activeSessions = [
        SELECT Id 
        FROM CollaborativeSession__c 
        WHERE Document__c = :documentId 
        AND Status__c = 'ACTIVE'
    ];
    if (activeSessions.size() > 5) {
        riskScore += 20; // Too many concurrent collaborators
    }
    
    return Math.min(100, riskScore);
}

    private static Decimal assessPrivacyRisk(String documentId, DocumentAnalysisRecord__c analysis) {
        Decimal riskScore = 0;
        
        // Check for personal data
        List<String> topics = analysis.Key_Topics__c != null ? 
            analysis.Key_Topics__c.split(';') : new List<String>();
        
        Boolean hasPersonalData = topics.contains('PERSONAL_DATA');
        Boolean hasBiometricData = topics.contains('BIOMETRIC');
        Boolean hasFinancialData = topics.contains('FINANCIAL');
        Boolean hasMedicalData = topics.contains('MEDICAL');
        
        if (hasPersonalData) riskScore += 25;
        if (hasBiometricData) riskScore += 35;
        if (hasFinancialData) riskScore += 30;
        if (hasMedicalData) riskScore += 40;
        
        // Check data retention compliance
        List<DocumentRetentionApplication__c> retentionApps = [
            SELECT Status__c FROM DocumentRetentionApplication__c 
            WHERE Document__c = :documentId
        ];
        if (retentionApps.isEmpty()) {
            riskScore += 25;
        }
        
        // Check consent management
        List<ConsentManagement__c> consents = [
            SELECT Consent_Status__c FROM ConsentManagement__c 
            WHERE Document__c = :documentId 
            AND Data_Subject_Type__c = 'INDIVIDUAL'
        ];
        if (hasPersonalData && consents.isEmpty()) {
            riskScore += 30;
        }
        
        // Check data sharing restrictions
        List<DataSharingRestriction__c> restrictions = [
            SELECT Id FROM DataSharingRestriction__c 
            WHERE Document__c = :documentId 
            AND Status__c = 'ACTIVE'
        ];
        if (hasPersonalData && restrictions.isEmpty()) {
            riskScore += 20;
        }
        
        return Math.min(100, riskScore);
    }
    
    private static Decimal assessReputationalRisk(String documentId, DocumentAnalysisRecord__c analysis) {
        Decimal riskScore = 0;
        
        // Check document classification
        String docType = analysis.Document_Type__c;
        if (docType == 'LEGAL_CONTRACT' || docType == 'POLICY_DOCUMENT') {
            riskScore += 20; // Higher reputational risk for legal/policy docs
        }
        
        // Check public access
        List<ContentDocumentLink> publicLinks = [
            SELECT Visibility FROM ContentDocumentLink 
            WHERE ContentDocumentId = :documentId 
            AND Visibility = 'AllUsers'
        ];
        if (!publicLinks.isEmpty() && analysis.Sensitivity_Level__c != 'LOW') {
            riskScore += 40;
        }
        
        // Check recent security incidents
        List<SecurityIncident__c> incidents = [
            SELECT Severity__c FROM SecurityIncident__c 
            WHERE Document__c = :documentId 
            AND CreatedDate >= :DateTime.now().addDays(-30)
        ];
        for (SecurityIncident__c incident : incidents) {
            if (incident.Severity__c == 'HIGH') {
                riskScore += 30;
            } else if (incident.Severity__c == 'MEDIUM') {
                riskScore += 15;
            }
        }
        
        // Check media attention indicators
        List<MediaMention__c> mentions = [
            SELECT Sentiment__c FROM MediaMention__c 
            WHERE Related_Document__c = :documentId 
            AND CreatedDate >= :DateTime.now().addDays(-90)
        ];
        for (MediaMention__c mention : mentions) {
            if (mention.Sentiment__c == 'NEGATIVE') {
                riskScore += 25;
            }
        }
        
        return Math.min(100, riskScore);
    }
    
    private static Decimal assessFinancialRisk(String documentId, DocumentAnalysisRecord__c analysis) {
        Decimal riskScore = 0;
        
        // Check document type
        String docType = analysis.Document_Type__c;
        if (docType == 'FINANCIAL_DOCUMENT' || docType == 'LEGAL_CONTRACT') {
            riskScore += 25;
        }
        
        // Check potential liability
        List<LiabilityAssessment__c> liabilities = [
            SELECT Estimated_Cost__c FROM LiabilityAssessment__c 
            WHERE Document__c = :documentId 
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
        if (!liabilities.isEmpty() && liabilities[0].Estimated_Cost__c > 100000) {
            riskScore += 35;
        }
        
        // Check compliance penalties
        List<ComplianceValidationRecord__c> complianceRecords = [
            SELECT Overall_Status__c FROM ComplianceValidationRecord__c 
            WHERE Document__c = :documentId 
            AND Overall_Status__c = 'NON_COMPLIANT'
        ];
        if (!complianceRecords.isEmpty()) {
            riskScore += 30; // Non-compliance can lead to fines
        }
        
        // Check insurance coverage
        List<InsuranceCoverage__c> coverage = [
            SELECT Coverage_Amount__c FROM InsuranceCoverage__c 
            WHERE Document__c = :documentId 
            AND Status__c = 'ACTIVE'
        ];
        if (coverage.isEmpty()) {
            riskScore += 20;
        }
        
        return Math.min(100, riskScore);
    }
    
    private static Decimal calculateOverallRiskScore(RiskAssessmentResult result) {
        // Weighted average of risk categories
        Map<String, Decimal> weights = new Map<String, Decimal>{
            'security' => 0.25,
            'compliance' => 0.20,
            'privacy' => 0.20,
            'operational' => 0.15,
            'reputational' => 0.10,
            'financial' => 0.10
        };
        
        Decimal weightedScore = 
            (result.securityRiskScore * weights.get('security')) +
            (result.complianceRiskScore * weights.get('compliance')) +
            (result.privacyRiskScore * weights.get('privacy')) +
            (result.operationalRiskScore * weights.get('operational')) +
            (result.reputationalRiskScore * weights.get('reputational')) +
            (result.financialRiskScore * weights.get('financial'));
            
        return Math.round(weightedScore);
    }
    
    private static String determineRiskLevel(Decimal overallScore) {
        if (overallScore >= 80) return 'CRITICAL';
        if (overallScore >= 60) return 'HIGH';
        if (overallScore >= 40) return 'MEDIUM';
        if (overallScore >= 20) return 'LOW';
        return 'MINIMAL';
    }
    
//     private static List<String> identifyRiskFactors(String documentId, DocumentAnalysisRecord__c analysis, RiskAssessmentResult result) {
//         List<String> factors = new List<String>();
        
//         if (result.securityRiskScore > 50) {
//             factors.add('Inadequate security controls');
//         }
//         if (result.complianceRiskScore > 50) {
//             factors.add('Compliance violations detected');
//         }
//         if (result.privacyRiskScore > 50) {
//             factors.add('Privacy protection deficiencies');
//         }
//         if (result.operationalRiskScore > 50) {
//             factors.add('Operational vulnerabilities');
//         }
//         case 'CONFIDENTIAL':
//                     sensitivityScore += 40;
//                     break;
//                 case 'CONTRACT':
//                     sensitivityScore += 20;
//                     break;
//                 case 'LEGAL':
//                     sensitivityScore += 25;
//                     break;
//                 case 'BIOMETRIC':
//                     sensitivityScore += 45;
//                     break;
//                 case 'INTELLECTUAL_PROPERTY':
//                     sensitivityScore += 35;
//                     break;
//                 default:
//                     sensitivityScore += 5;
//                     break;
//             }
//         }

//         // Additional scoring based on document content analysis
//         if (analysis.Content_Analysis__c != null) {
//             Map<String, Object> contentAnalysis = (Map<String, Object>) JSON.deserializeUntyped(analysis.Content_Analysis__c);
//             List<String> entities = (List<String>) contentAnalysis.get('extractedEntities');
            
//             if (entities != null) {
//                 for (String entity : entities) {
//                     if (entity.startsWith('EMAIL:') || entity.startsWith('SSN:') || entity.startsWith('PHONE:')) {
//                         sensitivityScore += 15;
//                     }
//                 }
//             }
//         }

//         // Classify sensitivity level
//         if (sensitivityScore >= 80) {
//             return 'CRITICAL';
//         } else if (sensitivityScore >= 60) {
//             return 'HIGH';
//         } else if (sensitivityScore >= 30) {
//             return 'MEDIUM';
//         } else {
//             return 'LOW';
//         }
        
//     } catch (Exception e) {
//         return 'UNKNOWN';
//     }
// }

private static RiskAnalysisResult analyzeDocumentRisk(
    String documentId,
    DocumentAnalysisRecord__c analysis,
    RiskAssessmentResult result
) {
    RiskAnalysisResult output = new RiskAnalysisResult();
    output.factors = new List<String>();
    Integer sensitivityScore = 0;

    try {
        // ---- Risk Factors ----
        if (result.securityRiskScore > 50) {
            output.factors.add('Inadequate security controls');
        }
        if (result.complianceRiskScore > 50) {
            output.factors.add('Compliance violations detected');
        }
        if (result.privacyRiskScore > 50) {
            output.factors.add('Privacy protection deficiencies');
        }
        if (result.operationalRiskScore > 50) {
            output.factors.add('Operational vulnerabilities');
        }

        // ---- Sensitivity Scoring ----
        switch on analysis.Document_Type__c {
            when 'CONFIDENTIAL' {
                sensitivityScore += 40;
            }
            when 'CONTRACT' {
                sensitivityScore += 20;
            }
            when 'LEGAL' {
                sensitivityScore += 25;
            }
            when 'BIOMETRIC' {
                sensitivityScore += 45;
            }
            when 'INTELLECTUAL_PROPERTY' {
                sensitivityScore += 35;
            }
            when else {
                sensitivityScore += 5;
            }
        }

        // Additional scoring based on content analysis JSON
        if (analysis.Content_Analysis__c != null) {
            Map<String, Object> contentAnalysis = 
                (Map<String, Object>) JSON.deserializeUntyped(analysis.Content_Analysis__c);

            List<String> entities = (List<String>) contentAnalysis.get('extractedEntities');
            if (entities != null) {
                for (String entity : entities) {
                    if (entity.startsWith('EMAIL:') || entity.startsWith('SSN:') || entity.startsWith('PHONE:')) {
                        sensitivityScore += 15;
                    }
                }
            }
        }

        // Classify sensitivity level
        if (sensitivityScore >= 80) {
            output.sensitivityLevel = 'CRITICAL';
        } else if (sensitivityScore >= 60) {
            output.sensitivityLevel = 'HIGH';
        } else if (sensitivityScore >= 30) {
            output.sensitivityLevel = 'MEDIUM';
        } else {
            output.sensitivityLevel = 'LOW';
        }

    } catch (Exception e) {
        output.sensitivityLevel = 'UNKNOWN';
    }

    return output;
}
}
}