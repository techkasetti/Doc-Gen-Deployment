public with sharing class PDFGenerationService {
    
    public Blob convertToPDF(String content, Map<String, Object> exportOptions) {
        try {
            // Create PDF page with content
            PageReference pdfPage = new PageReference('/apex/PDFGeneratorPage');
            pdfPage.getParameters().put('content', content);
            
            // Apply export options
            if (exportOptions.containsKey('orientation')) {
                pdfPage.getParameters().put('orientation', (String)exportOptions.get('orientation'));
            }
            if (exportOptions.containsKey('margin')) {
                pdfPage.getParameters().put('margin', (String)exportOptions.get('margin'));
            }
            if (exportOptions.containsKey('watermark')) {
                pdfPage.getParameters().put('watermark', (String)exportOptions.get('watermark'));
            }
            
            // Generate PDF blob
            Blob pdfBlob = Test.isRunningTest() ? Blob.valueOf('Test PDF Content') : pdfPage.getContentAsPDF();
            
            return pdfBlob;
            
        } catch (Exception e) {
            throw new PDFGenerationException('PDF generation failed: ' + e.getMessage());
        }
    }
    
    public Blob generateComplianceReport(Id documentId) {
        try {
            // Get compliance analysis data
            List<DocumentComplianceTracking__c> complianceRecords = [
                SELECT Compliance_Score__c, GDPR_Compliant__c, HIPAA_Compliant__c, 
                       Analysis_Date__c, Document_ID__c
                FROM DocumentComplianceTracking__c 
                WHERE Document_ID__c = :documentId 
                ORDER BY Analysis_Date__c DESC 
                LIMIT 1
            ];
            
            if (complianceRecords.isEmpty()) {
                throw new PDFGenerationException('No compliance data found for document');
            }
            
            // Create compliance report page
            PageReference reportPage = new PageReference('/apex/ComplianceReportPage');
            reportPage.getParameters().put('documentId', documentId);
            reportPage.getParameters().put('complianceScore', String.valueOf(complianceRecords[0].Compliance_Score__c));
            reportPage.getParameters().put('gdprCompliant', String.valueOf(complianceRecords[0].GDPR_Compliant__c));
            reportPage.getParameters().put('hipaaCompliant', String.valueOf(complianceRecords[0].HIPAA_Compliant__c));
            
            return Test.isRunningTest() ? Blob.valueOf('Test Compliance Report') : reportPage.getContentAsPDF();
            
        } catch (Exception e) {
            throw new PDFGenerationException('Compliance report generation failed: ' + e.getMessage());
        }
    }
    
    // Custom Exception Class
    public class PDFGenerationException extends Exception {}
}