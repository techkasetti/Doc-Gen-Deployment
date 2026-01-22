public with sharing class ComplianceChecker {

    public static List<String> validateDocument(
        String documentHtml,
        List<String> jurisdictions,
        String contractType
    ) {
        List<String> errors = new List<String>();

        List<Compliance_Rule__c> rules = [
            SELECT Jurisdiction__c,
                   Required_Text__c,
                   Error_Message__c,
                   Severity__c
            FROM Compliance_Rule__c
            WHERE Is_Active__c = true
              AND Jurisdiction__c IN :jurisdictions
              AND Contract_Type__c = :contractType
        ];

        for (Compliance_Rule__c rule : rules) {
            if (
                String.isNotBlank(rule.Required_Text__c) &&
                !documentHtml.toLowerCase()
                    .contains(rule.Required_Text__c.toLowerCase())
            ) {
                errors.add(
                    rule.Jurisdiction__c + ' → ' + rule.Error_Message__c
                );
            }
        }

        return errors;
    }
}