public with sharing class SignatureVerificationController {

    @AuraEnabled
    public static Boolean verifySignature(Id signatureRecordId, String expectedHash) {
        if (signatureRecordId == null) {
            throw new AuraHandledException('verifySignature: signatureRecordId is required');
        }
        if (String.isBlank(expectedHash)) {
            throw new AuraHandledException('verifySignature: expectedHash is required');
        }

        try {
            // Verify the signature using the service
            Boolean verified = SignatureVerifierService.verifySignatureHash(signatureRecordId, expectedHash);

            // Update Signature_Request__c.Status__c if the object exists
            try {
                Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
                if (gd.containsKey('Signature_Request__c')) {
                    String idStr = String.valueOf(signatureRecordId);
                    String soql = 'SELECT Id, Status__c FROM Signature_Request__c WHERE Id = \'' + idStr + '\' LIMIT 1';
                    SObject rec = Database.query(soql);
                    if (rec != null) {
                        rec.put('Status__c', verified ? 'VERIFIED' : 'FAILED');
                        update rec;
                    }
                }
            } catch (Exception eUpdate) {
                System.debug('SignatureVerificationController: failed to update Signature_Request__c status: ' + eUpdate.getMessage());
            }

            // Insert an audit record if Audit_Trail__c or AuditTrail__c exists
            try {
                Map<String, Schema.SObjectType> gd2 = Schema.getGlobalDescribe();
                SObject audit;
                
                if (gd2.containsKey('Audit_Trail__c')) {
                    audit = gd2.get('Audit_Trail__c').newSObject();
                } else if (gd2.containsKey('AuditTrail__c')) {
                    audit = gd2.get('AuditTrail__c').newSObject();
                } else {
                    audit = null;
                }

                if (audit != null) {
                    audit.put('Action__c', verified ? 'Signature Verified' : 'Signature Verification Failed');
                    audit.put('User__c', UserInfo.getUserId());
                    audit.put('Timestamp__c', DateTime.now());
                    audit.put('RelatedRecordId__c', signatureRecordId);
                    audit.put('Details__c', 'Verification result: ' + (verified ? 'SUCCESS' : 'FAIL') + ' by ' + UserInfo.getName());
                    insert audit;
                }
            } catch (Exception eAudit) {
                System.debug('SignatureVerificationController: failed to create audit record: ' + eAudit.getMessage());
            }

            return verified;
        } catch (Exception e) {
            throw new AuraHandledException('Signature verification failed: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Object> verifySignatureWithResult(Id signatureRecordId, String expectedHash) {
        Map<String, Object> out = new Map<String, Object>{
            'ok' => false,
            'verified' => false,
            'message' => ''
        };

        try {
            Boolean verified = verifySignature(signatureRecordId, expectedHash);
            out.put('ok', true);
            out.put('verified', verified);
            out.put('message', verified ? 'Signature verified' : 'Signature verification failed');
            return out;
        } catch (Exception ex) {
            out.put('ok', false);
            out.put('verified', false);
            out.put('message', ex.getMessage());
            return out;
        }
    }
}