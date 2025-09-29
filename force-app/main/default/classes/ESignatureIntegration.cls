public class ESignatureIntegration {

    public class SignatureRequest {
        @AuraEnabled public String documentId;
        @AuraEnabled public List<String> signerEmails;
        @AuraEnabled public String subject;
        @AuraEnabled public String message;
        @AuraEnabled public Boolean requireAllSignatures;
        @AuraEnabled public Integer expirationDays;
        @AuraEnabled public Map<String, Object> metadata;
    }

    public class SignatureResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String signatureRequestId;
        @AuraEnabled public String status;
        @AuraEnabled public List<String> signerStatuses;
        @AuraEnabled public String documentUrl;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public DateTime requestTime;
    }

    @AuraEnabled(cacheable=false)
    public static SignatureResult initiateSignatureProcess(SignatureRequest request) {
        SignatureResult result = new SignatureResult();
        result.requestTime = DateTime.now();
        result.signerStatuses = new List<String>();

        try {
            DocumentLifecycleConfiguration__c document = [
                SELECT Id, Document_Name__c, Content__c, Status__c
                FROM DocumentLifecycleConfiguration__c
                WHERE Id = :request.documentId
                LIMIT 1
            ];

            if (document == null) {
                result.success = false;
                result.errorMessage = 'Document not found';
                return result;
            }

            Signature_Request__c signatureRequest = new Signature_Request__c(
                Document_Id__c = request.documentId,
                Subject__c = request.subject,
                Message__c = request.message,
                Status__c = 'Sent',
                Expiration_Date__c = Date.today().addDays(
                    request.expirationDays != null ? request.expirationDays : 30
                ),
                Require_All_Signatures__c = request.requireAllSignatures != null 
                    ? request.requireAllSignatures : true,
                Created_Date__c = DateTime.now()
            );
            insert signatureRequest;

            for (String signerEmail : request.signerEmails) {
                Signature_Participant__c participant = new Signature_Participant__c(
                    Signature_Request__c = signatureRequest.Id,
                    Signer_Email__c = signerEmail,
                    Status__c = 'Pending',
                    Signing_Order__c = request.signerEmails.indexOf(signerEmail) + 1
                );
                insert participant;

                result.signerStatuses.add(signerEmail + ': Pending');
            }

            document.Status__c = 'Pending Signature';
            update document;

            result.success = true;
            result.signatureRequestId = signatureRequest.Id;
            result.status = 'Sent';
            result.documentUrl = '/lightning/r/DocumentLifecycleConfiguration__c/' + document.Id + '/view';

            Audit_Trail__c auditRecord = new Audit_Trail__c(
                Document_Id__c = request.documentId,
                Action_Type__c = 'SIGNATURE_INITIATED',
                Details__c = 'Signature request sent to ' + request.signerEmails.size() + ' recipients',
                Timestamp__c = DateTime.now()
            );
            insert auditRecord;

        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
        }

        return result;
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getSignatureStatus(String signatureRequestId) {
        Map<String, Object> status = new Map<String, Object>();

        try {
            Signature_Request__c request = [
                SELECT Id, Status__c, Subject__c, Created_Date__c, Expiration_Date__c,
                       Document_Id__c, Document_Id__r.Document_Name__c
                FROM Signature_Request__c
                WHERE Id = :signatureRequestId
                LIMIT 1
            ];

            List<Signature_Participant__c> participants = [
                SELECT Id, Signer_Email__c, Status__c, Signed_Date__c, Signing_Order__c
                FROM Signature_Participant__c
                WHERE Signature_Request__c = :signatureRequestId
                ORDER BY Signing_Order__c
            ];

            status.put('requestId', request.Id);
            status.put('status', request.Status__c);
            status.put('subject', request.Subject__c);
            status.put('documentName', request.Document_Id__r.Document_Name__c);
            status.put('createdDate', request.Created_Date__c);
            status.put('expirationDate', request.Expiration_Date__c);

            List<Map<String, Object>> participantStatuses = new List<Map<String, Object>>();
            for (Signature_Participant__c participant : participants) {
                participantStatuses.add(new Map<String, Object>{
                    'email' => participant.Signer_Email__c,
                    'status' => participant.Status__c,
                    'signedDate' => participant.Signed_Date__c,
                    'signingOrder' => participant.Signing_Order__c
                });
            }

            status.put('participants', participantStatuses);
            status.put('totalParticipants', participants.size());

            Integer completedSignatures = 0;
            for (Signature_Participant__c participant : participants) {
                if (participant.Status__c == 'Completed') {
                    completedSignatures++;
                }
            }

            status.put('completedSignatures', completedSignatures);
            status.put(
                'completionPercentage',
                participants.size() > 0 ? (completedSignatures * 100) / participants.size() : 0
            );

        } catch (Exception e) {
            status.put('error', e.getMessage());
        }

        return status;
    }

    @AuraEnabled(cacheable=false)
    public static Boolean processSignatureCallback(String signatureRequestId, String participantEmail, String action) {
        try {
            Signature_Participant__c participant = [
                SELECT Id, Status__c, Signature_Request__c, Signature_Request__r.Document_Id__c
                FROM Signature_Participant__c
                WHERE Signature_Request__c = :signatureRequestId
                AND Signer_Email__c = :participantEmail
                LIMIT 1
            ];

            if (participant == null) {
                return false;
            }

            if (action == 'SIGNED') {
                participant.Status__c = 'Completed';
                participant.Signed_Date__c = DateTime.now();
            } else if (action == 'DECLINED') {
                participant.Status__c = 'Declined';
                participant.Declined_Date__c = DateTime.now();
            }
            update participant;

            List<Signature_Participant__c> allParticipants = [
                SELECT Id, Status__c
                FROM Signature_Participant__c
                WHERE Signature_Request__c = :signatureRequestId
            ];

            Boolean allCompleted = true;
            Boolean anyDeclined = false;

            for (Signature_Participant__c p : allParticipants) {
                if (p.Status__c != 'Completed') {
                    allCompleted = false;
                }
                if (p.Status__c == 'Declined') {
                    anyDeclined = true;
                }
            }

            Signature_Request__c request = [
                SELECT Id, Status__c, Document_Id__c
                FROM Signature_Request__c
                WHERE Id = :signatureRequestId
                LIMIT 1
            ];

            if (anyDeclined) {
                request.Status__c = 'Declined';
            } else if (allCompleted) {
                request.Status__c = 'Completed';
            }
            update request;

            if (allCompleted) {
                DocumentLifecycleConfiguration__c document = [
                    SELECT Id, Status__c
                    FROM DocumentLifecycleConfiguration__c
                    WHERE Id = :request.Document_Id__c
                    LIMIT 1
                ];
                document.Status__c = 'Fully Executed';
                update document;
            }

            Audit_Trail__c auditRecord = new Audit_Trail__c(
                Document_Id__c = participant.Signature_Request__r.Document_Id__c,
                Action_Type__c = 'SIGNATURE_' + action.toUpperCase(),
                Details__c = 'Participant ' + participantEmail + ' ' + action.toLowerCase() + ' the document',
                Timestamp__c = DateTime.now()
            );
            insert auditRecord;

            return true;

        } catch (Exception e) {
            System.debug('Signature callback processing failed: ' + e.getMessage());
            return false;
        }
    }

    @AuraEnabled(cacheable=false)
    public static List<Map<String, Object>> getSignatureRequestHistory(String documentId) {
        List<Map<String, Object>> history = new List<Map<String, Object>>();

        try {
            List<Signature_Request__c> requests = [
                SELECT Id, Status__c, Subject__c, Created_Date__c, Expiration_Date__c,
                       (SELECT Id, Signer_Email__c, Status__c, Signed_Date__c FROM Signature_Participants__r)
                FROM Signature_Request__c
                WHERE Document_Id__c = :documentId
                ORDER BY Created_Date__c DESC
            ];

            for (Signature_Request__c request : requests) {
                Map<String, Object> requestData = new Map<String, Object>();
                requestData.put('id', request.Id);
                requestData.put('status', request.Status__c);
                requestData.put('subject', request.Subject__c);
                requestData.put('createdDate', request.Created_Date__c);
                requestData.put('expirationDate', request.Expiration_Date__c);

                List<Map<String, Object>> participantData = new List<Map<String, Object>>();
                for (Signature_Participant__c participant : request.Signature_Participants__r) {
                    participantData.add(new Map<String, Object>{
                        'email' => participant.Signer_Email__c,
                        'status' => participant.Status__c,
                        'signedDate' => participant.Signed_Date__c
                    });
                }

                requestData.put('participants', participantData);
                history.add(requestData);
            }

        } catch (Exception e) {
            System.debug('Error retrieving signature history: ' + e.getMessage());
        }

        return history;
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getSignatureMetrics() {
        Map<String, Object> metrics = new Map<String, Object>();

        try {
            Date thirtyDaysAgo = Date.today().addDays(-30);
            DateTime thirtyDaysAgoDateTime = DateTime.newInstance(thirtyDaysAgo, Time.newInstance(0, 0, 0, 0));

            Integer totalRequests = [
                SELECT COUNT()
                FROM Signature_Request__c
                WHERE CreatedDate >= :thirtyDaysAgoDateTime
            ];
            Integer completedRequests = [
                SELECT COUNT()
                FROM Signature_Request__c
                WHERE Status__c = 'Completed' AND CreatedDate >= :thirtyDaysAgoDateTime
            ];
            Integer declinedRequests = [
                SELECT COUNT()
                FROM Signature_Request__c
                WHERE Status__c = 'Declined' AND CreatedDate >= :thirtyDaysAgoDateTime
            ];

            metrics.put('totalRequests', totalRequests);
            metrics.put('completedRequests', completedRequests);
            metrics.put('declinedRequests', declinedRequests);
            metrics.put('pendingRequests', totalRequests - completedRequests - declinedRequests);
            metrics.put('completionRate', totalRequests > 0 ? (completedRequests * 100) / totalRequests : 0);

            List<AggregateResult> avgCompletionTime = [
                SELECT AVG(Days_To_Complete__c) avgDays
                FROM Signature_Request__c
                WHERE Status__c = 'Completed' AND CreatedDate >= :thirtyDaysAgoDateTime
            ];

            if (!avgCompletionTime.isEmpty() && avgCompletionTime[0].get('avgDays') != null) {
                metrics.put('averageCompletionDays', ((Decimal)avgCompletionTime[0].get('avgDays')).setScale(1));
            } else {
                metrics.put('averageCompletionDays', 0);
            }

        } catch (Exception e) {
            metrics.put('error', e.getMessage());
        }

        return metrics;
    }

    @AuraEnabled(cacheable=false)
    public static Boolean sendSignatureReminder(String signatureRequestId, String participantEmail) {
        try {
            Signature_Participant__c participant = [
                SELECT Id, Status__c, Signer_Email__c, Signature_Request__r.Subject__c,
                       Signature_Request__r.Document_Id__r.Document_Name__c
                FROM Signature_Participant__c
                WHERE Signature_Request__c = :signatureRequestId
                AND Signer_Email__c = :participantEmail
                AND Status__c = 'Pending'
                LIMIT 1
            ];

            if (participant == null) {
                return false;
            }

            EmailNotificationService.sendSignatureReminder(participant.Id);

            Audit_Trail__c auditRecord = new Audit_Trail__c(
                Document_Id__c = participant.Signature_Request__r.Document_Id__c,
                Action_Type__c = 'REMINDER_SENT',
                Details__c = 'Signature reminder sent to ' + participantEmail,
                Timestamp__c = DateTime.now()
            );
            insert auditRecord;

            return true;

        } catch (Exception e) {
            System.debug('Failed to send signature reminder: ' + e.getMessage());
            return false;
        }
    }
}
