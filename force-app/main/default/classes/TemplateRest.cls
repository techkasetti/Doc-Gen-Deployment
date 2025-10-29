public with sharing class TemplateRest
{
    // =========================
    // CREATE TEMPLATE
    // =========================
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

    // =========================
    // UPDATE TEMPLATE
    // =========================
    @AuraEnabled
    public static Template__c updateTemplate(Id templateId, String content, String format, Boolean isActive) {
        Template__c t = [
            SELECT Id, Content__c, Format__c, IsActive__c 
            FROM Template__c 
            WHERE Id = :templateId 
            LIMIT 1
        ];
        t.Content__c = content;
        t.Format__c = format;
        t.IsActive__c = isActive;
        update t;
        return t;
    }

    // =========================
    // GET TEMPLATE BY ID
    // =========================
    @AuraEnabled(cacheable=true)
    public static Template__c getTemplateById(Id id) {
        return [
            SELECT Id, Name, Content__c, Format__c, Version__c, IsActive__c 
            FROM Template__c 
            WHERE Id = :id 
            LIMIT 1
        ];
    }

    // =========================
    // LIST TEMPLATES
    // =========================
    @AuraEnabled(cacheable=true)
    public static List<Template__c> listTemplates(Boolean onlyActive) {
        if (onlyActive) {
            return [
                SELECT Id, Name, Format__c, Version__c, IsActive__c 
                FROM Template__c 
                WHERE IsActive__c = true 
                ORDER BY Name
            ];
        } else {
            return [
                SELECT Id, Name, Format__c, Version__c, IsActive__c 
                FROM Template__c 
                ORDER BY Name
            ];
        }
    }

    // =========================
    // DELETE TEMPLATE (Soft Delete)
    // =========================
    @AuraEnabled
    public static void deleteTemplate(Id id) {
        Template__c t = new Template__c(Id = id);
        delete t;
    }

    // =========================
    // CREATE NEW TEMPLATE VERSION
    // =========================
    @AuraEnabled
    public static Id createTemplateVersion(Id existingTemplateId, String newContent) {
        // Load existing template
        Template__c t = [
            SELECT Name, Content__c, Format__c, Version__c 
            FROM Template__c 
            WHERE Id = :existingTemplateId 
            LIMIT 1
        ];

        // Clone for new version
        Template__c v = t.clone(false, true, false, false);
        v.Content__c = newContent;

        // Compute next version number safely
        Integer nextVersion = 1;
        try {
            String currentVersionStr = String.valueOf(t.Version__c);
            if (!String.isBlank(currentVersionStr) && currentVersionStr != 'null') {
                try {
                    nextVersion = Integer.valueOf(currentVersionStr) + 1;
                } catch (Exception ex) {
                    nextVersion = 1; // fallback
                }
            }
        } catch (Exception e) {
            nextVersion = 1;
        }

        // Handle Version__c field type dynamically
        Schema.DescribeFieldResult dfr = Template__c.Version__c.getDescribe();
        Schema.DisplayType fieldType = dfr.getType();

        SObject sObj = (SObject) v;

        if (
            fieldType == Schema.DisplayType.INTEGER ||
            fieldType == Schema.DisplayType.DOUBLE ||
            fieldType == Schema.DisplayType.CURRENCY ||
            fieldType == Schema.DisplayType.PERCENT
        ) {
            sObj.put('Version__c', nextVersion);
        } else {
            sObj.put('Version__c', String.valueOf(nextVersion));
        }

        insert v;
        return v.Id;
    }
}