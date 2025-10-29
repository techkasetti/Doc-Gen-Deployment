public with sharing class DocumentViewerController {
    // ----------------------------------------------------
    // Existing/Provided Methods (Enhanced for null safety)
    // ----------------------------------------------------
    @AuraEnabled(cacheable=false)
    public static DocumentDetails getDocumentDetails(Id documentId) {
        try {
            ContentDocument doc = [
                SELECT Id, Title, FileExtension, ContentSize, CreatedDate, LastModifiedDate, CreatedBy.Name, Description
                FROM ContentDocument
                WHERE Id = :documentId
                LIMIT 1
            ];

            DocumentDetails details = new DocumentDetails();
            details.id = doc.Id;
            details.title = doc.Title;
            details.fileExtension = doc.FileExtension == null? null : doc.FileExtension.toLowerCase();
            details.contentSize = doc.ContentSize;
            details.createdDate = doc.CreatedDate;
            details.lastModifiedDate = doc.LastModifiedDate;
            details.createdBy = doc.CreatedBy!= null? doc.CreatedBy.Name : null;
            details.description = doc.Description;

            // Get download URL
            details.downloadUrl = '/sfc/servlet.shepherd/version/download/' + getLatestVersionId(documentId);

            // Get text content for supported file types
            if (isTextFile(doc.FileExtension)) {
                details.textContent = getTextContent(documentId);
            }
            return details;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to get document details: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static ComplianceData getComplianceData(Id documentId) {
        try {
            // Query compliance tracking record
            List<DocumentComplianceTracking__c> complianceRecords = [
                SELECT Id, Compliance_Score__c, GDPR_Compliant__c, HIPAA_Compliant__c,
                       Compliance_Violations__c, AI_Classification__c, Risk_Score__c
                FROM DocumentComplianceTracking__c
                WHERE Document_ID__c = :documentId
                ORDER BY Analysis_Date__c DESC
                LIMIT 1
            ];

            if (complianceRecords.isEmpty()) {
                return null;
            }

            DocumentComplianceTracking__c compliance = complianceRecords[0];
            ComplianceData data = new ComplianceData();
                 data.complianceScore = compliance.Compliance_Score__c == null ? 0 : Integer.valueOf(String.valueOf(compliance.Compliance_Score__c));
                 data.gdprCompliant = compliance.GDPR_Compliant__c == null ? false : Boolean.valueOf(String.valueOf(compliance.GDPR_Compliant__c));
                 data.hipaaCompliant = compliance.HIPAA_Compliant__c == null ? false : Boolean.valueOf(String.valueOf(compliance.HIPAA_Compliant__c));
                 data.riskScore = compliance.Risk_Score__c == null ? 0.0 : Decimal.valueOf(compliance.Risk_Score__c);

            // Parse violations
            if (String.isNotBlank(compliance.Compliance_Violations__c)) {
                data.violations = compliance.Compliance_Violations__c.split(';');
            }
            // Generate AI insights (placeholder)
            data.aiInsights = new List<AIInsight>(); // Placeholder: implement AI insight logic if needed
            return data;
        } catch (Exception e) {
            System.debug('Error getting compliance data: ' + e.getMessage());
            return null;
        }
    }

    @AuraEnabled(cacheable=false)
    public static AnalyticsData getDocumentAnalytics(Id documentId) {
        try {
            AnalyticsData analytics = new AnalyticsData();
            // Query view tracking
            List<AggregateResult> viewStats = [
                SELECT COUNT(Id) totalViews, MAX(View_Date__c) lastViewed
                FROM DocumentViewTracking__c
                WHERE Document_ID__c = :documentId
            ];
            if (!viewStats.isEmpty()) {
                analytics.totalViews = ((Integer) viewStats[0].get('totalViews')) == null? 0 : (Integer) viewStats[0].get('totalViews');
                analytics.lastViewedDate = (DateTime) viewStats[0].get('lastViewed');
            }

            // Query download tracking
            List<AggregateResult> downloadStats = [
                SELECT COUNT(Id) totalDownloads
                FROM DocumentDownloadTracking__c
                WHERE Document_ID__c = :documentId
            ];
            if (!downloadStats.isEmpty()) {
                analytics.totalDownloads = ((Integer) downloadStats[0].get('totalDownloads')) == null? 0 : (Integer) downloadStats[0].get('totalDownloads');
            }

            // Query share tracking
            List<AggregateResult> shareStats = [
                SELECT COUNT(Id) shareCount
                FROM DocumentShareTracking__c
                WHERE Document_ID__c = :documentId
            ];
            if (!shareStats.isEmpty()) {
                analytics.shareCount = ((Integer) shareStats[0].get('shareCount')) == null? 0 : (Integer) shareStats[0].get('shareCount');
            }
            return analytics;
        } catch (Exception e) {
            System.debug('Error getting analytics data: ' + e.getMessage());
            return new AnalyticsData();
        }
    }

    @AuraEnabled(cacheable=false)
    public static List<DocumentComment> getDocumentComments(Id documentId) {
        try {
            List<DocumentComment> comments = new List<DocumentComment>();
            // Query comments
            List<DocumentComment__c> commentRecords = [
                SELECT Id, Comment_Text__c, CreatedBy.Name, CreatedBy.SmallPhotoUrl, CreatedDate, Parent_Comment__c, Like_Count__c
                FROM DocumentComment__c
                WHERE Document_ID__c = :documentId
                ORDER BY CreatedDate DESC
            ];

            Map<Id, List<DocumentComment__c>> repliesMap = new Map<Id, List<DocumentComment__c>>();
            List<DocumentComment__c> topLevelComments = new List<DocumentComment__c>();

            for (DocumentComment__c comment : commentRecords) {
                if (comment.Parent_Comment__c == null) {
                    topLevelComments.add(comment);
                } else {
                    if (!repliesMap.containsKey(comment.Parent_Comment__c)) {
                        repliesMap.put(comment.Parent_Comment__c, new List<DocumentComment__c>());
                    }
                    repliesMap.get(comment.Parent_Comment__c).add(comment);
                }
            }

            // Convert to wrapper objects
            for (DocumentComment__c comment : topLevelComments) {
                DocumentComment commentObj = new DocumentComment();
                commentObj.id = comment.Id;
                commentObj.content = comment.Comment_Text__c;
                commentObj.authorName = comment.CreatedBy!= null? comment.CreatedBy.Name : null;
                commentObj.authorPhoto = comment.CreatedBy!= null? comment.CreatedBy.SmallPhotoUrl : null;
                commentObj.createdDate = comment.CreatedDate!= null? comment.CreatedDate.format('MMM dd, yyyy HH:mm') : null;
                commentObj.likeCount = comment.Like_Count__c == null? 0 : Integer.valueOf(comment.Like_Count__c);

                // Add replies if they exist
                if (repliesMap.containsKey(comment.Id)) {
                    commentObj.replies = new List<DocumentCommentReply>();
                    for (DocumentComment__c reply : repliesMap.get(comment.Id)) {
                        DocumentCommentReply replyObj = new DocumentCommentReply();
                        replyObj.id = reply.Id;
                        replyObj.content = reply.Comment_Text__c;
                        replyObj.authorName = reply.CreatedBy!= null? reply.CreatedBy.Name : null;
                        replyObj.authorPhoto = reply.CreatedBy!= null? reply.CreatedBy.SmallPhotoUrl : null;
                        replyObj.createdDate = reply.CreatedDate!= null? reply.CreatedDate.format('MMM dd, yyyy HH:mm') : null;
                        commentObj.replies.add(replyObj);
                    }
                }
                comments.add(commentObj);
            }
            return comments;
        } catch (Exception e) {
            System.debug('Error getting comments: ' + e.getMessage());
            return new List<DocumentComment>();
        }
    }

    // ----------------------------------------------------
    // Missing Methods (Requested and implemented)
    // ----------------------------------------------------
        @AuraEnabled
        public static Boolean deleteComment(Id commentId) {
            try {
                if (commentId == null) {
                    throw new AuraHandledException('Comment ID is required');
                }
                // Check if object exists
                if (!Schema.getGlobalDescribe().containsKey('DocumentComment__c')) {
                    throw new AuraHandledException('DocumentComment__c object not available. Cannot delete comment.');
                }
                // Find replies to this comment
                List<DocumentComment__c> toDelete = [
                    SELECT Id FROM DocumentComment__c WHERE Id = :commentId OR Parent_Comment__c = :commentId
                ];
                if (!toDelete.isEmpty()) {
                    delete toDelete;
                }
                return true;
            } catch (Exception e) {
                throw new AuraHandledException('Failed to delete comment: ' + e.getMessage());
            }
        }

    @AuraEnabled
    public static Boolean addDocumentComment(Id documentId, String commentText, Id parentCommentId) {
        try {
            if (documentId == null || String.isBlank(commentText)) {
                throw new AuraHandledException('Document ID and comment text are required');
            }
            if (!Schema.getGlobalDescribe().containsKey('DocumentComment__c')) {
                throw new AuraHandledException('DocumentComment__c object not available. Cannot save comment.');
            }
            
            DocumentComment__c rec = new DocumentComment__c(
                Document_ID__c = documentId,
                Comment_Text__c = commentText,
                Parent_Comment__c = parentCommentId
            );
            insert rec;
            return true;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to add comment: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean shareDocument(Id documentId, String recipientEmails, String message) {
        try {
            if (documentId == null || String.isBlank(recipientEmails)) {
                throw new AuraHandledException('Document ID and recipient emails are required');
            }
            // Logic to create a document share tracking record or send an email notification
            if (Schema.getGlobalDescribe().containsKey('DocumentShareTracking__c')) {
                DocumentShareTracking__c s = new DocumentShareTracking__c(
                    Document_ID__c = documentId,
                    Recipient_Emails__c = recipientEmails,
                    Message__c = message,
                    Share_Date__c = DateTime.now()
                );
                insert s;
            }
            // In a full implementation, actual email sending/sharing permissions would occur here.
            return true;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to share document: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean updateAnalytics(Id documentId, String actionType) {
        try {
            if (documentId == null || String.isBlank(actionType)) {
                throw new AuraHandledException('Document ID and actionType are required');
            }
            String t = actionType.toUpperCase();
            
            if (t == 'VIEW') {
                if (Schema.getGlobalDescribe().containsKey('DocumentViewTracking__c')) {
                    DocumentViewTracking__c v = new DocumentViewTracking__c(
                        Document_ID__c = documentId,
                        View_Date__c = Datetime.now()
                    );
                    insert v;
                }
            } else if (t == 'DOWNLOAD') {
                if (Schema.getGlobalDescribe().containsKey('DocumentDownloadTracking__c')) {
                    DocumentDownloadTracking__c d = new DocumentDownloadTracking__c(
                        Document_ID__c = documentId,
                        Download_Date__c = Datetime.now()
                    );
                    insert d;
                }
            }
            // Note: SHARE action tracking is already handled in shareDocument for complex flows.

            return true;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to update analytics: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static List<DocumentVersion> getVersionHistory(String documentId) {
        List<DocumentVersion> versions = new List<DocumentVersion>();
        try {
            // Using ContentVersion object which tracks standard version history
            List<ContentVersion> cvRecords = [
                SELECT Id, Title, ContentSize, VersionNumber, CreatedDate, CreatedBy.Name, Description, PathOnClient
                FROM ContentVersion
                WHERE ContentDocumentId = :documentId
                ORDER BY VersionNumber DESC
            ];

            for (ContentVersion cv : cvRecords) {
                DocumentVersion version = new DocumentVersion();
                version.id = cv.Id;
                version.versionNumber = 'v' + cv.VersionNumber;
                version.modifiedDate = cv.CreatedDate;
                version.modifiedBy = cv.CreatedBy!= null? cv.CreatedBy.Name : null;
                version.contentSize = cv.ContentSize;
                version.comments = cv.Description; // Use Description for general comments/summary
                version.downloadUrl = '/sfc/servlet.shepherd/version/download/' + cv.Id;
                versions.add(version);
            }
        } catch (Exception e) {
            System.debug('Error retrieving document version history: ' + e.getMessage());
        }
        return versions;
    }
    
    // ----------------------------------------------------
    // Internal Helper Methods (Minimally defined)
    // ----------------------------------------------------

    private static Boolean isTextFile(String fileExt) {
        if (String.isBlank(fileExt)) return false;
        String ext = fileExt.toLowerCase();
        return ext == 'txt' || ext == 'csv' || ext == 'log' || ext == 'html' || ext == 'xml';
    }
    
    private static String getLatestVersionId(Id documentId) {
        try {
            ContentVersion cv = [
                SELECT Id FROM ContentVersion 
                WHERE ContentDocumentId = :documentId 
                AND IsLatest = true LIMIT 1
            ];
            return cv!= null? cv.Id : null;
        } catch (Exception e) {
            return null;
        }
    }

    private static String getTextContent(Id documentId) {
        try {
            ContentVersion cv = [
                SELECT VersionData FROM ContentVersion 
                WHERE ContentDocumentId = :documentId 
                AND IsLatest = true LIMIT 1
            ];
            if (cv!= null && cv.VersionData!= null) {
                return cv.VersionData.toString();
            }
            return null;
        } catch (Exception e) {
            System.debug('Error extracting text content: ' + e.getMessage());
            return null;
        }
    }

   

    // ----------------------------------------------------
    // Inner Wrapper Classes
    // ----------------------------------------------------

    public class DocumentDetails {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String fileExtension { get; set; }
        @AuraEnabled public Integer contentSize { get; set; }
        @AuraEnabled public DateTime createdDate { get; set; }
        @AuraEnabled public DateTime lastModifiedDate { get; set; }
        @AuraEnabled public String createdBy { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String downloadUrl { get; set; }
        @AuraEnabled public String textContent { get; set; }
    }

    public class ComplianceData {
        @AuraEnabled public Integer complianceScore { get; set; }
        @AuraEnabled public Boolean gdprCompliant { get; set; }
        @AuraEnabled public Boolean hipaaCompliant { get; set; }
        @AuraEnabled public Decimal riskScore { get; set; }
        @AuraEnabled public List<String> violations { get; set; }
        @AuraEnabled public List<AIInsight> aiInsights { get; set; }

        public ComplianceData() {
            this.violations = new List<String>();
            this.aiInsights = new List<AIInsight>();
        }
    }

    public class AnalyticsData {
        @AuraEnabled public Integer totalViews { get; set; }
        @AuraEnabled public Integer totalDownloads { get; set; }
        @AuraEnabled public Integer shareCount { get; set; }
        @AuraEnabled public DateTime lastViewedDate { get; set; }

        public AnalyticsData() {
            this.totalViews = 0;
            this.totalDownloads = 0;
            this.shareCount = 0;
        }
    }

    public class DocumentComment {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String content { get; set; }
        @AuraEnabled public String authorName { get; set; }
        @AuraEnabled public String authorPhoto { get; set; }
        @AuraEnabled public String createdDate { get; set; }
        @AuraEnabled public Integer likeCount { get; set; }
        @AuraEnabled public List<DocumentCommentReply> replies { get; set; }

        public DocumentComment() {
            this.replies = new List<DocumentCommentReply>();
        }
    }

    public class DocumentCommentReply {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String content { get; set; }
        @AuraEnabled public String authorName { get; set; }
        @AuraEnabled public String authorPhoto { get; set; }
        @AuraEnabled public String createdDate { get; set; }
    }

    public class DocumentVersion {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String versionNumber { get; set; }
        @AuraEnabled public DateTime modifiedDate { get; set; }
        @AuraEnabled public String modifiedBy { get; set; }
        @AuraEnabled public Integer contentSize { get; set; }
        @AuraEnabled public String comments { get; set; }
        @AuraEnabled public String downloadUrl { get; set; }
    }

    public class AIInsight {
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public String text { get; set; }
        @AuraEnabled public Integer confidence { get; set; }
    }
}