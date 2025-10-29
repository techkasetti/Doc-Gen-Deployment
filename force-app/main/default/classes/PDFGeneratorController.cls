public with sharing class PDFGeneratorController {
    public String documentContent { get; set; }
    public String documentTitle { get; set; }
    public String orientation { get; set; }
    public String margin { get; set; }
    public String watermark { get; set; }
    public String exportId { get; set; }
    public Boolean showCompliance { get; set; }
    public Boolean gdprCompliant { get; set; }
    public Boolean hipaaCompliant { get; set; }
    public Decimal complianceScore { get; set; }
    
    public PDFGeneratorController() {
        // Get parameters from URL
        documentContent = ApexPages.currentPage().getParameters().get('content');
        documentTitle = ApexPages.currentPage().getParameters().get('title');
        orientation = ApexPages.currentPage().getParameters().get('orientation');
        margin = ApexPages.currentPage().getParameters().get('margin');
        watermark = ApexPages.currentPage().getParameters().get('watermark');
        
        // Generate export ID
        exportId = generateExportId();
        
        // Get compliance data if requested
        String showComplianceParam = ApexPages.currentPage().getParameters().get('showCompliance');
        showCompliance = showComplianceParam == 'true';
        
        if (showCompliance) {
            String documentId = ApexPages.currentPage().getParameters().get('documentId');
            if (documentId != null) {
                loadComplianceData(documentId);
            }
        }
        
        // Set defaults
        if (documentTitle == null) documentTitle = 'Untitled Document';
        if (orientation == null) orientation = 'portrait';
        if (margin == null) margin = '1in';
    }
    
    private String generateExportId() {
        return 'EXP-' + String.valueOf(DateTime.now().getTime()).substring(8);
    }
    
    private void loadComplianceData(String documentId) {
        try {
            List<DocumentComplianceTracking__c> complianceRecords = [
                SELECT Compliance_Score__c, GDPR_Compliant__c, HIPAA_Compliant__c
                FROM DocumentComplianceTracking__c 
                WHERE Document_ID__c = :documentId 
                ORDER BY Analysis_Date__c DESC 
                LIMIT 1
            ];
            
            if (!complianceRecords.isEmpty()) {
                DocumentComplianceTracking__c record = complianceRecords[0];

                // ✅ Convert String fields to matching data types safely
                if (record.Compliance_Score__c != null) {
                    try {
                        complianceScore = Decimal.valueOf(record.Compliance_Score__c);
                    } catch (Exception e) {
                        complianceScore = 0; // default if invalid
                    }
                }

                if (record.GDPR_Compliant__c != null) {
                    gdprCompliant = (record.GDPR_Compliant__c.toLowerCase() == 'true');
                }

                if (record.HIPAA_Compliant__c != null) {
                    hipaaCompliant = (record.HIPAA_Compliant__c.toLowerCase() == 'true');
                }
            }

        } catch (Exception e) {
            System.debug('Error loading compliance data: ' + e.getMessage());
            showCompliance = false;
        }
    }
}