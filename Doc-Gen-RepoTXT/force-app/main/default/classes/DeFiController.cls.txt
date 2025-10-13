public with sharing class DeFiController {
    @AuraEnabled
    public static Map<String,Object> getDefiPosition(String accountId) {
        Map<String,Object> out = new Map<String,Object>{ 'accountId' => accountId, 'positions' => new List<Object>() };
        // TODO: integrate to DeFi adapters
        return out;
    }
}
