public with sharing class TemplateService {
    // Create a template
    @AuraEnabled
    public static Id createTemplate(String name, String content, String format, Boolean isActive) {
        Template__c t = new Template__c();
        t.Name = name;
        t.Content__c = content;
        t.Format__c = format;
        t.IsActive__c = isActive;
        insert t;
        return t.Id;
    }

    // Update a template
    @AuraEnabled
    public static Template__c updateTemplate(Id templateId, String content, String format, Boolean isActive) {
        Template__c t = [SELECT Id, Content__c, Format__c, IsActive__c FROM Template__c WHERE Id = :templateId LIMIT 1];
        t.Content__c = content;
        t.Format__c = format;
        t.IsActive__c = isActive;
        update t;
        return t;
    }

    // Get template by id
    @AuraEnabled(cacheable=true)
    public static Template__c getTemplateById(Id id) {
        return [SELECT Id, Name, Content__c, Format__c, Version__c, IsActive__c FROM Template__c WHERE Id = :id LIMIT 1];
    }

    // List templates
    @AuraEnabled(cacheable=true)
    public static List<Template__c> listTemplates(Boolean onlyActive) {
        if (onlyActive) {
            return [SELECT Id, Name, Format__c, Version__c, IsActive__c FROM Template__c WHERE IsActive__c = true ORDER BY Name];
        } else {
            return [SELECT Id, Name, Format__c, Version__c, IsActive__c FROM Template__c ORDER BY Name];
        }
    }

    // Soft delete template
    @AuraEnabled
    public static void deleteTemplate(Id id) {
        Template__c t = new Template__c(Id = id);
        delete t;
    }

    // Simple versioning helper - create new version copy
    @AuraEnabled
    public static Id createTemplateVersion(Id existingTemplateId, String newContent) {
        Template__c t = [SELECT Name, Content__c, Format__c, Version__c FROM Template__c WHERE Id = :existingTemplateId LIMIT 1];
        Template__c v = t.clone(false, true, false, false);
        v.Content__c = newContent;
        v.Version__c = (v.Version__c == null) ? 1 : v.Version__c + 1;
        insert v;
        return v.Id;
    }

    // Basic validation (placeholder - extend as needed)
    public static Void validateTemplate(Template__c t) {
        if (String.isBlank(t.Name)) {
            throw new AuraHandledException('Template name required');
        }
        return null;
    }
}
