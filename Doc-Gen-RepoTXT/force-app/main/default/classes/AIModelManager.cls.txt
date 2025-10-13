public with sharing class AIModelManager {
    // TODO: Implement AI model configuration logic
    @AuraEnabled(cacheable=true)
    public static List<Object> getAvailableAIModels() {
        return new List<Object>();
    }
}