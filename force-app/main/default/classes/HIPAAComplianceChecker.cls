// File: force-app/main/default/classes/HIPAAComplianceChecker.cls
public with sharing class HIPAAComplianceChecker {
    
    private static final List<String> HIPAA_REQUIRED_ELEMENTS = new List<String>{
        'protected health information',
        'business associate',
        'minimum necessary',
        'administrative safeguards',
        'physical safeguards',
        'technical safeguards'
    };
    
    private static final List<String> PHI_IDENTIFIERS = new List<String>{
        'patient name',
        'medical record number',
        'health plan beneficiary',
        'account number',
        'certificate number'
    };
    
    public Boolean checkCompliance(String documentContent) {
        try {
            String contentLower = documentContent.toLowerCase();
            
            // Check for HIPAA required elements
            Integer foundElements = 0;
            for (String element : HIPAA_REQUIRED_ELEMENTS) {
                if (contentLower.contains(element)) {
                    foundElements++;
                }
            }
            
            // Check for PHI protection statements
            Boolean hasPHIProtection = checkPHIProtection(contentLower);
            
            // Calculate compliance (50% elements + PHI protection required)
            Decimal elementScore = (Decimal)foundElements / HIPAA_REQUIRED_ELEMENTS.size();
            
            return elementScore >= 0.5 && hasPHIProtection;
            
        } catch (Exception e) {
            System.debug('HIPAA compliance check failed: ' + e.getMessage());
            return false;
        }
    }
    
    private Boolean checkPHIProtection(String content) {
        List<String> protectionTerms = new List<String>{
            'phi protection',
            'health information security',
            'hipaa privacy rule',
            'breach notification'
        };
        
        for (String term : protectionTerms) {
            if (content.contains(term)) {
                return true;
            }
        }
        
        return false;
    }
    
    public List<String> getComplianceViolations(String documentContent) {
        List<String> violations = new List<String>();
        String contentLower = documentContent.toLowerCase();
        
        for (String element : HIPAA_REQUIRED_ELEMENTS) {
            if (!contentLower.contains(element)) {
                violations.add('Missing HIPAA element: ' + element);
            }
        }
        
        if (!checkPHIProtection(contentLower)) {
            violations.add('Missing PHI protection statements');
        }
        
        return violations;
    }
}
