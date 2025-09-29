public class ProductionValidationService {
    
    @AuraEnabled
    public static Map<String, Object> validateSystemHealth() {
        Map<String, Object> healthCheck = new Map<String, Object>();
        
        try {
            // Validate custom objects
            healthCheck.put('customObjects', validateCustomObjects());
            
            // Validate permission sets
            healthCheck.put('permissions', validatePermissions());
            
            // Validate named credentials
            healthCheck.put('credentials', validateNamedCredentials());
            
            // Validate templates
            healthCheck.put('templates', validateTemplates());
            
            // Validate compliance rules
            healthCheck.put('complianceRules', validateComplianceRules());
            
            // Overall health status
            Boolean overallHealth = true;
            for (String key : healthCheck.keySet()) {
                Map<String, Object> check = (Map<String, Object>) healthCheck.get(key);
                if (!(Boolean) check.get('isHealthy')) {
                    overallHealth = false;
                    break;
                }
            }
            
            healthCheck.put('overallHealth', overallHealth);
            healthCheck.put('lastChecked', System.now());
            
            return healthCheck;
            
        } catch (Exception e) {
            healthCheck.put('error', e.getMessage());
            healthCheck.put('overallHealth', false);
            return healthCheck;
        }
    }
    
    private static Map<String, Object> validateCustomObjects() {
        Map<String, Object> result = new Map<String, Object>();
        List<String> requiredObjects = new List<String>{
            'DocumentLifecycleConfiguration__c',
            'DocumentTemplate__c',
            'ComplianceRule__c',
            'Signature_Request__c',
            'AuditTrail__c',
            'SignatureValidation__c'
        };
        
        List<String> missingObjects = new List<String>();
        Integer validObjects = 0;
        
        for (String objName : requiredObjects) {
            try {
                // Try to query the object to validate it exists
                Database.query('SELECT Id FROM ' + objName + ' LIMIT 1');
                validObjects++;
            } catch (Exception e) {
                missingObjects.add(objName);
            }
        }
        
        result.put('totalRequired', requiredObjects.size());
        result.put('validObjects', validObjects);
        result.put('missingObjects', missingObjects);
        result.put('isHealthy', missingObjects.isEmpty());
        
        return result;
    }
    
    private static Map<String, Object> validatePermissions() {
        Map<String, Object> result = new Map<String, Object>();
        List<String> requiredPermissionSets = new List<String>{
            'DocumentGenerationAdmin',
            'DocumentGenerationUser'
        };
        
        List<PermissionSet> existingPermSets = [
            SELECT Name FROM PermissionSet 
            WHERE Name IN :requiredPermissionSets
        ];
        
        Set<String> existingNames = new Set<String>();
        for (PermissionSet ps : existingPermSets) {
            existingNames.add(ps.Name);
        }
        
        List<String> missingPermSets = new List<String>();
        for (String permSet : requiredPermissionSets) {
            if (!existingNames.contains(permSet)) {
                missingPermSets.add(permSet);
            }
        }
        
        result.put('totalRequired', requiredPermissionSets.size());
        result.put('existingCount', existingPermSets.size());
        result.put('missingPermissionSets', missingPermSets);
        result.put('isHealthy', missingPermSets.isEmpty());
        
        return result;
    }
    
    private static Map<String, Object> validateNamedCredentials() {
        Map<String, Object> result = new Map<String, Object>();
        List<String> requiredCredentials = new List<String>{
            'OpenAI_API',
            'DocuSign_API'
        };
        
        List<NamedCredential> existingCreds = [
            SELECT DeveloperName FROM NamedCredential 
            WHERE DeveloperName IN :requiredCredentials
        ];
        
        Set<String> existingNames = new Set<String>();
        for (NamedCredential nc : existingCreds) {
            existingNames.add(nc.DeveloperName);
        }
        
        List<String> missingCreds = new List<String>();
        for (String cred : requiredCredentials) {
            if (!existingNames.contains(cred)) {
                missingCreds.add(cred);
            }
        }
        
        result.put('totalRequired', requiredCredentials.size());
        result.put('existingCount', existingCreds.size());
        result.put('missingCredentials', missingCreds);
        result.put('isHealthy', missingCreds.isEmpty());
        
        return result;
    }
    
    private static Map<String, Object> validateTemplates() {
        Map<String, Object> result = new Map<String, Object>();
        
        List<DocumentTemplate__c> templates = [
            SELECT Id, Name, TemplateType__c, Region__c, IsActive__c 
            FROM DocumentTemplate__c 
            WHERE IsActive__c = true
        ];
        
        Map<String, Integer> templatesByRegion = new Map<String, Integer>();
        for (DocumentTemplate__c template : templates) {
            String key = template.Region__c + '_' + template.TemplateType__c;
            templatesByRegion.put(key, templatesByRegion.containsKey(key) ? templatesByRegion.get(key) + 1 : 1);
        }
        
        result.put('totalActiveTemplates', templates.size());
        result.put('templatesByRegion', templatesByRegion);
        result.put('isHealthy', templates.size() > 0);
        
        return result;
    }
    
    private static Map<String, Object> validateComplianceRules() {
        Map<String, Object> result = new Map<String, Object>();
        
        List<ComplianceRule__c> rules = [
            SELECT Id, RuleName__c, Region__c, DocumentType__c, IsActive__c 
            FROM ComplianceRule__c 
            WHERE IsActive__c = true
        ];
        
        Map<String, Integer> rulesByRegion = new Map<String, Integer>();
        for (ComplianceRule__c rule : rules) {
            rulesByRegion.put(rule.Region__c, rulesByRegion.containsKey(rule.Region__c) ? rulesByRegion.get(rule.Region__c) + 1 : 1);
        }
        
        result.put('totalActiveRules', rules.size());
        result.put('rulesByRegion', rulesByRegion);
        result.put('isHealthy', rules.size() > 0);
        
        return result;
    }
    
    @AuraEnabled
    public static String performEndToEndTest() {
        try {
            // Test 1: Generate clause
            String testClause = ClauseGenerator.generateClause('US', 'Manager', 'Employment');
            if (String.isBlank(testClause)) {
                return 'FAILED: Clause generation failed';
            }
            
            // Test 2: Validate compliance
            Boolean isCompliant = ComplianceChecker.validateClause(testClause, 'US', 'Employment');
            if (!isCompliant) {
                return 'FAILED: Compliance validation failed';
            }
            
            // Test 3: Create document request
            String docId = DocumentGenerationController.createDocumentRequest(
                'Employment', 'US', 'Manager', testClause, 'Production validation test', 'Compliant'
            );
            if (String.isBlank(docId)) {
                return 'FAILED: Document creation failed';
            }
            
            // Test 4: Initiate signature request
            String sigRequestId = SignatureRequestController.initiateSignatureRequest(
                docId, 'validation@test.com', 'Production Validation Test Document'
            );
            if (String.isBlank(sigRequestId)) {
                return 'FAILED: Signature request initiation failed';
            }
            
            // Clean up test data
            delete [SELECT Id FROM DocumentLifecycleConfiguration__c WHERE Id = :docId];
            delete [SELECT Id FROM Signature_Request__c WHERE Id = :sigRequestId];
            
            return 'SUCCESS: All end-to-end tests passed';
            
        } catch (Exception e) {
            return 'FAILED: ' + e.getMessage();
        }
    }
}
