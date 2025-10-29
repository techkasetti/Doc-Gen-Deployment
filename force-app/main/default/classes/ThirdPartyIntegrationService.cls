public with sharing class ThirdPartyIntegrationService {
    
    public class IntegrationResult {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String integrationId { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public Map<String, Object> responseData { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
        @AuraEnabled public DateTime processedTime { get; set; }
        
        public IntegrationResult() {
            this.responseData = new Map<String, Object>();
            this.processedTime = DateTime.now();
        }
    }
    
    @AuraEnabled
    public static IntegrationResult syncWithExternalSystem(String systemName, String operation, Map<String, Object> payload) {
        IntegrationResult result = new IntegrationResult();
        result.processedTime = DateTime.now();
        
        try {
            // Get integration configuration
            Integration_Configuration__c config = [
                SELECT Id, System_Name__c, Endpoint_URL__c, API_Key__c, Active__c
                FROM Integration_Configuration__c 
                WHERE System_Name__c = :systemName AND Active__c = true 
                LIMIT 1
            ];
            
            if (config == null) {
                result.success = false;
                result.errorMessage = 'Integration configuration not found for system: ' + systemName;
                return result;
            }
            
            // Create integration log
            Integration_Log__c integrationLog = new Integration_Log__c(
                System_Name__c = systemName,
                Operation__c = operation,
                Request_Payload__c = JSON.serialize(payload),
                Status__c = 'In Progress',
                Started_Date__c = DateTime.now()
            );
            insert integrationLog;
            
            // Perform integration based on system type
            Map<String, Object> integrationResponse = performIntegration(config, operation, payload);
            
            // Update integration log
            integrationLog.Status__c = (Boolean)integrationResponse.get('success') ? 'Success' : 'Failed';
            integrationLog.Response_Payload__c = JSON.serialize(integrationResponse);
            integrationLog.Completed_Date__c = DateTime.now();
            if (integrationResponse.containsKey('error')) {
                integrationLog.Error_Message__c = (String)integrationResponse.get('error');
            }
            update integrationLog;
            
            result.integrationId = integrationLog.Id;
            result.success = (Boolean)integrationResponse.get('success');
            result.responseData = integrationResponse;
            
            if (!result.success) {
                result.errorMessage = (String)integrationResponse.get('error');
            }
            
            return result;
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
            logIntegrationError(systemName, operation, e.getMessage());
            return result;
        }
    }
    
    @AuraEnabled
    public static IntegrationResult connectToDocuSign(Map<String, Object> documentData) {
        IntegrationResult result = new IntegrationResult();
        try {
            String documentId = (String)documentData.get('documentId');
            String signerEmail = (String)documentData.get('signerEmail');
            String signerName = (String)documentData.get('signerName');
            
            // Prepare DocuSign envelope
            Map<String, Object> envelopeData = new Map<String, Object>();
            envelopeData.put('emailSubject', 'Please sign this document');
            envelopeData.put('status', 'sent');
            
            // Add document
            List<Map<String, Object>> documents = new List<Map<String, Object>>();
            Map<String, Object> document = new Map<String, Object>();
            document.put('documentId', '1');
            document.put('name', 'Document to Sign');
            document.put('documentBase64', getDocumentBase64(documentId));
            documents.add(document);
            envelopeData.put('documents', documents);
            
            // Add signer
            List<Map<String, Object>> signers = new List<Map<String, Object>>();
            Map<String, Object> signer = new Map<String, Object>();
            signer.put('email', signerEmail);
            signer.put('name', signerName);
            signer.put('recipientId', '1');
            signers.add(signer);
            envelopeData.put('recipients', new Map<String, Object>{'signers' => signers});
            
            // Call DocuSign API
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:DocuSign/envelopes');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(envelopeData));
            req.setTimeout(30000);
            
            Http http = new Http();
            HttpResponse response = http.send(req);
            
            if (response.getStatusCode() == 201) {
                Map<String, Object> responseBody = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                String envelopeId = (String)responseBody.get('envelopeId');
                
                // Create external signature request record
                External_Signature_Request__c externalRequest = new External_Signature_Request__c(
                    Document_ID__c = documentId,
                    Provider__c = 'DocuSign',
                    External_ID__c = envelopeId,
                    Status__c = 'Sent',
                    Signer_Email__c = signerEmail,
                    Signer_Name__c = signerName,
                    Created_Date__c = DateTime.now()
                );
                insert externalRequest;
                
                result.success = true;
                result.integrationId = externalRequest.Id;
                result.responseData.put('envelopeId', envelopeId);
                result.responseData.put('status', 'sent');
            } else {
                result.success = false;
                result.errorMessage = 'DocuSign API error: ' + response.getStatus() + ' - ' + response.getBody();
                logIntegrationError('DocuSign', 'CREATE_ENVELOPE', result.errorMessage);
            }
            
            return result;
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'DocuSign integration failed: ' + e.getMessage();
            logIntegrationError('DocuSign', 'CREATE_ENVELOPE', e.getMessage());
            return result;
        }
    }
    
    // Stub method for actual integration logic
    private static Map<String, Object> performIntegration(Integration_Configuration__c config, String operation, Map<String, Object> payload) {
        Map<String, Object> response = new Map<String, Object>();
        response.put('success', true);
        response.put('message', 'Integration simulated successfully');
        return response;
    }
    
    // Stub method to fetch document as Base64
    private static String getDocumentBase64(String documentId) {
        // TODO: implement real document fetching
        return EncodingUtil.base64Encode(Blob.valueOf('Sample Document Content for ' + documentId));
    }
    
    // Error logging helper
    private static void logIntegrationError(String systemName, String operation, String errorMessage) {
        try {
            Integration_Log__c log = new Integration_Log__c(
                System_Name__c = systemName,
                Operation__c = operation,
                Status__c = 'Failed',
                Error_Message__c = errorMessage,
                Started_Date__c = DateTime.now(),
                Completed_Date__c = DateTime.now()
            );
            insert log;
        } catch (Exception e) {
            System.debug('Failed to log integration error: ' + e.getMessage());
        }
    }
    @AuraEnabled
public static IntegrationResult connectToAdobeSign(Map<String, Object> documentData) {
    IntegrationResult result = new IntegrationResult();
    
    try {
        String documentId = (String)documentData.get('documentId');
        String signerEmail = (String)documentData.get('signerEmail');
        String signerName = (String)documentData.get('signerName');
        
        // Prepare Adobe Sign agreement
        Map<String, Object> agreementData = new Map<String, Object>();
        agreementData.put('name', 'Document for Signature');
        agreementData.put('signatureType', 'ESIGN');
        agreementData.put('state', 'IN_PROCESS');
        
        // Add document
        List<Map<String, Object>> fileInfos = new List<Map<String, Object>>();
        Map<String, Object> fileInfo = new Map<String, Object>();
        fileInfo.put('libraryDocumentId', documentId);
        fileInfos.add(fileInfo);
        agreementData.put('fileInfos', fileInfos);
        
        // Add participant
        List<Map<String, Object>> participantSets = new List<Map<String, Object>>();
        Map<String, Object> participantSet = new Map<String, Object>();
        List<Map<String, Object>> memberInfos = new List<Map<String, Object>>();
        Map<String, Object> memberInfo = new Map<String, Object>();
        memberInfo.put('email', signerEmail);
        memberInfo.put('name', signerName);
        memberInfos.add(memberInfo);
        participantSet.put('memberInfos', memberInfos);
        participantSet.put('order', 1);
        participantSet.put('role', 'SIGNER');
        participantSets.add(participantSet);
        agreementData.put('participantSetsInfo', participantSets);
        
        // Call Adobe Sign API
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:AdobeSign/agreements');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(agreementData));
        req.setTimeout(30000);
        
        Http http = new Http();
        HttpResponse response = http.send(req);
        
        if (response.getStatusCode() == 201) {
            Map<String, Object> responseBody = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
            String agreementId = (String)responseBody.get('id');
            
            // Create external signature request record
            External_Signature_Request__c externalRequest = new External_Signature_Request__c(
                Document_ID__c = documentId,
                Provider__c = 'Adobe Sign',
                External_ID__c = agreementId,
                Status__c = 'Sent',
                Signer_Email__c = signerEmail,
                Signer_Name__c = signerName,
                Created_Date__c = DateTime.now()
            );
            insert externalRequest;
            
            result.success = true;
            result.integrationId = externalRequest.Id;
            result.responseData.put('agreementId', agreementId);
            result.responseData.put('status', 'sent');
        } else {
            result.success = false;
            result.errorMessage = 'Adobe Sign API error: ' + response.getStatus() + ' - ' + response.getBody();
            logIntegrationError('Adobe Sign', 'CREATE_AGREEMENT', result.errorMessage);
        }
        
        return result;
        
    } catch (Exception e) {
        result.success = false;
        result.errorMessage = 'Adobe Sign integration failed: ' + e.getMessage();
        logIntegrationError('Adobe Sign', 'CREATE_AGREEMENT', e.getMessage());
        return result;
    }
}

}