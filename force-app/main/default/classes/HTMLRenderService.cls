public with sharing class HTMLRenderService {
    public static String sanitizeHtml(String html) {
        if (String.isBlank(html)) return '';
        // Basic sanitization stub
        return html.replaceAll('<script.*?>.*?</script>', '');
    }
}