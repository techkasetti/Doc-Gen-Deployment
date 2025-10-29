public with sharing class TemplateRendererService {

    public class RenderResult {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public Id contentVersionId { get; set; }
        @AuraEnabled public String sha256Hex { get; set; }
        @AuraEnabled public String contentType { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
    }

    // =========================
    // Merge data into template HTML
    // =========================
    public static String mergeTemplate(String templateHtml, Map<String, Object> mergeData) {
        if (templateHtml == null) return '';
        if (mergeData == null || mergeData.isEmpty()) return templateHtml;

        String out = templateHtml;
        for (String k : mergeData.keySet()) {
            String token = '{{' + k + '}}';
            String v = mergeData.get(k) == null ? '' : String.valueOf(mergeData.get(k));
            out = out.replace(token, v);
        }
        return out;
    }

    // =========================
    // Render merged template and save as ContentVersion
    // =========================
    public static RenderResult render(
        String templateHtml, 
        Map<String, Object> mergeData, 
        String outputFormat, 
        String title
    ) {
        RenderResult r = new RenderResult();

        try {
            String merged = mergeTemplate(templateHtml, mergeData);
            String finalHtml = applyBasicSanitization(merged);

            Blob contentBlob;
            String contentType;

            if (outputFormat != null && outputFormat.toUpperCase() == 'PDF') {
                contentBlob = Blob.valueOf(finalHtml);
                contentType = 'application/pdf';
            } else {
                contentBlob = Blob.valueOf(finalHtml);
                contentType = 'text/html';
            }

            String sha256Hex = EncodingUtil.convertToHex(
                Crypto.generateDigest('SHA-256', contentBlob)
            );

            ContentVersion cv = new ContentVersion();
            cv.VersionData = contentBlob;
            cv.Title = title == null 
                ? ('generated-' + String.valueOf(DateTime.now().getTime())) 
                : title;
            cv.PathOnClient = cv.Title + (contentType == 'text/html' ? '.html' : '.pdf');
            cv.IsMajorVersion = true;
            cv.FirstPublishLocationId = null;
            insert cv;

            r.success = true;
            r.contentVersionId = cv.Id;
            r.sha256Hex = sha256Hex;
            r.contentType = contentType;
            return r;

        } catch (Exception ex) {
            r.success = false;
            r.errorMessage = ex.getMessage();
            return r;
        }
    }

    // =========================
    // Remove <script> tags from HTML
    // =========================
    private static String applyBasicSanitization(String html) {
        if (html == null) return '';
        // NOTE: Double escape for backslashes in regex
        return html.replaceAll('(?i)<script[\\s\\S]*?>[\\s\\S]*?</script>', '');
    }
}