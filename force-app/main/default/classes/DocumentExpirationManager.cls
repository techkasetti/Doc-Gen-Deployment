public class DocumentExpirationManager{
    // Create expiration policies and rules
    public static void createExpirationPolicies() {
        List<DocumentExpirationPolicy__c> policies = new List<DocumentExpirationPolicy__c>();
        
        // Contract expiration policy
        policies.add(new DocumentExpirationPolicy__c(
            Policy_Name__c = 'Contract_Auto_Expiration_Policy',
            Document_Type__c = 'SERVICE_AGREEMENT',
            Expiration_Rule_Type__c = 'DATE_BASED',
            Default_Validity_Period_Days__c = 365,
            Grace_Period_Days__c = 30,
            Auto_Renewal_Enabled__c = true,
            Auto_Renewal_Notice_Days__c = 90,
            Pre_Expiration_Warning_Days__c = 60,
            Hard_Expiration_Enforcement__c = true,
            Stakeholder_Notification_Template__c = 'Contract_Expiration_Warning',
            Escalation_Chain__c = 'manager@company.com;legal@company.com;executive@company.com',
            Business_Impact_Assessment__c = 'HIGH'
        ));
        
        // Regulatory compliance expiration
        policies.add(new DocumentExpirationPolicy__c(
            Policy_Name__c = 'Compliance_Certificate_Expiration',
            Document_Type__c = 'COMPLIANCE_CERTIFICATE',
            Expiration_Rule_Type__c = 'REGULATORY_BASED',
            Default_Validity_Period_Days__c = 365,
            Grace_Period_Days__c = 0, // No grace period for compliance
            Auto_Renewal_Enabled__c = false,
            Pre_Expiration_Warning_Days__c = 90,
            Hard_Expiration_Enforcement__c = true,
            Compliance_Risk_Level__c = 'CRITICAL',
            Regulatory_Body__c = 'ISO 27001, SOC 2, GDPR',
            Emergency_Contact__c = 'compliance-emergency@company.com'
        ));
        
        // Time-sensitive legal documents
        policies.add(new DocumentExpirationPolicy__c(
            Policy_Name__c = 'NDA_Expiration_Management',
            Document_Type__c = 'NON_DISCLOSURE_AGREEMENT',
            Expiration_Rule_Type__c = 'CONDITIONAL_BASED',
            Default_Validity_Period_Days__c = 1095, // 3 years
            Grace_Period_Days__c = 15,
            Auto_Renewal_Enabled__c = true,
            Auto_Renewal_Conditions__c = 'MUTUAL_CONSENT_REQUIRED',
            Pre_Expiration_Warning_Days__c = 120,
            Post_Expiration_Actions__c = 'ARCHIVE;NOTIFY_PARTIES;UPDATE_CRM',
            Legal_Review_Required__c = true
        ));
        
        insert policies;
        
        // Create expiration monitoring jobs
        createExpirationMonitoringJobs(policies);
    }
    
    private static void createExpirationMonitoringJobs(List<DocumentExpirationPolicy__c> policies) {
        List<DocumentExpirationJob__c> jobs = new List<DocumentExpirationJob__c>();
        
        for (DocumentExpirationPolicy__c policy : policies) {
            jobs.add(new DocumentExpirationJob__c(
                Job_Name__c = 'Monitor_' + policy.Policy_Name__c,
                Expiration_Policy__c = policy.Id,
                Schedule_Expression__c = '0 0 8 * * ?', // Daily at 8 AM
                Job_Status__c = 'ACTIVE',
                Last_Run_Date__c = null,
                Next_Run_Date__c = DateTime.now().addDays(1),
                Documents_Checked_Last_Run__c = 0,
                Warnings_Sent_Last_Run__c = 0,
                Expirations_Processed_Last_Run__c = 0,
                Job_Priority__c = policy.Business_Impact_Assessment__c == 'HIGH' ? 'HIGH' : 'MEDIUM'
            ));
        }
        
        insert jobs;
    }
    
    // Smart expiration monitoring with AI predictions
    @future(callout=true)
    public static void executeExpirationMonitoring(String policyId) {
        DocumentExpirationPolicy__c policy = [
            SELECT Id, Policy_Name__c, Document_Type__c, Default_Validity_Period_Days__c,
                   Grace_Period_Days__c, Pre_Expiration_Warning_Days__c, Hard_Expiration_Enforcement__c,
                   Auto_Renewal_Enabled__c, Auto_Renewal_Notice_Days__c, Stakeholder_Notification_Template__c,
                   Escalation_Chain__c, Business_Impact_Assessment__c
            FROM DocumentExpirationPolicy__c 
            WHERE Id = :policyId
        ];
        
        // Find documents approaching expiration
        Date warningDate = Date.today().addDays(Integer.valueOf(policy.Pre_Expiration_Warning_Days__c));
        Date expirationDate = Date.today();
        
        List<DocumentExpirationMonitor__c> monitors = [
            SELECT Id, Document__c, Document_Title__c, Expiration_Date__c, Warning_Sent__c,
                   Auto_Renewal_Eligible__c, Business_Critical__c, Last_Activity_Date__c
            FROM DocumentExpirationMonitor__c
            WHERE Expiration_Policy__c = :policyId
            AND Expiration_Date__c <= :warningDate
            AND Status__c = 'ACTIVE'
        ];
        
        List<DocumentExpirationAlert__c> alerts = new List<DocumentExpirationAlert__c>();
        
        for (DocumentExpirationMonitor__c monitor : monitors) {
            // Determine alert priority and type
            String alertType = determineAlertType(monitor.Expiration_Date__c, policy);
            String priority = calculateAlertPriority(monitor, policy);
            
            // Create expiration alert
            DocumentExpirationAlert__c alert = new DocumentExpirationAlert__c(
                Alert_Type__c = alertType,
                Document_Monitor__c = monitor.Id,
                Expiration_Policy__c = policy.Id,
                Document__c = monitor.Document__c,
                Alert_Priority__c = priority,
                Days_Until_Expiration__c = monitor.Expiration_Date__c.daysBetween(Date.today()),
                Alert_Date__c = Date.today(),
                Alert_Status__c = 'PENDING',
                Business_Impact__c = assessBusinessImpact(monitor),
                Recommended_Actions__c = generateRecommendedActions(monitor, policy),
                Stakeholders_To_Notify__c = policy.Escalation_Chain__c,
                Auto_Renewal_Recommended__c = shouldAutoRenew(monitor, policy)
            );
            
            alerts.add(alert);
            
            // Process different alert types
            if (alertType == 'EXPIRATION_WARNING') {
                sendExpirationWarning(monitor, policy, alert);
                monitor.Warning_Sent__c = true;
            } else if (alertType == 'CRITICAL_EXPIRATION') {
                handleCriticalExpiration(monitor, policy, alert);
            } else if (alertType == 'EXPIRED_DOCUMENT') {
                enforceDocumentExpiration(monitor, policy, alert);
            }
        }
        
        insert alerts;
        update monitors;
        
        // Update job statistics
        updateExpirationJobStats(policyId, monitors.size(), alerts.size());
    }
    
    private static String determineAlertType(Date expirationDate, DocumentExpirationPolicy__c policy) {
        Integer daysUntilExpiration = Date.today().daysBetween(expirationDate);
        
        if (daysUntilExpiration < 0) {
            return 'EXPIRED_DOCUMENT';
        } else if (daysUntilExpiration <= 7) {
            return 'CRITICAL_EXPIRATION';
        } else if (daysUntilExpiration <= policy.Pre_Expiration_Warning_Days__c) {
            return 'EXPIRATION_WARNING';
        } else {
            return 'RENEWAL_REMINDER';
        }
    }
    
    private static String calculateAlertPriority(DocumentExpirationMonitor__c monitor, DocumentExpirationPolicy__c policy) {
        if (monitor.Business_Critical__c || policy.Business_Impact_Assessment__c == 'HIGH') {
            return 'P1_CRITICAL';
        } else if (policy.Hard_Expiration_Enforcement__c) {
            return 'P2_HIGH';
        } else {
            return 'P3_MEDIUM';
        }
    }
    
    private static String assessBusinessImpact(DocumentExpirationMonitor__c monitor) {
        // AI-powered business impact assessment
        if (monitor.Business_Critical__c) {
            return 'SEVERE - Operations may be disrupted';
        } else {
            return 'MODERATE - Standard business process affected';
        }
    }
    
    private static String generateRecommendedActions(DocumentExpirationMonitor__c monitor, DocumentExpirationPolicy__c policy) {
        List<String> actions = new List<String>();
        
        if (policy.Auto_Renewal_Enabled__c && monitor.Auto_Renewal_Eligible__c) {
            actions.add('Initiate auto-renewal process');
        } else {
            actions.add('Contact counterparty for renewal negotiation');
        }
        
        actions.add('Review document terms for updates');
        actions.add('Verify compliance requirements');
        actions.add('Prepare backup agreements if needed');
        
        return String.join(actions, ';');
    }
    
    private static Boolean shouldAutoRenew(DocumentExpirationMonitor__c monitor, DocumentExpirationPolicy__c policy) {
        return policy.Auto_Renewal_Enabled__c && 
               monitor.Auto_Renewal_Eligible__c && 
               monitor.Last_Activity_Date__c > Date.today().addDays(-90);
    }
    
    private static void sendExpirationWarning(DocumentExpirationMonitor__c monitor, 
                                            DocumentExpirationPolicy__c policy, 
                                            DocumentExpirationAlert__c alert) {
        // Send automated notification using specified template
        EmailNotificationService.sendTemplatedEmail(
            policy.Stakeholder_Notification_Template__c,
            policy.Escalation_Chain__c.split(';'),
            new Map<String, String>{
                'documentTitle' => monitor.Document_Title__c,
                'expirationDate' => String.valueOf(monitor.Expiration_Date__c),
                'daysRemaining' => String.valueOf(alert.Days_Until_Expiration__c),
                'recommendedActions' => alert.Recommended_Actions__c
            }
        );
    }
    
    private static void handleCriticalExpiration(DocumentExpirationMonitor__c monitor,
                                               DocumentExpirationPolicy__c policy,
                                               DocumentExpirationAlert__c alert) {
        // Escalate to management and create high-priority task
        Task escalationTask = new Task(
            Subject = 'CRITICAL: Document Expiring - ' + monitor.Document_Title__c,
            Description = 'Document expires in ' + alert.Days_Until_Expiration__c + ' days. ' +
                         'Business impact: ' + alert.Business_Impact__c,
            Priority = 'High',
            Status = 'Not Started',
            ActivityDate = Date.today().addDays(1),
            OwnerId = getEscalationOwner(policy.Escalation_Chain__c)
        );
        insert escalationTask;
    }
    
    private static void enforceDocumentExpiration(DocumentExpirationMonitor__c monitor,
                                                DocumentExpirationPolicy__c policy,
                                                DocumentExpirationAlert__c alert) {
        if (policy.Hard_Expiration_Enforcement__c) {
            // Archive expired document and revoke access
            monitor.Status__c = 'EXPIRED';
            
            // Create audit record for expiration enforcement
            DocumentExpirationAudit__c audit = new DocumentExpirationAudit__c(
                Document__c = monitor.Document__c,
                Expiration_Policy__c = policy.Id,
                Expiration_Date__c = monitor.Expiration_Date__c,
                Enforcement_Date__c = Date.today(),
                Enforcement_Action__c = 'DOCUMENT_DEACTIVATED',
                Business_Impact__c = alert.Business_Impact__c,
                Grace_Period_Applied__c = policy.Grace_Period_Days__c > 0,
                Audit_Trail__c = 'Document automatically expired per policy: ' + policy.Policy_Name__c
            );
            insert audit;
        }
    }
    
    private static String getEscalationOwner(String escalationChain) {
        // Return first manager in escalation chain
        List<String> emails = escalationChain.split(';');
        if (emails.size() > 0) {
            User manager = [SELECT Id FROM User WHERE Email = :emails[0] LIMIT 1];
            return manager.Id;
        }
        return UserInfo.getUserId();
    }
    
    private static void updateExpirationJobStats(String policyId, Integer monitorsChecked, Integer alertsCreated) {
        DocumentExpirationJob__c job = [
            SELECT Id, Documents_Checked_Last_Run__c, Warnings_Sent_Last_Run__c,
                   Last_Run_Date__c, Next_Run_Date__c
            FROM DocumentExpirationJob__c 
            WHERE Expiration_Policy__c = :policyId 
            LIMIT 1
        ];
        
        job.Documents_Checked_Last_Run__c = monitorsChecked;
        job.Warnings_Sent_Last_Run__c = alertsCreated;
        job.Last_Run_Date__c = DateTime.now();
        job.Next_Run_Date__c = DateTime.now().addDays(1);
        
        update job;
    }
}