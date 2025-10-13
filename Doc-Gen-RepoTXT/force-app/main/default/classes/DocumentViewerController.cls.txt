public with sharing class DocumentViewerController {
    
    @AuraEnabled(cacheable=false)
    public static DocumentDetails getDocumentDetails(Id documentId) {
        try {
            ContentDocument doc = [
                SELECT Id, Title, FileExtension, ContentSize, CreatedDate, 
                       LastModifiedDate, CreatedBy.Name, Description
                FROM ContentDocument 
                WHERE Id = :documentId 
                LIMIT 1
            ];
            
            DocumentDetails details = new DocumentDetails();
            details.id = doc.Id;
            details.title = doc.Title;
            details.fileExtension = doc.FileExtension?.toLowerCase();
            details.contentSize = doc.ContentSize;
            details.createdDate = doc.CreatedDate;
            details.lastModifiedDate = doc.LastModifiedDate;
            details.createdBy = doc.CreatedBy.Name;
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
            data.complianceScore = compliance.Compliance_Score__c?.intValue() ?? 0;
            data.gdprCompliant = compliance.GDPR_Compliant__c ?? false;
            data.hipaaCompliant = compliance.HIPAA_Compliant__c ?? false;
            data.riskScore = compliance.Risk_Score__c ?? 0;
            
            // Parse violations
            if (String.isNotBlank(compliance.Compliance_Violations__c)) {
                data.violations = compliance.Compliance_Violations__c.split(';');
            }
            
            // Generate AI insights
            data.aiInsights = generateAIInsights(documentId, compliance);
            
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
                analytics.totalViews = (Integer) viewStats[0].get('totalViews') ?? 0;
                analytics.lastViewedDate = (DateTime) viewStats[0].get('lastViewed');
            }
            
            // Query download tracking
            List<AggregateResult> downloadStats = [
                SELECT COUNT(Id) totalDownloads
                FROM DocumentDownloadTracking__c 
                WHERE Document_ID__c = :documentId
            ];
            
            if (!downloadStats.isEmpty()) {
                analytics.totalDownloads = (Integer) downloadStats[0].get('totalDownloads') ?? 0;
            }
            
            // Query share tracking
            List<AggregateResult> shareStats = [
                SELECT COUNT(Id) shareCount
                FROM DocumentShareTracking__c 
                WHERE Document_ID__c = :documentId
            ];
            
            if (!shareStats.isEmpty()) {
                analytics.shareCount = (Integer) shareStats[0].get('shareCount') ?? 0;
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
            SELECT Id, Comment_Text__c, CreatedBy.Name, CreatedBy.SmallPhotoUrl,
                   CreatedDate, Parent_Comment__c, Like_Count__c
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
            commentObj.authorName = comment.CreatedBy.Name;
            commentObj.authorPhoto = comment.CreatedBy.SmallPhotoUrl;
            commentObj.createdDate = comment.CreatedDate.format('MMM dd, yyyy HH:mm');
            commentObj.likeCount = (comment.Like_Count__c != null) ? Integer.valueOf(comment.Like_Count__c) : 0;

            // Add replies if they exist
            if (repliesMap.containsKey(comment.Id)) {
                commentObj.replies = new List<DocumentCommentReply>();
                for (DocumentComment__c reply : repliesMap.get(comment.Id)) {
                    DocumentCommentReply replyObj = new DocumentCommentReply();
                    replyObj.id = reply.Id;
                    replyObj.content = reply.Comment_Text__c;
                    replyObj.authorName = reply.CreatedBy.Name;
                    replyObj.authorPhoto = reply.CreatedBy.SmallPhotoUrl;
                    replyObj.createdDate = reply.CreatedDate.format('MMM dd, yyyy HH:mm');
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
