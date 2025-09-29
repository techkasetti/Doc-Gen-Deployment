public with sharing class EncryptionServiceManager {
    @AuraEnabled
    public static String encrypt(String plaintext) {
        if (String.isBlank(plaintext)) return null;
        // simple placeholder: do not use for production
        return EncodingUtil.base64Encode(Blob.valueOf(plaintext));
    }
    @AuraEnabled
    public static String decrypt(String cipher) {
        if (String.isBlank(cipher)) return null;
        try { return Blob.valueOf(EncodingUtil.base64Decode(cipher)).toString(); } catch(Exception ex) { return null; }
    }
}
