public with sharing class MachineLearningModelManager {
    @AuraEnabled
    public static Map<String,Object> registerModel(String modelKey, Map<String,Object> meta) {
        Map<String,Object> out = new Map<String,Object>{'ok' => false};
        if (String.isBlank(modelKey)) return out;
        try {
            out.put('ok', true);
            out.put('modelKey', modelKey);
            out.put('registeredAt', String.valueOf(Datetime.now()));
            return out;
        } catch(Exception ex) {
            out.put('error', ex.getMessage());
            return out;
        }
    }
}