public with sharing class ReleaseManagementController {
    @AuraEnabled public static Map<String,Object> listReleases(Integer limitN) {
        Integer lim = (limitN == null) ? 10 : limitN;
        return new Map<String,Object>{'ok'=>true,'releases'=>new List<Map<String,Object>>(), 'limit'=>lim};
    }
}