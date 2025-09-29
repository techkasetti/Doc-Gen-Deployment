    /**
     * @description Advanced Document View Controller with AI-Powered Analytics and Real-time Collaboration
     * @author Anara AI Development Team
     * @version 1.0
     * @since 2024
     */
    public with sharing class DocumentViewController {
        
        // Document Retrieval and Processing
        @AuraEnabled(cacheable=false)
        public static DocumentViewWrapper getDocumentContent(String documentId) {
            try {
                // Validate input parameters
                if (String.isBlank(documentId)) {
                    throw new AuraHandledException('Document ID is required');
                }
                
                // Initialize document wrapper
                DocumentViewWrapper wrapper = new DocumentViewWrapper();
                
                // Retrieve document with comprehensive metadata
                Document__c doc = [
                SELECT Id, Name, Title__c, Document_Type__c, Status__c, Version__c,
                       Content__c, CreatedDate, LastModifiedDate, Last_Saved__c,
                       Jurisdiction__c, Retention_Period__c, Expiration_Date__c,
                       Legal_Hold_Status__c, Archive_Status__c, View_Count__c,
                       Average_Read_Time__c, Content_Type__c, PDF_URL__c,
                       HTML_Content__c, Document_Hash__c, Security_Level__c,
                       Compliance_Score__c, Risk_Score__c, Risk_Level__c,
                       AI_Analysis_Complete__c, Collaboration_Enabled__c
                FROM Document__c 
                WHERE Id = :documentId 
                LIMIT 1
            ];
                
                // Populate basic document information
                wrapper.documentId     = doc.Id;
                wrapper.title          = doc.Title__c;
                wrapper.type           = doc.Document_Type__c;
                wrapper.status         = doc.Status__c;
                wrapper.version        = doc.Version__c;
                wrapper.createdDate    = doc.CreatedDate.format('MMM dd, yyyy');
                wrapper.lastModified   = doc.LastModifiedDate.format('MMM dd, yyyy HH:mm');
                wrapper.lastSaved      = (doc.Last_Saved__c != null) ? doc.Last_Saved__c.format('MMM dd, yyyy HH:mm') : null;
                
                // Populate additional metadata
                wrapper.jurisdiction       = doc.Jurisdiction__c;
                wrapper.retentionPeriod    = doc.Retention_Period__c;
                wrapper.expirationDate     = (doc.Expiration_Date__c != null) ? doc.Expiration_Date__c.format('MMM dd, yyyy') : null;
                wrapper.legalHoldStatus    = doc.Legal_Hold_Status__c;
                wrapper.archiveStatus      = doc.Archive_Status__c;
                wrapper.viewCount          = doc.View_Count__c;
                wrapper.averageReadTime    = doc.Average_Read_Time__c;
                wrapper.contentType        = doc.Content_Type__c;
                wrapper.pdfUrl             = doc.PDF_URL__c;
                wrapper.htmlContent        = doc.HTML_Content__c;
                wrapper.documentHash       = doc.Document_Hash__c;
                wrapper.securityLevel      = doc.Security_Level__c;
                wrapper.complianceScore    = doc.Compliance_Score__c;
                wrapper.riskScore          = doc.Risk_Score__c;
                wrapper.riskLevel          = doc.Risk_Level__c;
                wrapper.aiAnalysisComplete = doc.AI_Analysis_Complete__c;
                wrapper.collaborationEnabled = doc.Collaboration_Enabled__c;
                
                return wrapper;
            } catch (Exception e) {
                throw new AuraHandledException('Error retrieving document content: ' + e.getMessage());
            }
        }
        
        
        @AuraEnabled(cacheable=true)
        public static DocumentWrapper getDocumentContent(Id documentId) {
            try {
                ContentDocument doc = [
                SELECT Id, Title, FileExtension, ContentSize, CreatedDate, LastModifiedDate,
                       CreatedBy.Name, LastModifiedBy.Name
                FROM ContentDocument 
                WHERE Id = :documentId 
                LIMIT 1
            ];
                
                ContentVersion version = [
                SELECT Id, VersionData, VersionNumber, ReasonForChange
                FROM ContentVersion 
                WHERE ContentDocumentId = :documentId 
                AND IsLatest = true 
                LIMIT 1
            ];
                
                DocumentWrapper wrapper = new DocumentWrapper();
                wrapper.documentId = doc.Id;
                wrapper.title = doc.Title;
                wrapper.fileExtension = doc.FileExtension;
                wrapper.contentSize = doc.ContentSize;
                wrapper.createdBy = doc.CreatedBy.Name;
                wrapper.createdDate = doc.CreatedDate.format('MMM dd, yyyy');
                wrapper.lastModifiedBy = doc.LastModifiedBy.Name;
                wrapper.versionNumber = version.VersionNumber;
                wrapper.reasonForChange = version.ReasonForChange;
                
                // Get document content based on file type
                if (doc.FileExtension == 'pdf') {
                    wrapper.content = EncodingUtil.base64Encode(version.VersionData);
                    wrapper.contentType = 'application/pdf';
                } else {
                    wrapper.content = version.VersionData.toString();
                    wrapper.contentType = 'text/plain';
                }
                
                return wrapper;
                
            } catch (Exception e) {
                throw new AuraHandledException('Error retrieving document: ' + e.getMessage());
            }
        }
        @AuraEnabled
        public static ComplianceAnalysisResult analyzeDocumentCompliance(Id documentId) {
            try {
                ComplianceAnalysisResult result = new ComplianceAnalysisResult();
                
                // Get document content
                ContentVersion version = [
                SELECT VersionData, ContentDocument.Title
                FROM ContentVersion 
                WHERE ContentDocumentId = :documentId 
                AND IsLatest = true 
                LIMIT 1
            ];
                
                String documentContent = version.VersionData.toString();
                
                // Analyze compliance using AI service
                ComplianceEngine engine = new ComplianceEngine();
                result = engine.analyzeCompliance(documentContent, documentId);
                
                // Store compliance results
                DocumentComplianceTracking__c tracking = new DocumentComplianceTracking__c();
                tracking.Document_ID__c = documentId;
                tracking.Compliance_Score__c = result.complianceScore;
                tracking.GDPR_Compliant__c = result.gdprCompliant;
                tracking.HIPAA_Compliant__c = result.hipaaCompliant;
                tracking.Analysis_Date__c = System.now();
                insert tracking;
                
                return result;
                
            } catch (Exception e) {
                throw new AuraHandledException('Compliance analysis failed: ' + e.getMessage());
            }
        }
        
        @AuraEnabled
        public static String updateSignatureStatus(Id documentId, String signatureStatus, String signerEmail) {
            try {
                DocumentSignatureTracking__c signatureRecord = new DocumentSignatureTracking__c();
                signatureRecord.Document_ID__c = documentId;
                signatureRecord.Signer_Email__c = signerEmail;
                signatureRecord.Signature_Status__c = signatureStatus;
                signatureRecord.Signature_Date__c = System.now();
                signatureRecord.IP_Address__c = ''; // Would be populated from request context
                insert signatureRecord;
                
                // Update document status
                ContentDocument doc = [SELECT Id FROM ContentDocument WHERE Id = :documentId];
                // Custom field update logic would go here
                
                return 'SUCCESS';
                
            } catch (Exception e) {
                throw new AuraHandledException('Signature update failed: ' + e.getMessage());
            }
        }
        
        @AuraEnabled(cacheable=true)
        public static String generateDocumentHash(Id documentId) {
            try {
                ContentVersion version = [
                SELECT VersionData 
                FROM ContentVersion 
                WHERE ContentDocumentId = :documentId 
                AND IsLatest = true 
                LIMIT 1
            ];
                
                Blob documentBlob = version.VersionData;
                Blob hashBlob = Crypto.generateDigest('SHA-256', documentBlob);
                String documentHash = EncodingUtil.convertToHex(hashBlob);
                
                // Store hash for integrity verification
                DocumentIntegrityTracking__c integrity = new DocumentIntegrityTracking__c();
                integrity.Document_ID__c = documentId;
                integrity.Document_Hash__c = documentHash;
                integrity.Hash_Algorithm__c = 'SHA-256';
                integrity.Generated_Date__c = System.now();
                insert integrity;
                
                return documentHash;
                
            } catch (Exception e) {
                throw new AuraHandledException('Hash generation failed: ' + e.getMessage());
            }
        }
        
        @AuraEnabled
        public static void trackDocumentView(Id documentId, Id userId) {
            try {
                DocumentViewTracking__c viewRecord = new DocumentViewTracking__c();
                viewRecord.Document_ID__c = documentId;
                viewRecord.User_ID__c = userId;
                viewRecord.View_Date__c = System.now();
                viewRecord.Session_Duration__c = 0; // Would be updated on session end
                insert viewRecord;
                
            } catch (Exception e) {
                System.debug('View tracking failed: ' + e.getMessage());
            }
        }
        
        @AuraEnabled(cacheable=true)
        public static List<CollaboratorWrapper> getCollaborators(Id documentId) {
            try {
                List<CollaboratorWrapper> collaborators = new List<CollaboratorWrapper>();
                
                List<ContentDocumentLink> links = [
                SELECT LinkedEntityId, LinkedEntity.Name, LinkedEntity.Type,
                       ShareType, Visibility
                FROM ContentDocumentLink 
                WHERE ContentDocumentId = :documentId
            ];
                
                for (ContentDocumentLink link : links) {
                    CollaboratorWrapper wrapper = new CollaboratorWrapper();
                    wrapper.entityId = link.LinkedEntityId;
                    wrapper.entityName = link.LinkedEntity.Name;
                    wrapper.entityType = link.LinkedEntity.Type;
                    wrapper.shareType = link.ShareType;
                    wrapper.visibility = link.Visibility;
                    collaborators.add(wrapper);
                }
                
                return collaborators;
                
            } catch (Exception e) {
                throw new AuraHandledException('Error retrieving collaborators: ' + e.getMessage());
            }
        }
        
        @AuraEnabled
        public static String exportToPDF(Id documentId, Map<String, Object> exportOptions) {
            try {
                // Get document content
                DocumentWrapper docWrapper = getDocumentContent(documentId);
                
                // Use PDF generation service
                PDFGenerationService pdfService = new PDFGenerationService();
                Blob pdfBlob = pdfService.convertToPDF(docWrapper.content, exportOptions);
                
                // Create new PDF version
                ContentVersion pdfVersion = new ContentVersion();
                pdfVersion.ContentDocumentId = documentId;
                pdfVersion.VersionData = pdfBlob;
                pdfVersion.Title = docWrapper.title + '_Export.pdf';
                pdfVersion.PathOnClient = docWrapper.title + '_Export.pdf';
                insert pdfVersion;
                
                return pdfVersion.Id;
                
            } catch (Exception e) {
                throw new AuraHandledException('PDF export failed: ' + e.getMessage());
            }
        }
        
        // Wrapper Classes
        public class DocumentWrapper {
            @AuraEnabled public Id documentId { get; set; }
            @AuraEnabled public String title { get; set; }
            @AuraEnabled public String fileExtension { get; set; }
            @AuraEnabled public Integer contentSize { get; set; }
            @AuraEnabled public String createdBy { get; set; }
            @AuraEnabled public String createdDate { get; set; }
            @AuraEnabled public String lastModifiedBy { get; set; }
            @AuraEnabled public Integer versionNumber { get; set; }
            @AuraEnabled public String reasonForChange { get; set; }
            @AuraEnabled public String content { get; set; }
            @AuraEnabled public String contentType { get; set; }
        }
        
        public class CollaboratorWrapper {
            @AuraEnabled public Id entityId { get; set; }
            @AuraEnabled public String entityName { get; set; }
            @AuraEnabled public String entityType { get; set; }
            @AuraEnabled public String shareType { get; set; }
            @AuraEnabled public String visibility { get; set; }
        }
        
        public class ComplianceAnalysisResult {
            @AuraEnabled public Decimal complianceScore { get; set; }
            @AuraEnabled public Boolean gdprCompliant { get; set; }
            @AuraEnabled public Boolean hipaaCompliant { get; set; }
            @AuraEnabled public List<String> violations { get; set; }
            @AuraEnabled public List<String> recommendations { get; set; }
           
        // Wrapper class
        public class DocumentViewWrapper {
            @AuraEnabled public String documentId;
            @AuraEnabled public String title;
            @AuraEnabled public String type;
            @AuraEnabled public String status;
            @AuraEnabled public String version;
            @AuraEnabled public String createdDate;
            @AuraEnabled public String lastModified;
            @AuraEnabled public String lastSaved;
            @AuraEnabled public String jurisdiction;
            @AuraEnabled public String retentionPeriod;
            @AuraEnabled public String expirationDate;
            @AuraEnabled public String legalHoldStatus;
            @AuraEnabled public String archiveStatus;
            @AuraEnabled public Integer viewCount;
            @AuraEnabled public Decimal averageReadTime;
            @AuraEnabled public String contentType;
            @AuraEnabled public String pdfUrl;
            @AuraEnabled public String htmlContent;
            @AuraEnabled public String documentHash;
            @AuraEnabled public String securityLevel;
            @AuraEnabled public Decimal complianceScore;
            @AuraEnabled public Decimal riskScore;
            @AuraEnabled public String riskLevel;
            @AuraEnabled public Boolean aiAnalysisComplete;
            @AuraEnabled public Boolean collaborationEnabled;
        }
        }
    }
    
    
