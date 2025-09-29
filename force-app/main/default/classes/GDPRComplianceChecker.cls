public with sharing class GDPRComplianceChecker {
    
    private static final List<String> GDPR_REQUIRED_CLAUSES = new List<String>{
        'right to be forgotten',
        'data portability',
        'consent withdrawal',
        'lawful basis',
        'data protection officer'
    };
    
    private static final List<String> PII_INDICATORS = new List<String>{
        'email',
        'phone',
        'address',
        'social security',
        'national id'
    };
    
    public Boolean checkCompliance(String documentContent) {
        try {
            String contentLower = documentContent.toLowerCase();
            
            // Check for required GDPR clauses
            Integer foundClauses = 0;
            for (String clause : GDPR_REQUIRED_CLAUSES) {
                if (contentLower.contains(clause)) {
                    foundClauses++;
                }
            }
            
            // Check for PII handling statements
            Boolean hasPIIHandling = checkPIIHandling(contentLower);
            
            // Calculate compliance score (60% clause coverage + PII handling required)
            Decimal clauseScore = (Decimal)foundClauses / GDPR_REQUIRED_CLAUSES.size();
            
            return clauseScore >= 0.6 && hasPIIHandling;
            
        } catch (Exception e) {
            System.debug('GDPR compliance check failed: ' + e.getMessage());
            return false;
        }
    }
    
    private Boolean checkPIIHandling(String content) {
        List<String> piiHandlingTerms = new List<String>{
            'personal data processing',
            'data subject rights',
            'privacy policy',
            'data retention'
        };
        
        for (String term : piiHandlingTerms) {
            if (content.contains(term)) {
                return true;
            }
        }
        
        return false;
    }
    
    public List<String> getComplianceViolations(String documentContent) {
        List<String> violations = new List<String>();
        String contentLower = documentContent.toLowerCase();
        
        for (String clause : GDPR_REQUIRED_CLAUSES) {
            if (!contentLower.contains(clause)) {
                violations.add('Missing GDPR clause: ' + clause);
            }
        }
        
        if (!checkPIIHandling(contentLower)) {
            violations.add('Missing PII handling statements');
        }
        
        return violations;
    }
}
