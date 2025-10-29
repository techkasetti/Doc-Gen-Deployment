public with sharing class AIManagerModel {

    public class AIModel {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public String provider { get; set; }
    }

    @AuraEnabled
    public static List<AIModel> getAvailableModels() {
        List<AIModel> models = new List<AIModel>();

        AIModel intent = new AIModel();
        intent.id = 'einstein_intent';
        intent.name = 'Einstein Intent';
        intent.type = 'NLP';
        intent.provider = 'Salesforce';
        models.add(intent);

        AIModel sentiment = new AIModel();
        sentiment.id = 'einstein_sentiment';
        sentiment.name = 'Einstein Sentiment';
        sentiment.type = 'NLP';
        sentiment.provider = 'Salesforce';
        models.add(sentiment);

        AIModel language = new AIModel();
        language.id = 'einstein_language';
        language.name = 'Einstein Language';
        language.type = 'NLP';
        language.provider = 'Salesforce';
        models.add(language);

        return models;
    }

    @AuraEnabled
    public static AIModel getModelById(String modelId) {
        for (AIModel model : getAvailableModels()) {
            if (model.id == modelId) {
                return model;
            }
        }
        return null;
    }
}