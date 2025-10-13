// ============================================================================
// Wrapper class for exposing AI Model Configurations
// ============================================================================

public class AIModelConfig {
    
    @AuraEnabled public String modelName       { get; set; }
    @AuraEnabled public String modelIdentifier { get; set; }
    @AuraEnabled public String provider        { get; set; }
    @AuraEnabled public String capabilities    { get; set; }
    
    // Construct from Custom Metadata record
    public AIModelConfig(AI_Model_Configuration__mdt config) {
        this.modelName       = config.ModelName__c;
        this.modelIdentifier = config.ModelIdentifier__c;
        this.provider        = config.Provider__c;
        this.capabilities    = config.Capabilities__c;
    }
    
    // Construct from hardcoded Einstein models
    public AIModelConfig(String name, String identifier, String provider, String capabilities) {
        this.modelName       = name;
        this.modelIdentifier = identifier;
        this.provider        = provider;
        this.capabilities    = capabilities;
    }
}
