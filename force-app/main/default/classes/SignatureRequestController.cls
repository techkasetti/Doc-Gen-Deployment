public with sharing class SignatureRequestController {
  @AuraEnabled
  public static Id createSignatureRequest(Id documentId, String signerEmail, String signerName) {
    SignatureData__c req = new SignatureData__c(Document__c = documentId, Signer_Name__c = signerName, Signature_Method__c = 'Pending');
    insert req;
    return req.Id;
  }

  // Callout-based send to provider (DocuSign) - implement NamedCredential usage
  public static void sendToProvider(Id signatureId) {
    // TODO: implement callout using Named Credential: callout:DocuSign_API
    // Use HttpRequest with named credential, handle OAuth refresh via DocuSignAuth
  }

  @AuraEnabled
  public static Boolean verifyHash(Id signatureId, String providedHash) {
    SignatureData__c sd = [SELECT Id, Signature_Hash__c FROM SignatureData__c WHERE Id = :signatureId LIMIT 1];
    return sd.Signature_Hash__c == providedHash;
  }
}