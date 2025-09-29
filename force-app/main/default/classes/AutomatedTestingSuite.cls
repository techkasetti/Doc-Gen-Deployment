public with sharing class AutomatedTestingSuite {
    @AuraEnabled
    public static List<String> listSuites() {
        return new List<String>{ 'unit', 'integration', 'smoke' };
    }
}
