public class DocumentArchivalManager {
    
    // Retention policy engine
    public static void createRetentionPolicies() {
        
        List<DocumentRetentionPolicy__c> policies = new List<DocumentRetentionPolicy__c>();
        
        // GDPR-compliant retention policy
        DocumentRetentionPolicy__c gdprPolicy = new DocumentRetentionPolicy__c();
        gdprPolicy.Policy_Name__c = 'GDPR_Personal_Data_Retention';
        gdprPolicy.Document_Type__c = 'DATA_PROCESSING_AGREEMENT';
        gdprPolicy.Retention_Period_Years__c = 7;
        gdprPolicy.Retention_Period_Days__c = 2555;
        gdprPolicy.Geographic_Scope__c = 'EU;EEA';
        gdprPolicy.Legal_Basis__c = 'GDPR Article 17 - Right to Erasure';
        gdprPolicy.Auto_Delete_Enabled__c = true;
        gdprPolicy.Pre_Deletion_Review__c = true;
        gdprPolicy.Deletion_Approval_Required__c = true;
        gdprPolicy.Archive_Before_Deletion__c = true;
        gdprPolicy.Archive_Location__c = 'SECURE_CLOUD_ARCHIVE';
        gdprPolicy.Encryption_Required__c = true;
        gdprPolicy.Access_Log_Required__c = true;
        gdprPolicy.Compliance_Officer_Notification__c = true;
        policies.add(gdprPolicy);
        
        // Financial records retention
        DocumentRetentionPolicy__c finPolicy = new DocumentRetentionPolicy__c();
        finPolicy.Policy_Name__c = 'Financial_Records_Retention_US';
        finPolicy.Document_Type__c = 'FINANCIAL_CONTRACT';
        finPolicy.Retention_Period_Years__c = 10;
        finPolicy.Retention_Period_Days__c = 3650;
        finPolicy.Geographic_Scope__c = 'US';
        finPolicy.Legal_Basis__c = 'SOX Compliance - 15 USC 7213';
        finPolicy.Auto_Delete_Enabled__c = false;
        finPolicy.Pre_Deletion_Review__c = true;
        finPolicy.Deletion_Approval_Required__c = true;
        finPolicy.Archive_Before_Deletion__c = true;
        finPolicy.Archive_Location__c = 'IMMUTABLE_BLOCKCHAIN_STORAGE';
        finPolicy.Encryption_Required__c = true;
        finPolicy.Access_Log_Required__c = true;
        finPolicy.Audit_Trail_Permanent__c = true;
        policies.add(finPolicy);
        
        // Healthcare records retention (HIPAA)
        DocumentRetentionPolicy__c hipaaPolicy = new DocumentRetentionPolicy__c();
        hipaaPolicy.Policy_Name__c = 'HIPAA_PHI_Retention_Policy';
        hipaaPolicy.Document_Type__c = 'HEALTHCARE_AGREEMENT';
        hipaaPolicy.Retention_Period_Years__c = 6;
        hipaaPolicy.Retention_Period_Days__c = 2190;
        hipaaPolicy.Geographic_Scope__c = 'US';
        hipaaPolicy.Legal_Basis__c = 'HIPAA 45 CFR 164.530(j)(2)';
        hipaaPolicy.Auto_Delete_Enabled__c = false;
        hipaaPolicy.Pre_Deletion_Review__c = true;
        hipaaPolicy.Deletion_Approval_Required__c = true;
        hipaaPolicy.Archive_Before_Deletion__c = true;
        hipaaPolicy.Archive_Location__c = 'HIPAA_COMPLIANT_ARCHIVE';
        hipaaPolicy.Encryption_Required__c = true;
        hipaaPolicy.PHI_Anonymization_Required__c = true;
        hipaaPolicy.Access_Log_Required__c = true;
        policies.add(hipaaPolicy);
        
        insert policies;
        
        // Create retention schedule for each policy
        createRetentionSchedules(policies);
    }
    
    private static void createRetentionSchedules(List<DocumentRetentionPolicy__c> policies) {
        List<DocumentRetentionSchedule__c> schedules = new List<DocumentRetentionSchedule__c>();
        
        for (DocumentRetentionPolicy__c policy : policies) {
            schedules.add(new DocumentRetentionSchedule__c(
                Retention_Policy__c = policy.Id,
                Schedule_Name__c = policy.Policy_Name__c + '_Schedule',
                Execution_Frequency__c = 'MONTHLY',
                Next_Execution_Date__c = Date.today().addDays(30),
                Last_Execution_Date__c = null,
                Documents_Processed_Last_Run__c = 0,
                Documents_Archived_Last_Run__c = 0,
                Documents_Deleted_Last_Run__c = 0,
                Schedule_Status__c = 'ACTIVE',
                Notification_Recipients__c = 'compliance@company.com;legal@company.com',
                Pre_Execution_Approval_Required__c = true
            ));
        }
        
        insert schedules;
    }
    
    // Intelligent archival process
    @future(callout=true)
    public static void executeRetentionPolicy(String policyId) {
        DocumentRetentionPolicy__c policy = [
            SELECT Id, Policy_Name__c, Document_Type__c, Retention_Period_Days__c, 
                   Auto_Delete_Enabled__c, Archive_Before_Deletion__c, Archive_Location__c,
                   Encryption_Required__c, Pre_Deletion_Review__c
            FROM DocumentRetentionPolicy__c 
            WHERE Id = :policyId
        ];
        
        // Find documents eligible for archival/deletion
        Date cutoffDate = Date.today().addDays(-Integer.valueOf(policy.Retention_Period_Days__c));
        
        List<ContentDocument> documentsToProcess = [
            SELECT Id, Title, CreatedDate, ContentSize, FileType,
                   (SELECT Id, LinkedEntityId FROM ContentDocumentLinks)
            FROM ContentDocument 
            WHERE CreatedDate < :cutoffDate
            AND FileType IN ('PDF', 'DOCX', 'DOC')
        ];
        
        List<DocumentArchivalRecord__c> archivalRecords = new List<DocumentArchivalRecord__c>();
        
        for (ContentDocument doc : documentsToProcess) {
            // Create archival record
            DocumentArchivalRecord__c record = new DocumentArchivalRecord__c(
                Document_Id__c = doc.Id,
                Document_Title__c = doc.Title,
                Original_Creation_Date__c = doc.CreatedDate,
                Archival_Date__c = Date.today(),
                Archive_Location__c = policy.Archive_Location__c,
                File_Size_MB__c = (doc.ContentSize / 1024.0 / 1024.0),
                Encryption_Applied__c = policy.Encryption_Required__c,
                Archive_Status__c = 'PENDING_ARCHIVAL',
                Legal_Hold_Check__c = checkLegalHoldStatus(doc.Id),
                Compliance_Verification__c = 'PASSED',
                Access_History_Preserved__c = true
            );
            
            archivalRecords.add(record);
            
            // Archive document if not under legal hold
            if (!record.Legal_Hold_Check__c) {
                archiveDocument(doc, policy);
                record.Archive_Status__c = 'ARCHIVED';
                
                // Delete original if policy allows
                if (policy.Auto_Delete_Enabled__c && !policy.Pre_Deletion_Review__c) {
                    deleteOriginalDocument(doc.Id);
                    record.Original_Document_Deleted__c = true;
                }
            }
        }
        
        insert archivalRecords;
        
        // Update retention schedule
        updateRetentionScheduleStats(policyId, archivalRecords.size());
    }
    
    private static Boolean checkLegalHoldStatus(String documentId) {
        Integer holdCount = [
            SELECT COUNT()
            FROM LegalHold__c
            WHERE Status__c = 'ACTIVE'
            AND Document_Scope__c = :documentId
        ];
        return holdCount > 0;
    }
    
    private static void archiveDocument(ContentDocument doc, DocumentRetentionPolicy__c policy) {
        // Archive to specified location with encryption
        ArchiveService.archiveDocument(doc.Id, policy.Archive_Location__c, policy.Encryption_Required__c);
        
        // Create blockchain audit record
        BlockchainAuditManager.createImmutableAuditRecord(
            doc.Id,
            'DOCUMENT_ARCHIVED',
            'Document archived per retention policy: ' + policy.Policy_Name__c
        );
    }
    
    private static void deleteOriginalDocument(String documentId) {
        delete [SELECT Id FROM ContentDocument WHERE Id = :documentId];
    }
    
    private static void updateRetentionScheduleStats(String policyId, Integer processedCount) {
        DocumentRetentionSchedule__c schedule = [
            SELECT Id, Documents_Processed_Last_Run__c, Last_Execution_Date__c,
                   Documents_Archived_Last_Run__c, Next_Execution_Date__c
            FROM DocumentRetentionSchedule__c 
            WHERE Retention_Policy__c = :policyId 
            LIMIT 1
        ];
        
        schedule.Documents_Processed_Last_Run__c = processedCount;
        schedule.Last_Execution_Date__c = Date.today();
        schedule.Next_Execution_Date__c = Date.today().addDays(30);
        schedule.Documents_Archived_Last_Run__c = processedCount;
        
        update schedule;
    }
}