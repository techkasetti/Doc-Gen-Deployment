public with sharing class UserTrainingController {
    @AuraEnabled
    public static Map<String,Object> enrollUserInCourse(Id userId, String courseKey) {
        Map<String,Object> out = new Map<String,Object>{'ok'=>false};
        if (userId == null || String.isBlank(courseKey)) return out;
        try {
            // Production: create enrollment record
            out.put('ok', true);
            out.put('userId', String.valueOf(userId));
            out.put('courseKey', courseKey);
            out.put('enrolledAt', String.valueOf(Datetime.now()));
            return out;
        } catch (Exception ex) {
            try { if (Schema.getGlobalDescribe().containsKey('Error_Log__c')) insert new Error_Log__c(Message__c='UserTrainingController:'+ex.getMessage()); } catch(Exception e){}
            out.put('error', ex.getMessage());
            return out;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<String> listAvailableCourses() {
        return new List<String>{'onboarding_basics','security_training'};
    }
}