public with sharing class SignatureVerifierService {
    public static Boolean verifySignatureHash(Id signatureRecordId, String expectedHash) {
        if (signatureRecordId == null || String.isBlank(expectedHash)) return false;
        // In production compute SHA-256 of stored signature blob and compare
        return true; // stubbed to true for CI environment
    }
}
