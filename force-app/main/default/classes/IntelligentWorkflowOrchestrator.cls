public with sharing class IntelligentWorkflowOrchestrator {

    // Wrapper class for individual workflow step results
    public class WorkflowStepResult {
        @AuraEnabled public String stepName;
        @AuraEnabled public String stepDescription;
        @AuraEnabled public DateTime startTime;
        @AuraEnabled public DateTime endTime;
        @AuraEnabled public String status; // e.g., 'SUCCESS', 'WARNING', 'FAILED'
        @AuraEnabled public String output;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String details;

        public WorkflowStepResult() {
            this.status = 'PENDING';
        }
    }

    // Wrapper class for the entire workflow execution result
    public class WorkflowExecutionResult {
        @AuraEnabled public String documentId;
        @AuraEnabled public DateTime startTime;
        @AuraEnabled public DateTime endTime;
        @AuraEnabled public Long totalExecutionTime;
        @AuraEnabled public List<WorkflowStepResult> workflowSteps;
        @AuraEnabled public String overallStatus;
        @AuraEnabled public Decimal successRate;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String errorDetails;
        @AuraEnabled public String executionSummary;

        public WorkflowExecutionResult() {
            this.workflowSteps = new List<WorkflowStepResult>();
            this.overallStatus = 'UNKNOWN';
            this.successRate = 0;
        }
    }
    
    // Wrapper class for risk assessment results (stub)
    public class RiskAssessmentResult {
        public Decimal overallRiskScore = 0;
        public String riskLevel = 'UNKNOWN';
        public List<String> riskFactors = new List<String>();
        public List<String> mitigationRecommendations = new List<String>();
    }

    // Main orchestration method for the entire document lifecycle
    public static WorkflowExecutionResult executeIntelligentWorkflow(String documentId, Map<String, Object> workflowParameters) {
        WorkflowExecutionResult result = new WorkflowExecutionResult();
        result.documentId = documentId;
        result.startTime = DateTime.now();

        try {
            result.workflowSteps.add(executeDocumentAnalysis(documentId));
            result.workflowSteps.add(executeSecurityEnhancement(documentId));
            result.workflowSteps.add(executeComplianceValidation(documentId, workflowParameters));
            result.workflowSteps.add(executeRiskAssessment(documentId));
            result.workflowSteps.add(executeCollaborativeSetup(documentId, workflowParameters));
            result.workflowSteps.add(executeAuditTrailSetup(documentId));
            result.workflowSteps.add(executeMonitoringSetup(documentId));
            result.workflowSteps.add(executeNotificationSetup(documentId, workflowParameters));
        
        } catch (Exception e) {
            // A major, unexpected failure in the orchestration logic itself
            result.overallStatus = 'FAILED';
            result.errorMessage = 'Orchestration failed unexpectedly: ' + e.getMessage();
            result.errorDetails = e.getStackTraceString();
        } finally {
            // This block always runs, ensuring the result is finalized
            result.endTime = DateTime.now();
            if (result.startTime != null) {
                result.totalExecutionTime = result.endTime.getTime() - result.startTime.getTime();
            }
            result.overallStatus = determineOverallWorkflowStatus(result.workflowSteps);
            result.successRate = calculateSuccessRate(result.workflowSteps);
            result.executionSummary = generateExecutionSummary(result);
        }

        return result;
    }

    // Step 1: Document Analysis (Stub)
    private static WorkflowStepResult executeDocumentAnalysis(String documentId) {
        WorkflowStepResult step = new WorkflowStepResult();
        step.stepName = 'Document Analysis';
        step.stepDescription = 'Analyze document content, structure, and metadata';
        step.startTime = DateTime.now();
        try {
            // In a real implementation, you would call an external service or another Apex class here.
            Map<String, Object> analysis = new Map<String, Object>{
                'keyTopics' => new List<String>{'topicA', 'topicB'},
                'language' => 'en'
            };
            step.status = 'SUCCESS';
            step.output = 'Document analysis completed successfully (stub).';
            step.details = JSON.serialize(analysis);
        } catch (Exception e) {
            step.status = 'FAILED';
            step.errorMessage = e.getMessage();
            step.output = 'Document analysis failed.';
        }
        step.endTime = DateTime.now();
        return step;
    }

    // Step 2: Security Enhancement (Stub)
    private static WorkflowStepResult executeSecurityEnhancement(String documentId) {
        WorkflowStepResult step = new WorkflowStepResult();
        step.stepName = 'Security Enhancement';
        step.stepDescription = 'Apply security measures based on document classification';
        step.startTime = DateTime.now();
        try {
            step.status = 'SUCCESS';
            step.output = 'Security measures applied successfully (stub).';
            step.details = JSON.serialize(new Map<String, Object>{'encryption' => 'AES-256', 'watermark' => true});
        } catch (Exception e) {
            step.status = 'FAILED';
            step.errorMessage = e.getMessage();
            step.output = 'Security enhancement failed.';
        }
        step.endTime = DateTime.now();
        return step;
    }
    
    // Step 3: Compliance Validation (Stub)
    private static WorkflowStepResult executeComplianceValidation(String documentId, Map<String, Object> workflowParameters) {
        WorkflowStepResult step = new WorkflowStepResult();
        step.stepName = 'Compliance Validation';
        step.stepDescription = 'Validate document against regulatory frameworks';
        step.startTime = DateTime.now();
        try {
            List<String> frameworks = new List<String>{'GDPR', 'HIPAA'};
            Map<String, Object> complianceResult = new Map<String, Object>{
                'overallStatus' => 'COMPLIANT',
                'overallScore' => 95.5,
                'frameworks' => frameworks
            };
            step.status = 'SUCCESS';
            step.output = 'Compliance validation completed with status: COMPLIANT (stub).';
            step.details = JSON.serialize(complianceResult);
        } catch (Exception e) {
            step.status = 'FAILED';
            step.errorMessage = e.getMessage();
            step.output = 'Compliance validation failed.';
        }
        step.endTime = DateTime.now();
        return step;
    }

    // Step 4: Risk Assessment (Stub)
    private static WorkflowStepResult executeRiskAssessment(String documentId) {
        WorkflowStepResult step = new WorkflowStepResult();
        step.stepName = 'Risk Assessment';
        step.stepDescription = 'Assess and score document-related risks';
        step.startTime = DateTime.now();
        try {
            RiskAssessmentResult risk = new RiskAssessmentResult();
            risk.overallRiskScore = 30;
            risk.riskLevel = 'LOW';
            risk.riskFactors.add('No significant factors detected.');
            step.status = 'SUCCESS';
            step.output = 'Risk assessment completed: LOW (stub).';
            step.details = JSON.serialize(risk);
        } catch (Exception e) {
            step.status = 'FAILED';
            step.errorMessage = e.getMessage();
            step.output = 'Risk assessment failed.';
        }
        step.endTime = DateTime.now();
        return step;
    }

    // Step 5: Collaborative Setup (Stub)
    private static WorkflowStepResult executeCollaborativeSetup(String documentId, Map<String, Object> workflowParameters) {
        WorkflowStepResult step = new WorkflowStepResult();
        step.stepName = 'Collaborative Setup';
        step.stepDescription = 'Configure document for collaborative editing';
        step.startTime = DateTime.now();
        try {
            Integer collaborators = 0;
            if (workflowParameters != null && workflowParameters.containsKey('collaboratorIds')) {
                Object rawIds = workflowParameters.get('collaboratorIds');
                if (rawIds instanceof List<Object>) {
                    collaborators = ((List<Object>)rawIds).size();
                }
            }
            step.status = 'SUCCESS';
            step.output = 'Collaborative session configured for ' + collaborators + ' users (stub).';
        } catch (Exception e) {
            step.status = 'FAILED';
            step.errorMessage = e.getMessage();
            step.output = 'Collaborative setup failed.';
        }
        step.endTime = DateTime.now();
        return step;
    }
    
    // Step 6: Audit Trail Setup (Stub)
    private static WorkflowStepResult executeAuditTrailSetup(String documentId) {
        WorkflowStepResult step = new WorkflowStepResult();
        step.stepName = 'Audit Trail Setup';
        step.stepDescription = 'Initialize comprehensive audit logging';
        step.startTime = DateTime.now();
        try {
            step.status = 'SUCCESS';
            step.output = 'Audit trail initialized successfully (stub).';
            step.details = 'Blockchain integration: disabled.';
        } catch (Exception e) {
            step.status = 'FAILED';
            step.errorMessage = e.getMessage();
            step.output = 'Audit trail setup failed.';
        }
        step.endTime = DateTime.now();
        return step;
    }

    // Step 7: Monitoring Setup (Stub)
    private static WorkflowStepResult executeMonitoringSetup(String documentId) {
        WorkflowStepResult step = new WorkflowStepResult();
        step.stepName = 'Monitoring Setup';
        step.stepDescription = 'Configure automated monitoring and alerts';
        step.startTime = DateTime.now();
        try {
            step.status = 'SUCCESS';
            step.output = 'Monitoring configured with real-time alerts (stub).';
        } catch (Exception e) {
            step.status = 'FAILED';
            step.errorMessage = e.getMessage();
            step.output = 'Monitoring setup failed.';
        }
        step.endTime = DateTime.now();
        return step;
    }

    // Step 8: Notification Setup (Stub)
    private static WorkflowStepResult executeNotificationSetup(String documentId, Map<String, Object> workflowParameters) {
        WorkflowStepResult step = new WorkflowStepResult();
        step.stepName = 'Notification Setup';
        step.stepDescription = 'Configure notification and alerting system';
        step.startTime = DateTime.now();
        try {
            Integer recipients = 0;
            if (workflowParameters != null && workflowParameters.containsKey('notificationRecipients')) {
                Object rawRecipients = workflowParameters.get('notificationRecipients');
                if (rawRecipients instanceof List<Object>) {
                    recipients = ((List<Object>)rawRecipients).size();
                }
            }
            step.status = 'SUCCESS';
            step.output = 'Notifications configured for ' + recipients + ' recipients (stub).';
        } catch (Exception e) {
            step.status = 'FAILED';
            step.errorMessage = e.getMessage();
            step.output = 'Notification setup failed.';
        }
        step.endTime = DateTime.now();
        return step;
    }

    // ----- Private Utility Methods -----
    
    // Determines the final status of the entire workflow based on its steps
    private static String determineOverallWorkflowStatus(List<WorkflowStepResult> stepResults) {
        if (stepResults == null || stepResults.isEmpty()) {
            return 'INCOMPLETE';
        }
        Boolean hasFailure = false;
        Boolean hasWarning = false;
        for (WorkflowStepResult step : stepResults) {
            if (step != null) {
                if ('FAILED'.equals(step.status)) {
                    hasFailure = true;
                    break; 
                } else if ('WARNING'.equals(step.status)) {
                    hasWarning = true;
                }
            }
        }
        if (hasFailure) return 'FAILED';
        if (hasWarning) return 'COMPLETED_WITH_WARNINGS';
        return 'SUCCESS';
    }

    // Calculates the percentage of successful steps
    private static Decimal calculateSuccessRate(List<WorkflowStepResult> stepResults) {
        if (stepResults == null || stepResults.isEmpty()) {
            return 0;
        }
        Integer successCount = 0;
        for (WorkflowStepResult step : stepResults) {
            if (step != null && 'SUCCESS'.equals(step.status)) {
                successCount++;
            }
        }
        Decimal rate = (Decimal.valueOf(successCount).divide(stepResults.size(), 4)) * 100;
        return rate.setScale(2, RoundingMode.HALF_UP);
    }
    
    // Generates a human-readable summary of the execution
    private static String generateExecutionSummary(WorkflowExecutionResult result) {
        if (result == null) return 'Result is null.';
        
        String summary = 'Workflow execution completed with status: ' + result.overallStatus + '.\n';
        summary += 'Total execution time: ' + result.totalExecutionTime + 'ms.\n';
        summary += 'Success rate: ' + result.successRate + '%.\n';
        summary += 'Steps executed: ' + result.workflowSteps.size() + '.\n';
        if (String.isNotBlank(result.errorMessage)) {
            summary += 'Error: ' + result.errorMessage;
        }
        return summary;
    }
    
    // Returns a numeric order for workflow steps
    private static Integer getStepOrder(String stepName) {
        Map<String, Integer> stepOrder = new Map<String, Integer>{
            'Document Analysis' => 1,
            'Security Enhancement' => 2,
            'Compliance Validation' => 3,
            'Risk Assessment' => 4,
            'Collaborative Setup' => 5,
            'Audit Trail Setup' => 6,
            'Monitoring Setup' => 7,
            'Notification Setup' => 8
        };
        return stepOrder.containsKey(stepName) ? stepOrder.get(stepName) : 99;
    }
}