public class AdvancedRetentionOrchestrator {
    
    public static void executeRetentionWorkflow(String policyId) {
        DocumentRetentionPolicy__c policy = getRetentionPolicy(policyId);
        List<ContentDocument> eligibleDocuments = findEligibleDocuments(policy);
        
        for (ContentDocument doc : eligibleDocuments) {
            RetentionExecutionResult result = processDocumentRetention(doc, policy);
            logRetentionExecution(result);
        }
    }
    
    private static RetentionExecutionResult processDocumentRetention(ContentDocument doc, DocumentRetentionPolicy__c policy) {
        RetentionExecutionResult result = new RetentionExecutionResult();
        result.documentId = doc.Id;
        result.policyId = policy.Id;
        result.executionStartTime = DateTime.now();
        
        try {
            // Step 1: Legal Hold Check
            Boolean isUnderLegalHold = checkLegalHoldStatus(doc.Id);
            result.legalHoldStatus = isUnderLegalHold;
            
            if (isUnderLegalHold) {
                result.action = 'SKIPPED_LEGAL_HOLD';
                result.status = 'COMPLETED';
                return result;
            }
            
            // Step 2: Pre-Archival Validation
            ValidationResult validation = validateDocumentForArchival(doc, policy);
            result.validationResult = validation;
            
            if (!validation.isValid) {
                result.action = 'VALIDATION_FAILED';
                result.status = 'FAILED';
                result.errorMessage = validation.errorMessage;
                return result;
            }
            
            // Step 3: Create Archival Record
            DocumentArchivalRecord__c archivalRecord = createArchivalRecord(doc, policy);
            
            // Step 4: Execute Archival Process
            if (policy.Archive_Before_Deletion__c) {
                ArchivalResult archivalResult = executeDocumentArchival(doc, policy, archivalRecord);
                result.archivalResult = archivalResult;
                
                if (!archivalResult.success) {
                    result.status = 'FAILED';
                    result.errorMessage = archivalResult.errorMessage;
                    return result;
                }
            }
            
            // Step 5: Document Deletion (if enabled)
            if (policy.Auto_Delete_Enabled__c && !policy.Pre_Deletion_Review__c) {
                DeletionResult deletionResult = executeDocumentDeletion(doc, policy, archivalRecord);
                result.deletionResult = deletionResult;
                
                if (deletionResult.success) {
                    archivalRecord.Original_Document_Deleted__c = true;
                    archivalRecord.Deletion_Timestamp__c = DateTime.now();
                }
            }
            
            // Step 6: Compliance Verification
            ComplianceVerificationResult complianceResult = verifyRetentionCompliance(archivalRecord, policy);
            result.complianceResult = complianceResult;
            
            // Step 7: Update Archival Record
            archivalRecord.Final_Status__c = result.status;
            archivalRecord.Execution_Completed__c = DateTime.now();
            archivalRecord.Compliance_Score__c = complianceResult.complianceScore;
            update archivalRecord;
            
            result.status = 'COMPLETED';
            result.action = 'ARCHIVED_AND_PROCESSED';
            
        } catch (Exception e) {
            result.status = 'ERROR';
            result.errorMessage = e.getMessage();
            result.stackTrace = e.getStackTraceString();
            
            // Create error notification
            createRetentionErrorNotification(doc.Id, policy.Id, e);
        }
        
        result.executionEndTime = DateTime.now();
        result.totalExecutionTime = result.executionEndTime.getTime() - result.executionStartTime.getTime();
        
        return result;
    }
    
    private static ArchivalResult executeDocumentArchival(ContentDocument doc, DocumentRetentionPolicy__c policy, DocumentArchivalRecord__c archivalRecord) {
        ArchivalResult result = new ArchivalResult();
        result.startTime = DateTime.now();
        
        try {
            // Get document content
            ContentVersion latestVersion = [
                SELECT Id, VersionData, Title, FileType, ContentSize
                FROM ContentVersion 
                WHERE ContentDocumentId = :doc.Id 
                AND IsLatest = true 
                LIMIT 1
            ];
            
            // Generate document hash for integrity verification
            String documentHash = generateDocumentHash(latestVersion.VersionData);
            
            // Prepare archival payload
            Map<String, Object> archivalPayload = new Map<String, Object>{
                'document_id' => doc.Id,
                'title' => latestVersion.Title,
                'file_type' => latestVersion.FileType,
                'content_size' => latestVersion.ContentSize,
                'document_hash' => documentHash,
                'retention_policy_id' => policy.Id,
                'archive_location' => policy.Archive_Location__c,
                'encryption_required' => policy.Encryption_Required__c,
                'compliance_metadata' => generateComplianceMetadata(doc, policy),
                'archival_timestamp' => DateTime.now().getTime(),
                'org_id' => UserInfo.getOrganizationId()
            };
            
            // Execute archival based on archive location
            switch on policy.Archive_Location__c {
                when 'SALESFORCE_SECURE_STORAGE' {
                    result = archiveToSalesforceStorage(latestVersion, archivalPayload);
                }
                when 'EXTERNAL_CLOUD_STORAGE' {
                    result = archiveToExternalStorage(latestVersion, archivalPayload);
                }
                when 'IMMUTABLE_BLOCKCHAIN_STORAGE' {
                    result = archiveToBlockchainStorage(latestVersion, archivalPayload);
                }
                when 'SNOWFLAKE_ARCHIVE' {
                    result = archiveToSnowflake(latestVersion, archivalPayload);
                }
                when else {
                    throw new ArchivalException('Unsupported archive location: ' + policy.Archive_Location__c);
                }
            }
            
            // Update archival record with results
            archivalRecord.Archive_Reference_Id__c = result.archiveReferenceId;
            archivalRecord.Archive_Hash__c = documentHash;
            archivalRecord.Archive_Size_MB__c = (Double) latestVersion.ContentSize / (1024 * 1024);
            archivalRecord.Archive_Status__c = result.success ? 'ARCHIVED' : 'FAILED';
            
            result.endTime = DateTime.now();
            result.duration = result.endTime.getTime() - result.startTime.getTime();
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
            result.endTime = DateTime.now();
        }
        
        return result;
    }
    
    private static ArchivalResult archiveToSnowflake(ContentVersion version, Map<String, Object> payload) {
        ArchivalResult result = new ArchivalResult();
        
        try {
            // Convert document to base64 for storage
            String base64Content = EncodingUtil.base64Encode(version.VersionData);
            payload.put('document_content', base64Content);
            
            // Make HTTP callout to Snowflake archive endpoint
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:SnowflakeArchive/api/v1/archive-document');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + getSnowflakeToken());
            req.setTimeout(120000); // 2 minutes for large documents
            req.setBody(JSON.serialize(payload));
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                
                result.success = true;
                result.archiveReferenceId = (String) responseData.get('archive_id');
                result.archiveLocation = 'SNOWFLAKE_ARCHIVE';
                result.verificationHash = (String) responseData.get('verification_hash');
                
                System.debug('Successfully archived document to Snowflake: ' + result.archiveReferenceId);
                
            } else {
                throw new CalloutException('Snowflake Archive API Error: ' + res.getStatusCode() + ' - ' + res.getBody());
            }
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Snowflake archival failed: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, result.errorMessage);
        }
        
        return result;
    }
    
    // Comprehensive document lifecycle monitoring
    public class DocumentLifecycleMonitor {
        
        @future(callout=true)
        public static void monitorDocumentCompliance(Set<Id> documentIds) {
            for (Id docId : documentIds) {
                try {
                    DocumentLifecycleStatus status = assessDocumentLifecycleStatus(docId);
                    
                    if (status.requiresAction) {
                        createLifecycleAlert(docId, status);
                    }
                    
                    updateDocumentLifecycleMetrics(docId, status);
                    
                } catch (Exception e) {
                    System.debug(LoggingLevel.ERROR, 'Error monitoring document ' + docId + ': ' + e.getMessage());
                }
            }
        }
        
        private static DocumentLifecycleStatus assessDocumentLifecycleStatus(Id documentId) {
            DocumentLifecycleStatus status = new DocumentLifecycleStatus();
            status.documentId = documentId;
            status.assessmentTime = DateTime.now();
            
            // Get document and related records
            ContentDocument doc = getDocumentWithMetadata(documentId);
            List<DocumentRetentionSchedule__c> schedules = getRetentionSchedules(documentId);
            List<DocumentArchivalRecord__c> archivalRecords = getArchivalRecords(documentId);
            
            // Assess retention compliance
            status.retentionCompliance = assessRetentionCompliance(doc, schedules);
            
            // Check archival status
            status.archivalStatus = assessArchivalStatus(archivalRecords);
            
            // Evaluate security posture
            status.securityPosture = assessDocumentSecurity(documentId);
            
            // Check for upcoming actions
            status.upcomingActions = identifyUpcomingActions(doc, schedules);
            
            // Determine if action is required
            status.requiresAction = status.retentionCompliance.violationsFound || 
                                  status.archivalStatus.failuresDetected || 
                                  status.securityPosture.threatsIdentified ||
                                  !status.upcomingActions.isEmpty();
            
            return status;
        }
    }
    
    // Advanced AI-powered document intelligence integration
    public class DocumentIntelligenceIntegration {
        
        public static void enhanceDocumentWithAI(Id documentId) {
            try {
                // Get document content
                ContentVersion version = [
                    SELECT Id, VersionData, Title, FileType, ContentDocumentId
                    FROM ContentVersion 
                    WHERE ContentDocumentId = :documentId 
                    AND IsLatest = true 
                    LIMIT 1
                ];
                
                // Execute AI analysis pipeline
                AIAnalysisResult analysisResult = executeAIAnalysisPipeline(version);
                
                // Store AI insights
                storeAIInsights(documentId, analysisResult);
                
                // Update document classification
                updateDocumentClassification(documentId, analysisResult);
                
                // Trigger compliance re-evaluation if needed
                if (analysisResult.complianceImpact) {
                    triggerComplianceReEvaluation(documentId);
                }
                
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'AI enhancement failed for document ' + documentId + ': ' + e.getMessage());
                
                // Log AI processing error
                //I'll continue from where the code was cut off and complete the Document Lifecycle Management implementation.
            insert new AIProcessingError__c(
                Document_Id__c = documentId,
                Error_Type__c = 'AI_ENHANCEMENT_FAILURE',
                Error_Message__c = e.getMessage(),
                Stack_Trace__c = e.getStackTraceString(),
                Timestamp__c = DateTime.now(),
                Retry_Count__c = 0,
                Status__c = 'PENDING_RETRY'
            );
        }
    }

    private static AIAnalysisResult executeAIAnalysisPipeline(ContentVersion version) {
        AIAnalysisResult result = new AIAnalysisResult();
        result.documentId = version.ContentDocumentId;
        result.analysisStartTime = DateTime.now();
        
        try {
            // Step 1: Content Extraction and Preprocessing
            String extractedText = extractTextContent(version.VersionData, version.FileType);
            result.extractedTextLength = extractedText.length();
            
            // Step 2: Natural Language Processing
            NLPResult nlpResult = performNLPAnalysis(extractedText);
            result.nlpResult = nlpResult;
            
            // Step 3: Document Classification
            ClassificationResult classification = classifyDocument(extractedText, nlpResult);
            result.classification = classification;
            
            // Step 4: Compliance Analysis
            ComplianceAnalysisResult compliance = analyzeComplianceRequirements(extractedText, classification);
            result.complianceAnalysis = compliance;
            result.complianceImpact = compliance.hasComplianceImplications;
            
            // Step 5: Risk Assessment
            RiskAssessmentResult riskAssessment = assessDocumentRisks(extractedText, classification, compliance);
            result.riskAssessment = riskAssessment;
            
            // Step 6: Generate Vector Embeddings
            VectorEmbeddingResult embeddings = generateVectorEmbeddings(extractedText);
            result.embeddings = embeddings;
            
            // Store embeddings in Snowflake
            storeEmbeddingsInSnowflake(version.ContentDocumentId, embeddings);
            
            result.analysisEndTime = DateTime.now();
            result.totalProcessingTime = result.analysisEndTime.getTime() - result.analysisStartTime.getTime();
            result.success = true;
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
            result.analysisEndTime = DateTime.now();
        }
        
        return result;
    }

    private static void storeAIInsights(Id documentId, AIAnalysisResult analysisResult) {
        try {
            // Create main AI insights record
            DocumentAIInsights__c insights = new DocumentAIInsights__c(
                Document_Id__c = documentId,
                Analysis_Timestamp__c = DateTime.now(),
                Processing_Time_MS__c = analysisResult.totalProcessingTime,
                Document_Classification__c = JSON.serialize(analysisResult.classification),
                NLP_Results__c = JSON.serialize(analysisResult.nlpResult),
                Compliance_Analysis__c = JSON.serialize(analysisResult.complianceAnalysis),
                Risk_Assessment__c = JSON.serialize(analysisResult.riskAssessment),
                Confidence_Score__c = analysisResult.overallConfidenceScore,
                Requires_Review__c = analysisResult.requiresHumanReview,
                AI_Model_Version__c = analysisResult.modelVersion
            );
            insert insights;
            
            // Store detailed classification tags
            if (analysisResult.classification != null && analysisResult.classification.tags != null) {
                List<DocumentClassificationTag__c> tags = new List<DocumentClassificationTag__c>();
                for (String tag : analysisResult.classification.tags) {
                    tags.add(new DocumentClassificationTag__c(
                        Document_Id__c = documentId,
                        AI_Insights__c = insights.Id,
                        Tag_Name__c = tag,
                        Confidence_Score__c = analysisResult.classification.tagConfidences.get(tag),
                        Created_Date__c = DateTime.now()
                    ));
                }
                if (!tags.isEmpty()) {
                    insert tags;
                }
            }
            
            // Store compliance findings
            if (analysisResult.complianceAnalysis != null && analysisResult.complianceAnalysis.findings != null) {
                List<DocumentComplianceFinding__c> findings = new List<DocumentComplianceFinding__c>();
                for (ComplianceFinding finding : analysisResult.complianceAnalysis.findings) {
                    findings.add(new DocumentComplianceFinding__c(
                        Document_Id__c = documentId,
                        AI_Insights__c = insights.Id,
                        Regulation__c = finding.regulation,
                        Finding_Type__c = finding.findingType,
                        Severity__c = finding.severity,
                        Description__c = finding.description,
                        Recommendation__c = finding.recommendation,
                        Confidence_Score__c = finding.confidenceScore,
                        Auto_Actionable__c = finding.autoActionable
                    ));
                }
                if (!findings.isEmpty()) {
                    insert findings;
                }
            }
            
            // Store risk factors
            if (analysisResult.riskAssessment != null && analysisResult.riskAssessment.riskFactors != null) {
                List<DocumentRiskFactor__c> riskFactors = new List<DocumentRiskFactor__c>();
                for (RiskFactor factor : analysisResult.riskAssessment.riskFactors) {
                    riskFactors.add(new DocumentRiskFactor__c(
                        Document_Id__c = documentId,
                        AI_Insights__c = insights.Id,
                        Risk_Category__c = factor.category,
                        Risk_Level__c = factor.level,
                        Impact_Score__c = factor.impactScore,
                        Probability_Score__c = factor.probabilityScore,
                        Mitigation_Strategy__c = factor.mitigationStrategy,
                        Description__c = factor.description
                    ));
                }
                if (!riskFactors.isEmpty()) {
                    insert riskFactors;
                }
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to store AI insights: ' + e.getMessage());
            throw new AIProcessingException('Failed to store AI insights: ' + e.getMessage());
        }
    }
}

// Enhanced Document Version Management System
public class AdvancedVersionControlEngine {
    
    // Create comprehensive document version tree
    public static DocumentVersionNode createVersionTree(Id documentId) {
        DocumentVersionNode rootNode = new DocumentVersionNode();
        rootNode.documentId = documentId;
        rootNode.creationTime = DateTime.now();
        
        try {
            // Get all versions of the document
            List<ContentVersion> versions = [
                SELECT Id, Title, VersionNumber, CreatedDate, CreatedById, 
                       ReasonForChange, ContentSize, FileType, IsLatest
                FROM ContentVersion 
                WHERE ContentDocumentId = :documentId 
                ORDER BY CreatedDate ASC
            ];
            
            // Build version hierarchy
            DocumentVersionTree__c versionTree = new DocumentVersionTree__c(
                Document_Id__c = documentId,
                Total_Versions__c = versions.size(),
                Root_Version_Id__c = !versions.isEmpty() ? versions[0].Id : null,
                Latest_Version_Id__c = getCurrentLatestVersion(versions),
                Tree_Structure__c = buildTreeStructure(versions),
                Created_Date__c = DateTime.now(),
                Last_Updated__c = DateTime.now()
            );
            insert versionTree;
            
            // Create detailed version nodes
            List<DocumentVersionNode__c> versionNodes = new List<DocumentVersionNode__c>();
            for (Integer i = 0; i < versions.size(); i++) {
                ContentVersion version = versions[i];
                versionNodes.add(new DocumentVersionNode__c(
                    Version_Tree__c = versionTree.Id,
                    Content_Version_Id__c = version.Id,
                    Version_Number__c = version.VersionNumber,
                    Parent_Version_Id__c = i > 0 ? versions[i-1].Id : null,
                    Is_Root__c = i == 0,
                    Is_Latest__c = version.IsLatest,
                    Creation_Date__c = version.CreatedDate,
                    Created_By__c = version.CreatedById,
                    Change_Reason__c = version.ReasonForChange,
                    Content_Size__c = version.ContentSize,
                    File_Type__c = version.FileType,
                    Version_Status__c = 'ACTIVE'
                ));
            }
            
            if (!versionNodes.isEmpty()) {
                insert versionNodes;
            }
            
            // Analyze version differences
            analyzeVersionDifferences(versionTree.Id, versions);
            
            rootNode.versionTree = versionTree;
            rootNode.success = true;
            
        } catch (Exception e) {
            rootNode.success = false;
            rootNode.errorMessage = e.getMessage();
            System.debug(LoggingLevel.ERROR, 'Version tree creation failed: ' + e.getMessage());
        }
        
        return rootNode;
    }
    
    private static void analyzeVersionDifferences(Id versionTreeId, List<ContentVersion> versions) {
        List<DocumentVersionDiff__c> diffs = new List<DocumentVersionDiff__c>();
        
        for (Integer i = 1; i < versions.size(); i++) {
            ContentVersion currentVersion = versions[i];
            ContentVersion previousVersion = versions[i-1];
            
            // Calculate differences
            VersionDiffResult diffResult = calculateVersionDifferences(previousVersion, currentVersion);
            
            diffs.add(new DocumentVersionDiff__c(
                Version_Tree__c = versionTreeId,
                Current_Version_Id__c = currentVersion.Id,
                Previous_Version_Id__c = previousVersion.Id,
                Changes_Summary__c = diffResult.changesSummary,
                Content_Changes__c = JSON.serialize(diffResult.contentChanges),
                Metadata_Changes__c = JSON.serialize(diffResult.metadataChanges),
                Size_Change_Bytes__c = currentVersion.ContentSize - previousVersion.ContentSize,
                Change_Type__c = diffResult.changeType,
                Risk_Level__c = diffResult.riskLevel,
                Compliance_Impact__c = diffResult.complianceImpact,
                Analysis_Timestamp__c = DateTime.now()
            ));
        }
        
        if (!diffs.isEmpty()) {
            insert diffs;
        }
    }
    
    // Advanced collaborative editing conflict resolution
    public static ConflictResolutionResult resolveEditingConflicts(Id documentId, List<EditingSession> sessions) {
        ConflictResolutionResult result = new ConflictResolutionResult();
        result.documentId = documentId;
        result.resolutionStartTime = DateTime.now();
        
        try {
            // Identify overlapping editing sessions
            List<EditingConflict> conflicts = identifyConflicts(sessions);
            
            if (conflicts.isEmpty()) {
                result.conflictsFound = false;
                result.resolution = 'NO_CONFLICTS';
                return result;
            }
            
            // Apply AI-powered conflict resolution
            for (EditingConflict conflict : conflicts) {
                ConflictResolution resolution = resolveConflictWithAI(conflict);
                
                // Create conflict resolution record
                DocumentEditingConflict__c conflictRecord = new DocumentEditingConflict__c(
                    Document_Id__c = documentId,
                    Conflict_Type__c = conflict.conflictType,
                    User_A__c = conflict.userA,
                    User_B__c = conflict.userB,
                    Conflict_Section__c = conflict.sectionId,
                    Original_Content__c = conflict.originalContent,
                    User_A_Changes__c = conflict.userAChanges,
                    User_B_Changes__c = conflict.userBChanges,
                    AI_Resolution__c = resolution.resolvedContent,
                    Resolution_Confidence__c = resolution.confidenceScore,
                    Resolution_Method__c = resolution.method,
                    Requires_Human_Review__c = resolution.requiresHumanReview,
                    Resolution_Timestamp__c = DateTime.now(),
                    Status__c = 'RESOLVED'
                );
                
                result.resolvedConflicts.add(conflictRecord);
            }
            
            // Insert all conflict records
            if (!result.resolvedConflicts.isEmpty()) {
                insert result.resolvedConflicts;
            }
            
            // Generate merged document version
            String mergedContent = generateMergedContent(documentId, result.resolvedConflicts);
            
            // Create new version with merged content
            ContentVersion mergedVersion = createMergedVersion(documentId, mergedContent, sessions);
            
            result.mergedVersionId = mergedVersion.Id;
            result.conflictsFound = true;
            result.totalConflicts = conflicts.size();
            result.autoResolvedConflicts = countAutoResolved(result.resolvedConflicts);
            result.requiresReview = countRequiringReview(result.resolvedConflicts);
            result.success = true;
            
            // Notify users of conflict resolution
            notifyUsersOfResolution(sessions, result);
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
            System.debug(LoggingLevel.ERROR, 'Conflict resolution failed: ' + e.getMessage());
        }
        
        result.resolutionEndTime = DateTime.now();
        result.totalResolutionTime = result.resolutionEndTime.getTime() - result.resolutionStartTime.getTime();
        
        return result;
    }
}

// Document Expiration Management System
public class DocumentExpirationEngine {
    
    @future(callout=false)
    public static void processExpiringDocuments(Set<Id> documentIds) {
        for (Id docId : documentIds) {
            try {
                processDocumentExpiration(docId);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Failed to process expiration for document ' + docId + ': ' + e.getMessage());
                
                // Log expiration processing error
                insert new DocumentExpirationError__c(
                    Document_Id__c = docId,
                    Error_Type__c = 'EXPIRATION_PROCESSING_FAILURE',
                    Error_Message__c = e.getMessage(),
                    Stack_Trace__c = e.getStackTraceString(),
                    Timestamp__c = DateTime.now(),
                    Status__c = 'PENDING_RETRY'
                );
            }
        }
    }
    
    private static void processDocumentExpiration(Id documentId) {
        // Get document expiration policy
        DocumentExpirationPolicy__c policy = [
            SELECT Id, Expiration_Date__c, Warning_Period_Days__c, Auto_Archive__c, 
                   Auto_Delete__c, Notification_Recipients__c, Grace_Period_Days__c,
                   Expiration_Action__c, Business_Justification_Required__c
            FROM DocumentExpirationPolicy__c 
            WHERE Document_Id__c = :documentId 
            LIMIT 1
        ];
        
        Date today = Date.today();
        Date expirationDate = policy.Expiration_Date__c;
        Date warningDate = expirationDate.addDays(-(Integer)policy.Warning_Period_Days__c);
        
        //I'll continue from where the Document Expiration Management System was cut off and complete the implementation.
        ExpirationProcessingResult result = new ExpirationProcessingResult();
        result.documentId = documentId;
        result.policyId = policy.Id;
        result.processingStartTime = DateTime.now();
        result.currentDate = today;
        result.expirationDate = expirationDate;

    try {
        // Determine expiration status
        if (today.daysBetween(expirationDate) <= 0) {
            // Document has expired
            result.expirationStatus = 'EXPIRED';
            result.daysOverdue = today.daysBetween(expirationDate) * -1;
            
            // Check if still within grace period
            Date gracePeriodEnd = expirationDate.addDays((Integer)policy.Grace_Period_Days__c);
            if (today <= gracePeriodEnd) {
                result.withinGracePeriod = true;
                result.graceDaysRemaining = today.daysBetween(gracePeriodEnd);
            } else {
                result.withinGracePeriod = false;
                result.graceDaysExceeded = gracePeriodEnd.daysBetween(today);
            }
            
            // Execute expiration actions
            executeExpirationActions(documentId, policy, result);
            
        } else if (today >= warningDate) {
            // Document is in warning period
            result.expirationStatus = 'WARNING';
            result.daysUntilExpiration = today.daysBetween(expirationDate);
            
            // Send warning notifications
            sendExpirationWarnings(documentId, policy, result);
            
        } else {
            // Document is still valid
            result.expirationStatus = 'VALID';
            result.daysUntilWarning = today.daysBetween(warningDate);
            result.daysUntilExpiration = today.daysBetween(expirationDate);
        }
        
        // Update document expiration tracking
        updateExpirationTracking(documentId, result);
        
        result.success = true;
        
    } catch (Exception e) {
        result.success = false;
        result.errorMessage = e.getMessage();
        result.stackTrace = e.getStackTraceString();
    }

    result.processingEndTime = DateTime.now();
    result.totalProcessingTime = result.processingEndTime.getTime() - result.processingStartTime.getTime();

    // Log processing result
    logExpirationProcessingResult(result);
    }

private static void executeExpirationActions(Id documentId, DocumentExpirationPolicy__c policy, ExpirationProcessingResult result) {
    List<String> actionsExecuted = new List<String>();
    
    try {
        // Action 1: Document Access Restriction
        if (policy.Expiration_Action__c.contains('RESTRICT_ACCESS')) {
            restrictDocumentAccess(documentId);
            actionsExecuted.add('ACCESS_RESTRICTED');
        }
        
        // Action 2: Automatic Archival
        if (policy.Auto_Archive__c && policy.Expiration_Action__c.contains('AUTO_ARCHIVE')) {
            ArchivalResult archivalResult = archiveExpiredDocument(documentId, policy);
            if (archivalResult.success) {
                actionsExecuted.add('ARCHIVED');
                result.archivalReferenceId = archivalResult.archiveReferenceId;
            } else {
                result.archivalError = archivalResult.errorMessage;
            }
        }
        
        // Action 3: Automatic Deletion (only if archival successful or not required)
        if (policy.Auto_Delete__c && 
            policy.Expiration_Action__c.contains('AUTO_DELETE') && 
            (!policy.Auto_Archive__c || result.archivalReferenceId != null)) {
            
            DeletionResult deletionResult = deleteExpiredDocument(documentId, policy);
            if (deletionResult.success) {
                actionsExecuted.add('DELETED');
                result.documentDeleted = true;
            } else {
                result.deletionError = deletionResult.errorMessage;
            }
        }
        
        // Action 4: Stakeholder Notifications
        if (policy.Expiration_Action__c.contains('NOTIFY_STAKEHOLDERS')) {
            sendExpirationNotifications(documentId, policy, result);
            actionsExecuted.add('STAKEHOLDERS_NOTIFIED');
        }
        
        // Action 5: Compliance Violation Logging
        if (policy.Business_Justification_Required__c) {
            createComplianceViolationRecord(documentId, policy, result);
            actionsExecuted.add('COMPLIANCE_VIOLATION_LOGGED');
        }
        
        result.actionsExecuted = actionsExecuted;
        
    } catch (Exception e) {
        result.actionExecutionError = e.getMessage();
        System.debug(LoggingLevel.ERROR, 'Failed to execute expiration actions: ' + e.getMessage());
    }
}

private static void updateExpirationTracking(Id documentId, ExpirationProcessingResult result) {
    // Upsert expiration tracking record
    List<DocumentExpirationTracking__c> existingTracking = [
        SELECT Id FROM DocumentExpirationTracking__c 
        WHERE Document_Id__c = :documentId LIMIT 1
    ];
    
    DocumentExpirationTracking__c tracking;
    if (!existingTracking.isEmpty()) {
        tracking = existingTracking[0];
    } else {
        tracking = new DocumentExpirationTracking__c(
            Document_Id__c = documentId
        );
    }
    
    tracking.Expiration_Status__c = result.expirationStatus;
    tracking.Days_Until_Expiration__c = result.daysUntilExpiration;
    tracking.Days_Overdue__c = result.daysOverdue;
    tracking.Within_Grace_Period__c = result.withinGracePeriod;
    tracking.Grace_Days_Remaining__c = result.graceDaysRemaining;
    tracking.Last_Check_Date__c = result.currentDate;
    tracking.Last_Processing_Time__c = DateTime.now();
    tracking.Actions_Executed__c = String.join(result.actionsExecuted, ';');
    tracking.Document_Deleted__c = result.documentDeleted;
    tracking.Archival_Reference_Id__c = result.archivalReferenceId;
    
    upsert tracking;
    result.trackingRecordId = tracking.Id;
}
}
}