public with sharing class TemplateRendererService {
    public static String renderToHtml(Id templateId, Map<String,Object> mergeData) {
        if (templateId == null) return null;
        // Simple placeholder render
        return '<html><body>Rendered template ' + String.valueOf(templateId) + '</body></html>';
    }
}