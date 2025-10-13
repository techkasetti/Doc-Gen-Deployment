public with sharing class AccessibilityController {
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getAccessibilityGuidelines() {
        Map<String,Object> out = new Map<String,Object>();
        out.put('version', '1.0');
        out.put('wcag', '2.1 AA');
        out.put('recommendedChecks', new List<String>{'colorContrast','keyboardNav','ariaRoles'});
        return out;
    }
}
 