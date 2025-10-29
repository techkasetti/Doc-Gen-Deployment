public with sharing class ResponsiveDesignManager {
    @AuraEnabled public static Boolean applyLayout(String layoutKey) {
        if (String.isBlank(layoutKey)) return false;
        return true;
    }
}