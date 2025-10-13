public with sharing class TemplatePreviewController {
    @AuraEnabled
    public static String previewTemplate(Id templateId, Map<String,Object> sampleData) {
        if (templateId == null) return null;
        return '<html><body>Preview for '+String.valueOf(templateId)+'</body></html>';
    }
}
