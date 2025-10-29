public with sharing class TemplateRollbackService {
    public static Boolean rollbackToVersion(Id templateId, Id versionId) {
        if (templateId == null || versionId == null) return false;
        // stub: update template pointer
        return true;
    }
}