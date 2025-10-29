public class DocumentComplianceProcessor {
    
private static final Map<String, RegulatoryFramework> REGULATORY_FRAMEWORKS = new Map<String, RegulatoryFramework>{
    'GDPR' => new RegulatoryFramework('GDPR', 'General Data Protection Regulation', new Set<String>{'EU', 'EEA'}),
    'HIPAA' => new RegulatoryFramework('HIPAA', 'Health Insurance Portability and Accountability Act', new Set<String>{'US'}),
    'SOX' => new RegulatoryFramework('SOX', 'Sarbanes-Oxley Act', new Set<String>{'US'}),
    'CCPA' => new RegulatoryFramework('CCPA', 'California Consumer Privacy Act', new Set<String>{'US-CA'}),
    'PIPEDA' => new RegulatoryFramework('PIPEDA', 'Personal Information Protection and Electronic Documents Act', new Set<String>{'CA'}),
    'DPA' => new RegulatoryFramework('DPA', 'Data Protection Act', new Set<String>{'UK'}),
    'LGPD' => new RegulatoryFramework('LGPD', 'Lei Geral de Proteção de Dados', new Set<String>{'BR'})
};

private static final Set<String> PII_PATTERNS = new Set<String>{
    '\\b\\d{3}-\\d{2}-\\d{4}\\b', // SSN
    '\\b\\d{4}[-\\s]?\\d{4}[-\\s]?\\d{4}[-\\s]?\\d{4}\\b', // Credit Card
    '\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}\\b', // Email
    '\\b\\d{3}-\\d{3}-\\d{4}\\b', // Phone
    '\\b\\d{1,2}\\/\\d{1,2}\\/\\d{4}\\b' // Date of Birth
};

public class ComplianceAnalysisResult {
    public Integer overallScore { get; set; }
    public Map<String, Boolean> frameworkCompliance { get; set; }
    public List<String> violations { get; set; }
    public List<String> recommendations { get; set; }
    public Map<String, Integer> riskScores { get; set; }
    public String classification { get; set; }
    public DateTime analyzedDate { get; set; }
    
    public ComplianceAnalysisResult() {
        this.frameworkCompliance = new Map<String, Boolean>();
        this.violations = new List<String>();
        this.recommendations = new List<String>();
        this.riskScores = new Map<String, Integer>();
        this.analyzedDate = System.now();
    }
}

@future
public static void analyzeDocumentAsync(Id documentId) {
    DocumentComplianceProcessor processor = new DocumentComplianceProcessor();
    processor.analyzeDocument(documentId);
}

public ComplianceAnalysisResult analyzeDocument(Id documentId) {
    try {
        // Get document content
        ContentVersion document = getDocumentContent(documentId);
        if (document == null) {
            throw new AnaraException('Document not found or inaccessible');
        }

        // Initialize analysis result
        ComplianceAnalysisResult result = new ComplianceAnalysisResult();
        
        // Perform multi-dimensional analysis
        performContentAnalysis(document, result);
        performPIIAnalysis(document, result);
        performRegulatoryAnalysis(document, result);
        performRiskAssessment(document, result);
        classifyDocument(document, result);
        
        // Calculate overall compliance score
        calculateOverallScore(result);
        
        // Generate recommendations
        generateRecommendations(result);
        
        // Store analysis results
        saveAnalysisResults(documentId, result);
        
        return result;
        
    } catch (Exception e) {
        System.debug('Error analyzing document: ' + e.getMessage());
        throw new AnaraException('Document analysis failed: ' + e.getMessage());
    }
}

private ContentVersion getDocumentContent(Id documentId) {
    try {
        return [
            SELECT Id, Title, FileExtension, ContentSize, VersionData, 
                   CreatedDate, ContentDocumentId, Description
            FROM ContentVersion 
            WHERE ContentDocumentId = :documentId 
            AND IsLatest = true 
            LIMIT 1
        ];
    } catch (Exception e) {
        return null;
    }
}

private void performContentAnalysis(ContentVersion document, ComplianceAnalysisResult result) {
    try {
        String content = extractTextContent(document);
        if (String.isBlank(content)) {
            result.violations.add('Document content could not be analyzed');
            return;
        }
        
        // Analyze content structure
        analyzeDocumentStructure(content, result);
        
        // Check for required clauses
        analyzeRequiredClauses(content, result);
        
        // Analyze language compliance
        analyzeLanguageCompliance(content, result);
        
    } catch (Exception e) {
        System.debug('Content analysis error: ' + e.getMessage());
        result.violations.add('Content analysis failed');
    }
}

private void performPIIAnalysis(ContentVersion document, ComplianceAnalysisResult result) {
    try {
        String content = extractTextContent(document);
        if (String.isBlank(content)) return;
        
        Integer piiMatches = 0;
        List<String> detectedPII = new List<String>();
        
        for (String patternStr : PII_PATTERNS) {
            Pattern regexPattern = Pattern.compile(patternStr);
            Matcher matcher = regexPattern.matcher(content);
            
            while (matcher.find()) {
                piiMatches++;
                String piiType = getPIIType(patternStr);
                if (!detectedPII.contains(piiType)) {
                    detectedPII.add(piiType);
                }
            }
        }
        
        if (piiMatches > 0) {
            result.violations.add('PII detected: ' + String.join(detectedPII, ', '));
            result.riskScores.put('PII_RISK', Math.min(piiMatches * 10, 100));
            
            // Check for PII protection measures
            if (!hasDataProtectionClauses(content)) {
                result.violations.add('PII detected but no data protection clauses found');
            }
        }
        
    } catch (Exception e) {
        System.debug('PII analysis error: ' + e.getMessage());
    }
}


private void performRegulatoryAnalysis(ContentVersion document, ComplianceAnalysisResult result) {
    try {
        String content = extractTextContent(document);
        
        for (String frameworkKey : REGULATORY_FRAMEWORKS.keySet()) {
            RegulatoryFramework framework = REGULATORY_FRAMEWORKS.get(frameworkKey);
            Boolean isCompliant = assessFrameworkCompliance(content, framework);
            result.frameworkCompliance.put(frameworkKey, isCompliant);
            
            if (!isCompliant) {
                result.violations.add(framework.name + ' compliance requirements not met');
                result.riskScores.put(frameworkKey + '_RISK', 75);
            } else {
                result.riskScores.put(frameworkKey + '_RISK', 25);
            }
        }
        
    } catch (Exception e) {
        System.debug('Regulatory analysis error: ' + e.getMessage());
    }
}

private void performRiskAssessment(ContentVersion document, ComplianceAnalysisResult result) {
    try {
        Integer totalRisk = 0;
        Integer riskFactors = 0;
        
        // Assess various risk factors
        totalRisk += assessContentRisk(document);
        totalRisk += assessAccessRisk(document);
        totalRisk += assessRetentionRisk(document);
        totalRisk += assessEncryptionRisk(document);
        riskFactors = 4;
        
        // Calculate average risk score
        Integer averageRisk = riskFactors > 0 ? totalRisk / riskFactors : 0;
        result.riskScores.put('OVERALL_RISK', averageRisk);
        
        if (averageRisk > 70) {
            result.violations.add('High risk document identified - immediate review required');
        }
        
    } catch (Exception e) {
        System.debug('Risk assessment error: ' + e.getMessage());
    }
}

private void classifyDocument(ContentVersion document, ComplianceAnalysisResult result) {
    try {
        String content = extractTextContent(document);
        String classification = 'UNCLASSIFIED';
        
        // AI-based classification logic
        if (containsFinancialTerms(content)) {
            classification = 'FINANCIAL';
        } else if (containsHealthTerms(content)) {
            classification = 'HEALTHCARE';
        } else if (containsLegalTerms(content)) {
            classification = 'LEGAL';
        } else if (containsHRTerms(content)) {
            classification = 'HUMAN_RESOURCES';
        } else if (containsTechnicalTerms(content)) {
            classification = 'TECHNICAL';
        }
        
        result.classification = classification;
        
    } catch (Exception e) {
        System.debug('Classification error: ' + e.getMessage());
        result.classification = 'UNKNOWN';
    }
}

private void calculateOverallScore(ComplianceAnalysisResult result) {
    try {
        Integer score = 100;
        
        // Deduct points for violations
        score -= Math.min(result.violations.size() * 10, 50);
        
        // Deduct points for non-compliant frameworks
        for (Boolean isCompliant : result.frameworkCompliance.values()) {
            if (!isCompliant) {
                score -= 15;
            }
        }
        
        // Deduct points for high risk scores
        for (Integer riskScore : result.riskScores.values()) {
            if (riskScore > 70) {
                score -= 10;
            }
        }
        
        result.overallScore = Math.max(score, 0);
        
    } catch (Exception e) {
        System.debug('Score calculation error: ' + e.getMessage());
        result.overallScore = 50; // Default moderate score
    }
}

private void generateRecommendations(ComplianceAnalysisResult result) {
    try {
        // Generate recommendations based on analysis
        if (result.overallScore < 60) {
            result.recommendations.add('Comprehensive compliance review required');
        }
        
        for (String framework : result.frameworkCompliance.keySet()) {
            if (!result.frameworkCompliance.get(framework)) {
                result.recommendations.add('Add ' + framework + ' compliance clauses');
            }
        }
        
        if (result.riskScores.containsKey('PII_RISK') && result.riskScores.get('PII_RISK') > 50) {
            result.recommendations.add('Implement PII protection measures');
        }
        
        if (result.riskScores.containsKey('OVERALL_RISK') && result.riskScores.get('OVERALL_RISK') > 70) {
            result.recommendations.add('Immediate security review recommended');
        }
        
    } catch (Exception e) {
        System.debug('Recommendation generation error: ' + e.getMessage());
    }
}

private void saveAnalysisResults(Id documentId, ComplianceAnalysisResult result) {
    try {
        DocumentComplianceTracking__c tracking = new DocumentComplianceTracking__c();
        tracking.Document_ID__c = documentId;
        tracking.Compliance_Score__c = String.Valueof(result.overallScore);
        tracking.GDPR_Compliant__c = String.Valueof(result.frameworkCompliance.get('GDPR'));
        tracking.HIPAA_Compliant__c = String.Valueof(result.frameworkCompliance.get('HIPAA'));
        tracking.Compliance_Violations__c = String.join(result.violations, ';');
        tracking.AI_Classification__c = result.classification;
        tracking.Risk_Score__c = String.valueOf(result.riskScores.get('OVERALL_RISK'));
        tracking.Analysis_Date__c = result.analyzedDate;
        tracking.Recommendations__c = String.join(result.recommendations, ';');
        // Use insert instead of upsert if Document_ID__c is not an External Id
        insert tracking;
    } catch (Exception e) {
        System.debug('Error saving analysis results: ' + e.getMessage());
        throw new AnaraException('Failed to save compliance analysis');
    }
}

// Helper methods for content analysis
private String extractTextContent(ContentVersion document) {
    try {
        if (document.VersionData == null) return '';
        
        String fileExtension = document.FileExtension?.toLowerCase();
        if (isTextFile(fileExtension)) {
            return document.VersionData.toString();
        } else if (fileExtension == 'pdf') {
            return extractPDFText(document.VersionData);
        } else {
            return ''; // Unsupported format
        }
    } catch (Exception e) {
        System.debug('Text extraction error: ' + e.getMessage());
        return '';
    }
}

private Boolean isTextFile(String fileExtension) {
    Set<String> textExtensions = new Set<String>{'txt', 'csv', 'xml', 'json', 'html'};
    return textExtensions.contains(fileExtension);
}

private String extractPDFText(Blob pdfData) {
    // Placeholder for PDF text extraction
    // In production, this would use a PDF parsing library or external service
    return 'PDF_TEXT_EXTRACTION_PLACEHOLDER';
}

private void analyzeDocumentStructure(String content, ComplianceAnalysisResult result) {
    if (content.length() < 100) {
        result.violations.add('Document appears incomplete or too short');
    }
    
    if (!content.contains('signature') && !content.contains('agree')) {
        result.violations.add('No signature or agreement terms found');
    }
}

private void analyzeRequiredClauses(String content, ComplianceAnalysisResult result) {
    List<String> requiredClauses = new List<String>{
        'privacy policy', 'data protection', 'confidentiality',
        'liability', 'termination', 'governing law'
    };
    
    for (String clause : requiredClauses) {
        if (!content.toLowerCase().contains(clause)) {
            result.violations.add('Missing required clause: ' + clause);
        }
    }
}

private void analyzeLanguageCompliance(String content, ComplianceAnalysisResult result) {
    // Check for clear, plain language
    List<String> complexTerms = new List<String>{
        'heretofore', 'whereas', 'aforementioned', 'notwithstanding'
    };
    
    Integer complexityScore = 0;
    for (String term : complexTerms) {
        if (content.toLowerCase().contains(term)) {
            complexityScore += 10;
        }
    }
    
    if (complexityScore > 30) {
        result.violations.add('Document language may be too complex for general understanding');
    }
}

private String getPIIType(String pattern) {
    if (pattern.contains('\\d{3}-\\d{2}-\\d{4}')) return 'SSN';
    if (pattern.contains('\\d{4}[-\\s]?\\d{4}')) return 'Credit Card';
    if (pattern.contains('@')) return 'Email';
    if (pattern.contains('\\d{3}-\\d{3}-\\d{4}')) return 'Phone';
    if (pattern.contains('\\/')) return 'Date';
    return 'Unknown PII';
}
    private Boolean hasDataProtectionClauses(String content) {
    List<String> protectionTerms = new List<String>{
        'data protection', 'privacy', 'confidential', 'secure', 'encrypt', 
        'gdpr', 'hipaa', 'personal data', 'sensitive information'
    };
    String lowerContent = content.toLowerCase();
    for (String term : protectionTerms) {
        if (lowerContent.contains(term)) {
            return true;
        }
    }
    return false;
}

private Boolean assessFrameworkCompliance(String content, RegulatoryFramework framework) {
    try {
        String lowerContent = content.toLowerCase();
        switch on framework.code {
            when 'GDPR' { return assessGDPRCompliance(lowerContent); }
            when 'HIPAA' { return assessHIPAACompliance(lowerContent); }
            when 'SOX' { return assessSOXCompliance(lowerContent); }
            when 'CCPA' { return assessCCPACompliance(lowerContent); }
            when 'PIPEDA' { return assessPIPEDACompliance(lowerContent); }
            when 'LGPD' { return assessLGPDCompliance(lowerContent); }
            when else { return true; } // Default to compliant for unknown frameworks
        }
    } catch (Exception e) {
        System.debug('Framework compliance assessment error: ' + e.getMessage());
        return false;
    }
}

private Boolean assessGDPRCompliance(String content) {
    List<String> gdprRequirements = new List<String>{
        'lawful basis', 'consent', 'data subject rights', 'data protection officer',
        'breach notification', 'privacy by design', 'legitimate interest'
    };
    Integer found = 0;
    for (String requirement : gdprRequirements) {
        if (content.contains(requirement)) {
            found++;
        }
    }
    return found >= 3; // At least 3 GDPR concepts should be present
}

private Boolean assessHIPAACompliance(String content) {
    List<String> hipaaRequirements = new List<String>{
        'protected health information', 'phi', 'business associate', 'minimum necessary',
        'security rule', 'privacy rule', 'covered entity'
    };
    Integer found = 0;
    for (String requirement : hipaaRequirements) {
        if (content.contains(requirement)) {
            found++;
        }
    }
    return found >= 2; // At least 2 HIPAA concepts should be present
}

private Boolean assessSOXCompliance(String content) {
    List<String> soxRequirements = new List<String>{
        'internal controls', 'financial reporting', 'audit', 
        'segregation of duties', 'documentation', 'certification'
    };
    Integer found = 0;
    for (String requirement : soxRequirements) {
        if (content.contains(requirement)) {
            found++;
        }
    }
    return found >= 2;
}

private Boolean assessCCPACompliance(String content) {
    List<String> ccpaRequirements = new List<String>{
        'california consumer privacy act', 'ccpa', 'right to know', 
        'right to delete', 'opt-out', 'personal information', 'sale of personal information'
    };
    Integer found = 0;
    for (String requirement : ccpaRequirements) {
        if (content.contains(requirement)) {
            found++;
        }
    }
    return found >= 2;
}

private Boolean assessPIPEDACompliance(String content) {
    List<String> pipedaRequirements = new List<String>{
        'pipeda', 'personal information protection', 'privacy breach', 
        'consent', 'collection limitation'
    };
    Integer found = 0;
    for (String requirement : pipedaRequirements) {
        if (content.contains(requirement)) {
            found++;
        }
    }
    return found >= 1;
}

private Boolean assessLGPDCompliance(String content) {
    List<String> lgpdRequirements = new List<String>{
        'lgpd', 'dados pessoais', 'consentimento', 'finalidade', 'adequação', 'necessidade'
    };
    Integer found = 0;
    for (String requirement : lgpdRequirements) {
        if (content.contains(requirement)) {
            found++;
        }
    }
    return found >= 1;
}

private Integer assessContentRisk(ContentVersion document) {
    try {
        String content = extractTextContent(document);
        Integer riskScore = 0;

        // Check for sensitive content indicators
        if (content.toLowerCase().contains('confidential')) riskScore += 20;
        if (content.toLowerCase().contains('internal only')) riskScore += 15;
        if (content.toLowerCase().contains('proprietary')) riskScore += 10;

        // Check for financial terms
        if (containsFinancialTerms(content)) riskScore += 25;

        // Check for health information
        if (containsHealthTerms(content)) riskScore += 30;

        return Math.min(riskScore, 100);
    } catch (Exception e) {
        return 50; // Default moderate risk
    }
}
private Integer assessAccessRisk(ContentVersion document) {
    try {
        // Check sharing and visibility settings
        List<ContentDocumentLink> links = [
            SELECT Id, ShareType, Visibility 
            FROM ContentDocumentLink 
            WHERE ContentDocumentId = :document.ContentDocumentId
        ];
        Integer riskScore = 0;
        for (ContentDocumentLink link : links) {
            if (link.ShareType == 'V' && link.Visibility == 'AllUsers') {
                riskScore += 30; // High risk for all users visibility
            } else if (link.ShareType == 'V') {
                riskScore += 10; // Moderate risk for view access
            }
        }
        return Math.min(riskScore, 100);
    } catch (Exception e) {
        return 25; // Default low-moderate risk
    }
}

private Integer assessRetentionRisk(ContentVersion document) {
    try {
        Integer daysSinceCreation = Date.today().daysBetween(document.CreatedDate.date());
        Integer riskScore = 0;
        // Risk increases with age without explicit retention policy
        if (daysSinceCreation > 2555) { // > 7 years
            riskScore = 80;
        } else if (daysSinceCreation > 1825) { // > 5 years
            riskScore = 60;
        } else if (daysSinceCreation > 1095) { // > 3 years
            riskScore = 40;
        } else if (daysSinceCreation > 365) { // > 1 year
            riskScore = 20;
        }
        return riskScore;
    } catch (Exception e) {
        return 30; // Default moderate risk
    }
}

private Integer assessEncryptionRisk(ContentVersion document) {
    try {
        // Check if document has encryption indicators
        String content = extractTextContent(document);
        Integer riskScore = 50; // Default moderate risk
        // Look for encryption mentions
        if (content.toLowerCase().contains('encrypted') || content.toLowerCase().contains('encryption')) {
            riskScore = 20; // Low risk if encryption is mentioned
        }
        // Check file type - some formats have built-in security
        String fileExt = document.FileExtension?.toLowerCase();
        if (fileExt == 'pdf') {
            riskScore = 30; // PDFs can have built-in security
        }
        return riskScore;
    } catch (Exception e) {
        return 70; // Default high risk if can't assess
    }
}

private Boolean containsFinancialTerms(String content) {
    List<String> financialTerms = new List<String>{
        'bank', 'credit card', 'payment', 'invoice', 'financial', 
        'accounting', 'revenue', 'profit', 'budget', 'cost', 'expense'
    };
    String lowerContent = content.toLowerCase();
    for (String term : financialTerms) {
        if (lowerContent.contains(term)) {
            return true;
        }
    }
    return false;
}

private Boolean containsHealthTerms(String content) {
    List<String> healthTerms = new List<String>{
        'medical', 'health', 'patient', 'diagnosis', 'treatment', 
        'hospital', 'doctor', 'physician', 'clinical', 'healthcare', 'medication'
    };
    String lowerContent = content.toLowerCase();
    for (String term : healthTerms) {
        if (lowerContent.contains(term)) {
            return true;
        }
    }
    return false;
}

private Boolean containsLegalTerms(String content) {
    List<String> legalTerms = new List<String>{
        'contract', 'agreement', 'legal', 'clause', 'terms', 
        'conditions', 'liability', 'indemnity', 'jurisdiction', 
        'governing law', 'dispute'
    };
    String lowerContent = content.toLowerCase();
    for (String term : legalTerms) {
        if (lowerContent.contains(term)) {
            return true;
        }
    }
    return false;
}

private Boolean containsHRTerms(String content) {
    List<String> hrTerms = new List<String>{
        'employee', 'employment', 'salary', 'benefits', 'personnel', 
        'human resources', 'hr', 'recruitment', 'onboarding', 'performance review'
    };
    String lowerContent = content.toLowerCase();
    for (String term : hrTerms) {
        if (lowerContent.contains(term)) {
            return true;
        }
    }
    return false;
}

private Boolean containsTechnicalTerms(String content) {
    List<String> technicalTerms = new List<String>{
        'software', 'hardware', 'system', 'database', 'server', 
        'network', 'security', 'encryption', 'api', 'integration', 'technical'
    };
    String lowerContent = content.toLowerCase();
    for (String term : technicalTerms) {
        if (lowerContent.contains(term)) {
            return true;
        }
    }
    return false;
}
public class RegulatoryFramework {
    public String code { get; set; }
    public String name { get; set; }
    public Set<String> jurisdictions { get; set; }

    public RegulatoryFramework(String code, String name, Set<String> jurisdictions) {
        this.code = code;
        this.name = name;
        this.jurisdictions = jurisdictions;
    }
}

// Custom exception class
public class AnaraException extends Exception {}
}