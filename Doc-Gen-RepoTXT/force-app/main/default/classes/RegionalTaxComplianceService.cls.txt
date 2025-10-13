public with sharing class RegionalTaxComplianceService {
    @AuraEnabled public static Map<String,Object> computeTax(String regionCode, Decimal amount) {
        if (String.isBlank(regionCode) || amount == null) return new Map<String,Object>{'ok'=>false};
        Decimal tax = 0;
        // simplistic default, replace with rules per region
        tax = amount * 0.1;
        return new Map<String,Object>{'ok'=>true,'region'=>regionCode,'tax'=> tax};
    }
}
