public with sharing class ComplianceReportController {
    public String documentId { get; set; }
    public String documentTitle { get; set; }
    public Integer documentSize { get; set; }
    public DateTime createdDate { get; set; }
    public DateTime lastModifiedDate { get; set; }
    public DateTime analysisDate { get; set; }
    public Decimal complianceScore { get; set; }
    public Boolean gdprCompliant { get; set; }
    public Boolean hipaaCompliant { get; set; }
    public Decimal gdprScore { get; set; }
    public Decimal hipaaScore { get; set; }
    public Boolean overallCompliant { get; set; }
    public Integer violationCount { get; set; }
    public List<String> violations { get; set; }
    public List<String> recommendations { get; set; }
    
    public ComplianceReportController() {
        // Get parameters
        documentId = ApexPages.currentPage().getParameters().get('documentId');
        String complianceScoreParam = ApexPages.currentPage().getParameters().get('complianceScore');
        String gdprCompliantParam = ApexPages.currentPage().getParameters().get('gdprCompliant');
        String hipaaCompliantParam = ApexPages.currentPage().getParameters().get('hipaaCompliant');
        
        // Set compliance data from parameters
        if (complianceScoreParam != null) {
            complianceScore = Decimal.valueOf(complianceScoreParam);
        }
        gdprCompliant = gdprCompliantParam == 'true';
        hipaaCompliant = hipaaCompliantParam == 'true';
        
        // Load detailed compliance data
        loadComplianceDetails();
        loadDocumentMetadata();
        generateRecommendations();
        
        // Calculate overall compliance
        overallCompliant = complianceScore >= 80;
    }
    
    private void loadComplianceDetails() {
        try {
            // Load latest compliance analysis
            List<DocumentComplianceTracking__c> complianceRecords = [
            SELECT Compliance_Score__c, GDPR_Compliant__c, HIPAA_Compliant__c, 
                   Analysis_Date__c, Violation_Details__c
            FROM DocumentComplianceTracking__c
            WHERE Document_ID__c = :documentId
            ORDER BY Analysis_Date__c DESC
            LIMIT 1
        ];
            
            if (!complianceRecords.isEmpty()) {
                DocumentComplianceTracking__c record = complianceRecords[0];
                analysisDate = record.Analysis_Date__c;
                
                // Calculate individual regulation scores
                gdprScore = gdprCompliant ? 95.0 : 45.0;
                hipaaScore = hipaaCompliant ? 90.0 : 40.0;
                
                // Load violations
                violations = new List<String>();
                if (!gdprCompliant) {
                    violations.addAll(getGDPRViolations());
                }
                if (!hipaaCompliant) {
                    violations.addAll(getHIPAAViolations());
                }
                violationCount = violations.size();
            } else {
                // Set defaults if no compliance data found
                analysisDate = DateTime.now();
                gdprScore = 0;
                hipaaScore = 0;
                violations = new List<String>{'No compliance analysis data available'};
                violationCount = 1;
            }
        } catch (Exception e) {
            System.debug('Error loading compliance details: ' + e.getMessage());
            violations = new List<String>{'Error loading compliance data: ' + e.getMessage()};
            violationCount = 1;
        }
    }
    
    private void loadDocumentMetadata() {
        try {
            List<ContentDocument> documents = [
            SELECT Title, ContentSize, CreatedDate, LastModifiedDate
            FROM ContentDocument
            WHERE Id = :documentId
            LIMIT 1
        ];
            
            if (!documents.isEmpty()) {
                ContentDocument doc = documents[0];
                documentTitle = doc.Title;
                documentSize = doc.ContentSize;
                createdDate = doc.CreatedDate;
                lastModifiedDate = doc.LastModifiedDate;
            } else {
                documentTitle = 'Unknown Document';
                documentSize = 0;
                createdDate = DateTime.now();
                lastModifiedDate = DateTime.now();
            }
        } catch (Exception e) {
            System.debug('Error loading document metadata: ' + e.getMessage());
            documentTitle = 'Error Loading Document';
        }
    }
    
    private List<String> getGDPRViolations() {
        return new List<String>{
            'Missing explicit consent mechanisms for data processing',
            'Insufficient data subject rights documentation',
            'Missing privacy policy or inadequate privacy notices',
            'No clear lawful basis specified for data processing',
            'Missing data retention and deletion policies'
        };
    }
    
    private List<String> getHIPAAViolations() {
        return new List<String>{
            'Missing business associate agreement clauses',
            'Insufficient administrative safeguards documentation',
            'Inadequate physical safeguards specifications',
            'Missing technical safeguards requirements',
            'No breach notification procedures defined'
        };
    }
    
    private void generateRecommendations() {
        recommendations = new List<String>();
        
        if (!gdprCompliant) {
            recommendations.add('Implement explicit consent collection mechanisms');
            recommendations.add('Add comprehensive data subject rights section');
            recommendations.add('Include detailed privacy policy with data processing purposes');
            recommendations.add('Specify lawful basis for each type of data processing');
        }
        
        if (!hipaaCompliant) {
            recommendations.add('Include business associate agreement templates');
            recommendations.add('Add administrative safeguards checklist');
            recommendations.add('Specify physical security requirements');
            recommendations.add('Implement technical safeguards documentation');
        }
        
        if (complianceScore < 80) {
            recommendations.add('Conduct comprehensive legal review');
            recommendations.add('Implement automated compliance monitoring');
            recommendations.add('Schedule regular compliance assessments');
        }
        
        // Always add general recommendations
        recommendations.add('Maintain audit trail of all document changes');
        recommendations.add('Implement version control for compliance tracking');
        recommendations.add('Schedule quarterly compliance reviews');
    }
}