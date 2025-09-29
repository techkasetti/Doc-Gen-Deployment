    public with sharing class SignatureDispatcher {
        
        @future(callout=true)
        public static void dispatchToExternalProvider(String requestId, String provider) {
            try {
                Signature_Request__c sigRequest = getSignatureRequest(requestId);
                
                // Create dispatcher record
                SignatureDispatcher__c dispatcher = new SignatureDispatcher__c(
                    Signature_Request__c = requestId,
                API_Provider__c = provider,
                Integration_Status__c = 'Pending'
                    );
                insert dispatcher;
                
                String response = '';
                String externalId = '';
                
                switch on provider {
                    when 'DocuSign' {
                        Map<String, Object> docuSignResult = callDocuSignAPI(sigRequest);
                        response = (String) docuSignResult.get('response');
                        externalId = (String) docuSignResult.get('envelopeId');
                    }
                    when 'Adobe_Sign' {
                        Map<String, Object> adobeResult = callAdobeSignAPI(sigRequest);
                        response = (String) adobeResult.get('response');
                        externalId = (String) adobeResult.get('agreementId');
                    }
                    when 'Internal' {
                        response = processInternalSignature(sigRequest);
                        externalId = 'INT_' + requestId;
                    }
                    when else {
                        throw new CalloutException('Unsupported provider: ' + provider);
                    }
                }
                
                // Update dispatcher with response
                dispatcher.Integration_Status__c = 'Completed';
                dispatcher.External_Request_ID__c = externalId;
                dispatcher.Response_Data__c = response;
                update dispatcher;
                
                // Update signature request
                sigRequest.Status__c = 'In Progress';
                update sigRequest;
                
            } catch (Exception e) {
                handleDispatchError(requestId, e.getMessage());
            }
        }
        
        private static Map<String, Object> callDocuSignAPI(Signature_Request__c sigRequest) {
            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:DocuSign_API/v2.1/accounts/{accountId}/envelopes');
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');
                
                Map<String, Object> envelope = new Map<String, Object>{
                    'status' => 'sent',
                    'emailSubject' => 'Please sign this document',
                    'documents' => new List<Map<String, Object>>{
                        new Map<String, Object>{
                            'documentId' => '1',
                            'name' => 'Document to Sign',
                            'documentBase64' => getDocumentBase64(sigRequest.Document__c)
                        }
                    },
                    'recipients' => new Map<String, Object>{
                        'signers' => new List<Map<String, Object>>{
                            new Map<String, Object>{
                                'email' => getSignerEmail(sigRequest.Signer__c),
                                'name' => getSignerName(sigRequest.Signer__c),
                                'recipientId' => '1'
                            }
                        }
                    }
                };
                
                req.setBody(JSON.serialize(envelope));
                
                Http http = new Http();
                HttpResponse res = http.send(req);
                
                if (res.getStatusCode() == 201) {
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    return new Map<String, Object>{
                        'response' => res.getBody(),
                        'envelopeId' => responseMap.get('envelopeId')
                    };
                } else {
                    throw new CalloutException('DocuSign API call failed: ' + res.getStatus());
                }
                
            } catch (Exception e) {
                throw new CalloutException('DocuSign integration error: ' + e.getMessage());
            }
        }
        
        private static Map<String, Object> callAdobeSignAPI(Signature_Request__c sigRequest) {
            // Mock Adobe Sign implementation
            return new Map<String, Object>{
                'response' => '{"agreementId": "mock_adobe_id"}',
                'agreementId' => 'mock_adobe_id'
            };
        }
        
        private static String processInternalSignature(Signature_Request__c sigRequest) {
            // Internal signature processing
        return '{"status": "internal_processing", "requestId": "' + sigRequest.Id + '"}';
    }
    
    private static Signature_Request__c getSignatureRequest(String requestId) {
        return [
            SELECT Id, Document__c, Signer__c, Status__c 
            FROM Signature_Request__c 
            WHERE Id = :requestId 
            LIMIT 1
        ];
    }
    
    private static String getDocumentBase64(String documentId) {
        // Mock document base64 - in production, this would retrieve actual document content
        return EncodingUtil.base64Encode(Blob.valueOf('Mock document content for ' + documentId));
    }
    
    private static String getSignerEmail(String signerId) {
        Signer__c signer = [SELECT Email__c FROM Signer__c WHERE Id = :signerId LIMIT 1];
        return signer.Email__c;
    }
    
    private static String getSignerName(String signerId) {
        Signer__c signer = [SELECT Name FROM Signer__c WHERE Id = :signerId LIMIT 1];
        return signer.Name;
    }
    
    private static void handleDispatchError(String requestId, String errorMessage) {
        // Update dispatcher record with error
        List<SignatureDispatcher__c> dispatchers = [
            SELECT Id FROM SignatureDispatcher__c 
            WHERE Signature_Request__c = :requestId 
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
        
        if (!dispatchers.isEmpty()) {
            dispatchers[0].Integration_Status__c = 'Failed';
            dispatchers[0].Error_Message__c = errorMessage;
            update dispatchers[0];
        }
        
        // Log error
        Audit_Log__c audit = new Audit_Log__c(
            Record_Id__c = requestId,
        Action__c = 'DISPATCH_ERROR',
        Message__c = errorMessage,
        User_Id__c = UserInfo.getUserId(),
        Timestamp__c = System.now()
            );
        insert audit;
    }
}