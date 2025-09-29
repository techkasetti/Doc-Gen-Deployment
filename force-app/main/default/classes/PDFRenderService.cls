public with sharing class PDFRenderService {
    public static Id renderHtmlToPdf(String html, String title) {
        if (String.isBlank(html)) return null;
        // In prod: call rendering service; here create ContentVersion when available
        if (!Schema.getGlobalDescribe().containsKey('ContentVersion')) return null;
        ContentVersion cv = new ContentVersion(Title= (title==null? 'pdf': title), PathOnClient='render.pdf', VersionData=Blob.valueOf(html));
        insert cv;
        return cv.Id;
    }
}