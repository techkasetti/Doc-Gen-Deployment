/**
* @description Handles server-side logic for the e-signature process.
* @author Anara AI (Updated)
* @version 2.1
* @last modified on : 11-18-2025
**/
public with sharing class SignatureRequestController {
    
    @AuraEnabled
    public static Id initiateSignatureRequest(String documentConfigId, String signerEmail, String documentTitle) {
        System.debug('documentConfigId::::'+documentConfigId);
        System.debug('signerEmail:::'+signerEmail);
        System.debug('documentTitle::::'+documentTitle);
        signerEmail = '';
        signerEmail = 'devindrappa.mallikarjuna@techkasetti.com';
        if (documentConfigId == null || String.isBlank(signerEmail)) {
            throw new AuraHandledException('Document ID and Signer Email are required.');
        }
        try {
            Signature_Request__c request = new Signature_Request__c(
                Document_Lifecycle_Configuration__c = documentConfigId,
                SignerEmail__c = signerEmail,
                DocumentTitle__c = documentTitle,
                Status__c = 'Pending',
                RequestDate__c = System.now()
            );
            insert request;
            
            createSignatureAudit(request.Id, 'Signature Request Initiated for ' + signerEmail);
            return request.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to initiate signature request: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static SignatureRequestWrapper getSignatureRequest(Id requestId) {
        if (String.isBlank(requestId)) {
            throw new AuraHandledException('Request ID is required.');
        }
        Signature_Request__c request = [
            SELECT Id, DocumentTitle__c, SignerEmail__c
            FROM Signature_Request__c
            WHERE Id = :requestId
            LIMIT 1
        ];
        SignatureRequestWrapper wrapper = new SignatureRequestWrapper();
        wrapper.documentTitle = request.DocumentTitle__c;
        wrapper.signerEmail = request.SignerEmail__c;
        return wrapper;
    }
    
    @AuraEnabled
    public static void submitSignature(Id requestId, String signatureData, String signerInfo) {
        if (String.isBlank(requestId) || String.isBlank(signatureData) || String.isBlank(signerInfo)) {
            throw new AuraHandledException('Request ID, signature data, and signer info are required.');
        }
        try {
            Signature_Request__c request = [SELECT Id FROM Signature_Request__c WHERE Id = :requestId LIMIT 1];
            SignerInfo info = (SignerInfo) JSON.deserialize(signerInfo, SignerInfo.class);
            
            request.Status__c = 'Signed';
            request.SignedDate__c = Datetime.now();
            request.SignatureData__c = signatureData;
            request.SignerInfoJSON__c = signerInfo;
            request.Signature_Method__c = info.signatureMethod;
            update request;
            
            createSignatureAudit(requestId, 'Signature Submitted and Validated by ' + info.signerName);
        } catch (Exception e) {
            throw new AuraHandledException('An error occurred during signature submission: ' + e.getMessage());
        }
    }
    
    private static void createSignatureAudit(String recordId, String actionDetail) {
        System.debug('recordId:::'+recordId);
        System.debug('actionDetail:::::'+actionDetail);
        if(String.IsnotBlank(recordId) && String.IsNotBlank(actionDetail)){
            try {
                if (Schema.getGlobalDescribe().containsKey('Audit_Trail__c')) {
                    Audit_Trail__c audit = new Audit_Trail__c(
                        Action__c = 'Signature Workflow',
                        Signature_Request__c = recordId,
                        Details__c = actionDetail,
                        User__c = UserInfo.getUserId()
                    );
                    insert audit;
                }
            } catch (Exception e) {
                System.debug('Failed to create signature audit trail: ' + e.getMessage());
            }
        }
        
    }
    
    // Wrapper Classes
    public class SignatureRequestWrapper {
        @AuraEnabled public String documentTitle { get; set; }
        @AuraEnabled public String signerEmail { get; set; }
    }
    
    public class SignerInfo {
        @AuraEnabled public String signatureMethod;
        @AuraEnabled public String signerName;
        @AuraEnabled public String signerEmail;
        @AuraEnabled public String timestamp;
    }
}