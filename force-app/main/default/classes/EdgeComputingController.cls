public with sharing class EdgeComputingController {
    @AuraEnabled
    public static Map<String,Object> deployEdgeTask(String taskName, Map<String,Object> cfg) {
        Map<String,Object> out = new Map<String,Object>{'ok'=>false};
        if (String.isBlank(taskName)) return out;
        out.put('ok', true);
        out.put('task', taskName);
        return out;
    }
}
