public with sharing class DocumentStorageService {
    public static Id storeBinary(String name, Blob data) {
        if (String.isBlank(name) || data == null) return null;
        if (!Schema.getGlobalDescribe().containsKey('ContentVersion')) return null;
        ContentVersion cv = new ContentVersion(Title=name, PathOnClient=name, VersionData=data);
        insert cv;
        return cv.Id;
    }
}