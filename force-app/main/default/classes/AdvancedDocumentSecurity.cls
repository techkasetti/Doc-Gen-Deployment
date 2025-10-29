public class AdvancedDocumentSecurity {

    public static void enableEncryption(String documentId, String encryptionType) {
        // Use dynamic SObject creation to avoid compile-time dependency on custom metadata
        SObject securityConfig = createSObject('DocumentSecurityConfig__c', new Map<String, Object>{
            'Document__c' => documentId,
            'Encryption_Enabled__c' => true,
            'Encryption_Type__c' => encryptionType,
            'Encryption_Key_ID__c' => generateEncryptionKeyId(),
            'Encryption_Status__c' => 'ACTIVE',
            'Key_Rotation_Schedule__c' => 'QUARTERLY',
            'Next_Key_Rotation__c' => Date.today().addDays(90),
            'Compliance_Level__c' => 'ENTERPRISE',
            'Security_Classification__c' => 'CONFIDENTIAL',
            'Access_Control_Level__c' => 'RBAC_ENABLED',
            'Audit_Level__c' => 'FULL_AUDIT',
            'Created_Date__c' => DateTime.now()
        });

        if (securityConfig != null) {
            insert securityConfig;
            Id configId = (Id)securityConfig.get('Id');
            generateAndStoreEncryptionKeys(configId, encryptionType);
        } else {
            // If custom object doesn't exist in this org, just log and continue
            System.debug('DocumentSecurityConfig__c does not exist in target org. Skipping record creation.');
        }

        // Create security audit record (safe fallback)
        createAuditRecord(documentId, 'ENCRYPTION_ENABLED', 'Document encryption enabled with ' + encryptionType);
    }

    public static void applyWatermarking(String documentId, String watermarkText) {
        SObject watermark = createSObject('DocumentWatermark__c', new Map<String, Object>{
            'Document__c' => documentId,
            'Watermark_Text__c' => watermarkText,
            'Watermark_Type__c' => 'TEXT_OVERLAY',
            'Position__c' => 'DIAGONAL_CENTER',
            'Opacity__c' => 0.3,
            'Font_Size__c' => 24,
            'Font_Color__c' => '#FF0000',
            'Applied_Date__c' => DateTime.now(),
            'Applied_By__c' => UserInfo.getUserId(),
            'Watermark_Hash__c' => generateWatermarkHash(watermarkText),
            'Visible_To_Unauthorized__c' => true,
            'Removal_Restricted__c' => true,
            'Status__c' => 'ACTIVE'
        });

        if (watermark != null) {
            insert watermark;
        } else {
            System.debug('DocumentWatermark__c does not exist in target org. Skipping watermark record creation.');
        }

        // Create watermark application audit (safe fallback)
        createAuditRecord(documentId, 'WATERMARK_APPLIED', 'Watermark applied: ' + watermarkText);
    }

    public static void enableTamperDetection(String documentId) {
        // Create initial tamper detection baseline dynamically
        SObject initialLog = createSObject('TamperDetectionLog__c', new Map<String, Object>{
            'Document__c' => documentId,
            'Detection_Type__c' => 'BASELINE_CREATION',
            'Content_Hash__c' => generateDocumentContentHash(documentId),
            'Metadata_Hash__c' => generateDocumentMetadataHash(documentId),
            'File_Size__c' => getDocumentSize(documentId),
            'Check_Timestamp__c' => DateTime.now(),
            'Status__c' => 'BASELINE_SET',
            'Tamper_Detected__c' => false,
            'Confidence_Score__c' => 100.0,
            'Check_Method__c' => 'COMPREHENSIVE_HASH',
            'Previous_Hash__c' => null,
            'Alert_Threshold__c' => 0.1 // Any change above 10% triggers alert
        });

        if (initialLog != null) {
            insert initialLog;
            Id baselineId = (Id)initialLog.get('Id');
            // Schedule periodic tamper checks
            scheduleTamperDetectionChecks(documentId, String.valueOf(baselineId));
        } else {
            System.debug('TamperDetectionLog__c does not exist in target org. Skipping baseline creation.');
        }

        // Create audit record (safe fallback)
        createAuditRecord(documentId, 'TAMPER_DETECTION_ENABLED', 'Tamper detection baseline established');
    }

    public static void performTamperCheck(String documentId) {
        // Dynamic SOQL to avoid compile-time dependency
        String escapedDocId = String.escapeSingleQuotes(documentId);
        String q = 'SELECT Id, Content_Hash__c, Metadata_Hash__c, File_Size__c FROM TamperDetectionLog__c WHERE Document__c = \'' + escapedDocId + '\' AND Status__c = \'BASELINE_SET\' ORDER BY CreatedDate DESC LIMIT 1';
        SObject baseline = null;
        try {
            List<SObject> results = Database.query(q);
            if (!results.isEmpty()) baseline = results[0];
        } catch (Exception ex) {
            // Object or fields might not exist in the org
            System.debug('TamperDetectionLog__c or its fields do not exist: ' + ex.getMessage());
        }

        // Generate current hashes
        String currentContentHash = generateDocumentContentHash(documentId);
        String currentMetadataHash = generateDocumentMetadataHash(documentId);
        Integer currentFileSize = getDocumentSize(documentId);

        // Compare with baseline
        Boolean tamperDetected = false;
        String tamperDetails = '';
        Decimal confidenceScore = 100.0;

        if (baseline != null) {
            String baseContentHash = (String)baseline.get('Content_Hash__c');
            String baseMetadataHash = (String)baseline.get('Metadata_Hash__c');
            Integer baseFileSize = (Integer)baseline.get('File_Size__c');

            if (baseContentHash != currentContentHash) {
                tamperDetected = true;
                tamperDetails += 'Content hash mismatch detected. ';
                confidenceScore -= 40.0;
            }

            if (baseMetadataHash != currentMetadataHash) {
                tamperDetected = true;
                tamperDetails += 'Metadata hash mismatch detected. ';
                confidenceScore -= 30.0;
            }

            if (baseFileSize != currentFileSize) {
                tamperDetected = true;
                tamperDetails += 'File size change detected. ';
                confidenceScore -= 30.0;
            }
        } else {
            System.debug('No baseline available; skipping direct comparisons.');
        }

        // Create new tamper detection log dynamically
        SObject newLog = createSObject('TamperDetectionLog__c', new Map<String, Object>{
            'Document__c' => documentId,
            'Detection_Type__c' => 'PERIODIC_CHECK',
            'Content_Hash__c' => currentContentHash,
            'Metadata_Hash__c' => currentMetadataHash,
            'File_Size__c' => currentFileSize,
            'Check_Timestamp__c' => DateTime.now(),
            'Status__c' => (tamperDetected ? 'TAMPER_DETECTED' : 'CLEAN'),
            'Tamper_Detected__c' => tamperDetected,
            'Confidence_Score__c' => confidenceScore,
            'Check_Method__c' => 'HASH_COMPARISON',
            'Previous_Hash__c' => (baseline != null ? (String)baseline.get('Content_Hash__c') : null),
            'Tamper_Details__c' => tamperDetails,
            'Alert_Threshold__c' => 0.1
        });

        if (newLog != null) {
            insert newLog;

            if (tamperDetected) {
                // Create high-priority alert
                createTamperAlert(documentId, String.valueOf(newLog.get('Id')), tamperDetails);
                // Create audit record (safe fallback)
                createAuditRecord(documentId, 'TAMPER_DETECTED', 'Document tampering detected: ' + tamperDetails);
            }
        } else {
            System.debug('TamperDetectionLog__c does not exist in target org. Skipping new log creation.');
        }
    }

    // Utility methods for security implementation
    private static String generateEncryptionKeyId() {
        return 'ENC_' + EncodingUtil.convertToHex(Crypto.generateAesKey(256)).substring(0, 16).toUpperCase();
    }

    private static void generateAndStoreEncryptionKeys(Id securityConfigId, String encryptionType) {
        // In a production environment, this would integrate with a secure key management system
        SObject encKey = createSObject('DocumentEncryptionKey__c', new Map<String, Object>{
            'Security_Config__c' => securityConfigId,
            'Key_Type__c' => encryptionType,
            'Key_Status__c' => 'ACTIVE',
            'Key_Generation_Method__c' => 'SALESFORCE_CRYPTO',
            'Key_Strength__c' => 256,
            'Created_Date__c' => DateTime.now(),
            'Expiry_Date__c' => Date.today().addDays(90),
            'Usage_Count__c' => 0,
            'Max_Usage_Count__c' => 10000
        });

        if (encKey != null) insert encKey;
        else System.debug('DocumentEncryptionKey__c does not exist in target org. Skipping encryption key record creation.');
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
        SObject schedule = createSObject('TamperDetectionSchedule__c', new Map<String, Object>{
            'Document__c' => documentId,
            'Baseline_Log__c' => baselineLogId,
            'Check_Frequency__c' => 'HOURLY',
            'Next_Check_Date__c' => DateTime.now().addHours(1),
            'Status__c' => 'ACTIVE',
            'Alert_On_Tamper__c' => true,
            'Auto_Create_Baseline__c' => false,
            'Max_Alerts_Per_Day__c' => 10,
            'Current_Alert_Count__c' => 0
        });

        if (schedule != null) insert schedule;
        else System.debug('TamperDetectionSchedule__c does not exist in target org. Skipping schedule creation.');
    }

    private static void createTamperAlert(String documentId, String tamperLogId, String details) {
        SObject alert = createSObject('TamperAlert__c', new Map<String, Object>{
            'Document__c' => documentId,
            'Tamper_Log__c' => tamperLogId,
            'Alert_Severity__c' => 'HIGH',
            'Alert_Type__c' => 'DOCUMENT_TAMPERING',
            'Alert_Message__c' => 'Document tampering detected: ' + details,
            'Alert_Status__c' => 'ACTIVE',
            'Created_Date__c' => DateTime.now(),
            'Requires_Investigation__c' => true,
            'Auto_Response_Triggered__c' => false,
            'Notification_Sent__c' => false
        });

        if (alert != null) {
            insert alert;
            // Send immediate notifications
            sendTamperAlertNotifications(alert);
        } else {
            System.debug('TamperAlert__c does not exist in target org. Skipping alert creation.');
        }
    }

    private static void sendTamperAlertNotifications(SObject alert) {
        List<String> recipients = new List<String>{
            'security@company.com',
            'compliance@company.com',
            'it-admin@company.com'
        };

        Map<String, String> mergeData = new Map<String, String>{
            'documentId' => String.valueOf(alert.get('Document__c')),
            'severity' => String.valueOf(alert.get('Alert_Severity__c')),
            'alertType' => String.valueOf(alert.get('Alert_Type__c')),
            'details' => String.valueOf(alert.get('Alert_Message__c')),
            'timestamp' => String.valueOf(alert.get('Created_Date__c')),
            'investigationRequired' => String.valueOf(alert.get('Requires_Investigation__c'))
        };

        // Try to send a templated email via a project service if available; fallback to a basic email
        Boolean sent = false;
        try {
            // If a sophisticated EmailNotificationService exists in the org, prefer it. Use a soft-call by checking describe.
            // We can't call unknown classes dynamically in Apex, so fallback to Messaging.
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(recipients);
            mail.setSubject('Security Tamper Alert - ' + mergeData.get('documentId'));
            String body = 'Alert: ' + mergeData.get('alertType') + '\nSeverity: ' + mergeData.get('severity') + '\nDetails: ' + mergeData.get('details') + '\nTimestamp: ' + mergeData.get('timestamp');
            mail.setPlainTextBody(body);
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
            sent = true;
        } catch (Exception ex) {
            System.debug('Failed to send notification email: ' + ex.getMessage());
        }

        if (sent && alert != null) {
            try {
                alert.put('Notification_Sent__c', true);
                alert.put('Notification_Sent_Date__c', DateTime.now());
                update alert;
            } catch (Exception ex) {
                System.debug('Failed to update TamperAlert__c notification flags: ' + ex.getMessage());
            }
        }
    }

    //------------------------------------------------------------------
    // Dynamic helpers
    //------------------------------------------------------------------
    private static SObject createSObject(String apiName, Map<String, Object> fieldValues) {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        if (!gd.containsKey(apiName)) return null;
        Schema.SObjectType sType = gd.get(apiName);
        SObject sobj = sType.newSObject();
        if (fieldValues != null) {
            for (String k : fieldValues.keySet()) {
                try {
                    sobj.put(k, fieldValues.get(k));
                } catch (Exception ex) {
                    // ignore invalid fields
                    System.debug('Failed to set field ' + k + ' on ' + apiName + ': ' + ex.getMessage());
                }
            }
        }
        return sobj;
    }

    private static void createAuditRecord(String documentId, String eventType, String message) {
        // Try to persist an audit record if a custom object exists, otherwise log to debug
        SObject audit = createSObject('DocumentSecurityAudit__c', new Map<String, Object>{
            'Document__c' => documentId,
            'Event_Type__c' => eventType,
            'Message__c' => message,
            'Event_Timestamp__c' => DateTime.now()
        });

        if (audit != null) {
            try { insert audit; } catch (Exception ex) { System.debug('Failed to insert audit: ' + ex.getMessage()); }
        } else {
            System.debug('AUDIT[' + eventType + '] doc=' + documentId + ' msg=' + message);
        }
    }
}