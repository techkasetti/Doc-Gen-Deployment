public class AdvancedDocumentSecurity {
    
    public static void enableEncryption(String documentId, String encryptionType) {
        DocumentSecurityConfig__c securityConfig = new DocumentSecurityConfig__c(
            Document__c = documentId,
            Encryption_Enabled__c = true,
            Encryption_Type__c = encryptionType,
            Encryption_Key_ID__c = generateEncryptionKeyId(),
            Encryption_Status__c = 'ACTIVE',
            Key_Rotation_Schedule__c = 'QUARTERLY',
            Next_Key_Rotation__c = Date.today().addDays(90),
            Compliance_Level__c = 'ENTERPRISE',
            Security_Classification__c = 'CONFIDENTIAL',
            Access_Control_Level__c = 'RBAC_ENABLED',
            Audit_Level__c = 'FULL_AUDIT',
            Created_Date__c = DateTime.now()
        );
        
        insert securityConfig;
        
        // Generate encryption keys
        generateAndStoreEncryptionKeys(securityConfig.Id, encryptionType);
        
        // Create security audit record
        BlockchainAuditManager.createImmutableAuditRecord(
            documentId, 
            'ENCRYPTION_ENABLED', 
            'Document encryption enabled with ' + encryptionType
        );
    }
    
    public static void applyWatermarking(String documentId, String watermarkText) {
        DocumentWatermark__c watermark = new DocumentWatermark__c(
            Document__c = documentId,
            Watermark_Text__c = watermarkText,
            Watermark_Type__c = 'TEXT_OVERLAY',
            Position__c = 'DIAGONAL_CENTER',
            Opacity__c = 0.3,
            Font_Size__c = 24,
            Font_Color__c = '#FF0000',
            Applied_Date__c = DateTime.now(),
            Applied_By__c = UserInfo.getUserId(),
            Watermark_Hash__c = generateWatermarkHash(watermarkText),
            Visible_To_Unauthorized__c = true,
            Removal_Restricted__c = true,
            Status__c = 'ACTIVE'
        );
        
        insert watermark;
        
        // Create watermark application audit
        BlockchainAuditManager.createImmutableAuditRecord(
            documentId,
            'WATERMARK_APPLIED',
            'Watermark applied: ' + watermarkText
        );
    }
    
    public static void enableTamperDetection(String documentId) {
        // Create initial tamper detection baseline
        TamperDetectionLog__c initialLog = new TamperDetectionLog__c(
            Document__c = documentId,
            Detection_Type__c = 'BASELINE_CREATION',
            Content_Hash__c = generateDocumentContentHash(documentId),
            Metadata_Hash__c = generateDocumentMetadataHash(documentId),
            File_Size__c = getDocumentSize(documentId),
            Check_Timestamp__c = DateTime.now(),
            Status__c = 'BASELINE_SET',
            Tamper_Detected__c = false,
            Confidence_Score__c = 100.0,
            Check_Method__c = 'COMPREHENSIVE_HASH',
            Previous_Hash__c = null,
            Alert_Threshold__c = 0.1 // Any change above 10% triggers alert
        );
        
        insert initialLog;
        
        // Schedule periodic tamper checks
        scheduleTamperDetectionChecks(documentId, initialLog.Id);
        
        // Create audit record
        BlockchainAuditManager.createImmutableAuditRecord(
            documentId,
            'TAMPER_DETECTION_ENABLED',
            'Tamper detection baseline established'
        );
    }
    
    public static void performTamperCheck(String documentId) {
        // Get the latest baseline
        TamperDetectionLog__c baseline = [
            SELECT Id, Content_Hash__c, Metadata_Hash__c, File_Size__c
            FROM TamperDetectionLog__c
            WHERE Document__c = :documentId
            AND Status__c = 'BASELINE_SET'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        // Generate current hashes
        String currentContentHash = generateDocumentContentHash(documentId);
        String currentMetadataHash = generateDocumentMetadataHash(documentId);
        Integer currentFileSize = getDocumentSize(documentId);
        
        // Compare with baseline
        Boolean tamperDetected = false;
        String tamperDetails = '';
        Decimal confidenceScore = 100.0;
        
        if (baseline.Content_Hash__c != currentContentHash) {
            tamperDetected = true;
            tamperDetails += 'Content hash mismatch detected. ';
            confidenceScore -= 40.0;
        }
        
        if (baseline.Metadata_Hash__c != currentMetadataHash) {
            tamperDetected = true;
            tamperDetails += 'Metadata hash mismatch detected. ';
            confidenceScore -= 30.0;
        }
        
        if (baseline.File_Size__c != currentFileSize) {
            tamperDetected = true;
            tamperDetails += 'File size change detected. ';
            confidenceScore -= 30.0;
        }
        
        // Create new tamper detection log
        TamperDetectionLog__c newLog = new TamperDetectionLog__c(
            Document__c = documentId,
            Detection_Type__c = 'PERIODIC_CHECK',
            Content_Hash__c = currentContentHash,
            Metadata_Hash__c = currentMetadataHash,
            File_Size__c = currentFileSize,
            Check_Timestamp__c = DateTime.now(),
            Status__c = tamperDetected ? 'TAMPER_DETECTED' : 'CLEAN',
            Tamper_Detected__c = tamperDetected,
            Confidence_Score__c = confidenceScore,
            Check_Method__c = 'HASH_COMPARISON',
            Previous_Hash__c = baseline.Content_Hash__c,
            Tamper_Details__c = tamperDetails,
            Alert_Threshold__c = 0.1
        );
        
        insert newLog;
        
        if (tamperDetected) {
            // Create high-priority alert
            createTamperAlert(documentId, newLog.Id, tamperDetails);
            
            // Create blockchain audit record
            BlockchainAuditManager.createImmutableAuditRecord(
                documentId,
                'TAMPER_DETECTED',
                'Document tampering detected: ' + tamperDetails
            );
        }
    }
    
    // Utility methods for security implementation
    private static String generateEncryptionKeyId() {
        return 'ENC_' + EncodingUtil.convertToHex(Crypto.generateAesKey(256)).substring(0, 16).toUpperCase();
    }
    
    private static void generateAndStoreEncryptionKeys(String securityConfigId, String encryptionType) {
        // In a production environment, this would integrate with a secure key management system
        DocumentEncryptionKey__c encKey = new DocumentEncryptionKey__c(
            Security_Config__c = securityConfigId,
            Key_Type__c = encryptionType,
            Key_Status__c = 'ACTIVE',
            Key_Generation_Method__c = 'SALESFORCE_CRYPTO',
            Key_Strength__c = 256,
            Created_Date__c = DateTime.now(),
            Expiry_Date__c = Date.today().addDays(90),
            Usage_Count__c = 0,
            Max_Usage_Count__c = 10000
        );
        
        insert encKey;
    }
    
    private static String generateWatermarkHash(String watermarkText) {
        return EncodingUtil.convertToHex(
            Crypto.generateDigest('SHA256', Blob.valueOf(watermarkText + String.valueOf(DateTime.now())))
        );
    }
    
    private static String generateDocumentContentHash(String documentId) {
        ContentVersion version = [SELECT VersionData FROM ContentVersion WHERE ContentDocumentId = :documentId AND IsLatest = true LIMIT 1];
        return EncodingUtil.convertToHex(Crypto.generateDigest('SHA256', version.VersionData));
    }
    
    private static String generateDocumentMetadataHash(String documentId) {
        ContentDocument doc = [SELECT Title, FileType, CreatedDate, LastModifiedDate FROM ContentDocument WHERE Id = :documentId LIMIT 1];
        String metadata = doc.Title + doc.FileType + String.valueOf(doc.CreatedDate) + String.valueOf(doc.LastModifiedDate);
        return EncodingUtil.convertToHex(Crypto.generateDigest('SHA256', Blob.valueOf(metadata)));
    }
    
    private static Integer getDocumentSize(String documentId) {
        ContentVersion version = [SELECT ContentSize FROM ContentVersion WHERE ContentDocumentId = :documentId AND IsLatest = true LIMIT 1];
        return version.ContentSize;
    }
    
    @future
    private static void scheduleTamperDetectionChecks(String documentId, String baselineLogId) {
        // Create scheduled check record
        TamperDetectionSchedule__c schedule = new TamperDetectionSchedule__c(
            Document__c = documentId,
            Baseline_Log__c = baselineLogId,
            Check_Frequency__c = 'HOURLY',
            Next_Check_Date__c = DateTime.now().addHours(1),
            Status__c = 'ACTIVE',
            Alert_On_Tamper__c = true,
            Auto_Create_Baseline__c = false,
            Max_Alerts_Per_Day__c = 10,
            Current_Alert_Count__c = 0
        );
        
        insert schedule;
    }
    
    private static void createTamperAlert(String documentId, String tamperLogId, String details) {
        TamperAlert__c alert = new TamperAlert__c(
            Document__c = documentId,
            Tamper_Log__c = tamperLogId,
            Alert_Severity__c = 'HIGH',
            Alert_Type__c = 'DOCUMENT_TAMPERING',
            Alert_Message__c = 'Document tampering detected: ' + details,
            Alert_Status__c = 'ACTIVE',
            Created_Date__c = DateTime.now(),
            Requires_Investigation__c = true,
            Auto_Response_Triggered__c = false,
            Notification_Sent__c = false
        );
        
        insert alert;
        
        // Send immediate notifications
        sendTamperAlertNotifications(alert);
    }
private static void sendTamperAlertNotifications(TamperAlert__c alert) {
        List<String> recipients = new List<String>{
            'security@company.com',
            'compliance@company.com',
            'it-admin@company.com'
        };
Map<String, String> mergeData = new Map<String, String>{
    'documentId'             => alert.Document__c,
    'severity'               => alert.Alert_Severity__c,
    'alertType'              => alert.Alert_Type__c,
    'details'                => alert.Alert_Message__c,
    'timestamp'              => String.valueOf(alert.Created_Date__c),
    'investigationRequired'  => String.valueOf(alert.Requires_Investigation__c)
};

// Send templated email
EmailNotificationService.sendTemplatedEmail(
    'Security_Tamper_Alert',
    recipients,
    mergeData
);

// Update alert as notification sent
alert.Notification_Sent__c      = true;
alert.Notification_Sent_Date__c = DateTime.now();
update alert;
    }
}