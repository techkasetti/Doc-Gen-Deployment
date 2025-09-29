public class DocumentRiskAssessor {
    public static RiskAssessmentResult assessDocumentRisks(String documentId) {
        RiskAssessmentResult result = new RiskAssessmentResult();
        
        try {
            // Get document analysis data
            DocumentAnalysisRecord__c analysis = [
                SELECT Document_Type__c, Sensitivity_Level__c, Key_Topics__c
                FROM DocumentAnalysisRecord__c 
                WHERE Document__c = :documentId 
                ORDER BY CreatedDate DESC 
                LIMIT 1
            ];
            
            // Assess different risk categories
            result.securityRiskScore = assessSecurityRisk(documentId, analysis);
            result.complianceRiskScore = assessComplianceRisk(documentId, analysis);
            result.operationalRiskScore = assessOperationalRisk(documentId, analysis);
            result.privacyRiskScore = assessPrivacyRisk(documentId, analysis);
            result.reputationalRiskScore = assessReputationalRisk(documentId, analysis);
            result.financialRiskScore = assessFinancialRisk(documentId, analysis);
            
            // Calculate overall risk score
            result.overallRiskScore = calculateOverallRiskScore(result);
            result.riskLevel = determineRiskLevel(result.overallRiskScore);
            
            // Identify risk factors
            result.riskFactors = identifyRiskFactors(documentId, analysis, result);
            
            // Generate mitigation recommendations
            result.mitigationRecommendations = generateMitigationRecommendations(result);
            
        } catch (Exception e) {
            result.assessmentError = e.getMessage();
            result.overallRiskScore = 100; // Maximum risk if assessment fails
            result.riskLevel = 'CRITICAL';
        }
        
        return result;
    }
    
    private static Decimal assessSecurityRisk(String documentId, DocumentAnalysisRecord__c analysis) {
        Decimal riskScore = 0;
        
        // Check encryption status
        DocumentSecurityConfig__c securityConfig = getSecurityConfig(documentId);
        if (securityConfig == null || !securityConfig.Encryption_Enabled__c) {
            riskScore += 30;
        }
        
        // Check access controls
        List<DocumentAccessControl__c> accessControls = [
            SELECT Id FROM DocumentAccessControl__c 
            WHERE Document__c = :documentId AND Status__c = 'ACTIVE'
        ];
        if (accessControls.isEmpty()) {
            riskScore += 25;
        }
        
        // Check tamper detection
        List<TamperDetectionLog__c> tamperLogs = [
            SELECT Id FROM TamperDetectionLog__c 
            WHERE Document__c = :documentId AND Tamper_Detected__c = true
        ];
        if (!tamperLogs.isEmpty()) {
            riskScore += 40;
        }
        
        // Sensitivity-based risk adjustment
        String sensitivity = analysis.Sensitivity_Level__c;
        if (sensitivity == 'CRITICAL') {
            riskScore *= 1.5;
        } else if (sensitivity == 'HIGH') {
            riskScore *= 1.3;
        }
        
        return Math.min(100, riskScore);
    }
    
    private static Decimal assessComplianceRisk(String documentId, DocumentAnalysisRecord__c analysis) {
        Decimal riskScore = 0;
        
        // Check compliance validation status
        List<ComplianceValidationRecord__c> complianceRecords = [
            SELECT Overall_Status__c, Overall_Compliance_Score__c 
            FROM ComplianceValidationRecord__c 
            WHERE Document__c = :documentId 
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
        
        if (complianceRecords.isEmpty()) {
            riskScore += 50; // No compliance validation performed
        } else {
            ComplianceValidationRecord__c record = complianceRecords[0];
            if (record.Overall_Status__c == 'NON_COMPLIANT') {
                riskScore += 60;
            } else if (record.Overall_Status__c == 'PARTIALLY_COMPLIANT') {
                riskScore += 30;
            }
            
            // Adjust based on compliance score
            if (record.Overall_Compliance_Score__c < 50) {
                riskScore += 40;
            } else if (record.Overall_Compliance_Score__c < 75) {
                riskScore += 20;
            }
        }
        
        // Check for regulatory requirement changes
        List<RegulatoryUpdate__c> recentUpdates = [
            SELECT Id FROM RegulatoryUpdate__c 
            WHERE Effective_Date__c >= :Date.today().addDays(-30)
            AND Impact_Level__c = 'HIGH'
        ];
        if (!recentUpdates.isEmpty()) {
            riskScore += 15;
        }
        
        return Math.min(100, riskScore);
    }
    
    // private static Decimal assessOperationalRisk(String documentId, DocumentAnalysisRecord__c analysis) {
    //     Decimal riskScore = 0;
        
    //     // Check document availability
    //     List<SystemDowntime__c> downtimeRecords = [
    //         SELECT Id FROM SystemDowntime__c 
    //         WHERE CreatedDate >= :DateTime.now().addDays(-7)
    //         AND Impact__c INCLUDES 'DOCUMENT_ACCESS'
    //     ];
    //     if (!downtimeRecords.isEmpty()) {
    //         riskScore += 25;
    //     }
        
    //     // Check backup status
    //     List<DocumentBackup__c> backupRecords = [
    //         SELECT Backup_Status__c FROM DocumentBackup__c 
    //         WHERE Document__c = :documentId 
    //         ORDER BY CreatedDate DESC 
    //         LIMIT 1
    //     ];
    //     if (backupRecords.isEmpty() || backupRecords[0].Backup_Status__c != 'SUCCESS') {
    //         riskScore += 30;
    //     }
        
    //     // Check version control
    //     List<ContentVersion> versions = [
    //         SELECT Id FROM ContentVersion 
    //         WHERE ContentDocumentId = :documentId
    //     ];
    //     if (versions.size() > 10) {
    //         riskScore += 15; // Too many versions might indicate chaos
    //     }
        
    //     // Check collaborative access
    //     List<CollaborativeSession__c> activeSessions = [
    //         SELECT Id FROM CollaborativeSession__c 
    //         WHERE Document__c = :documentId 
    //         AND Status__c = 'ACTIVE'
    //     ];
    //     if (activeSessions.size() > 5) {
    //         riskScore += 20; // Too many concurrent collaborators
    //     }
        
    //     return Math.min(100, riskScore);
    // }
    private static Decimal assessOperationalRisk(String documentId, DocumentAnalysisRecord__c analysis) {
    Decimal riskScore = 0;
    
    // -------------------------
    // 1. Check document availability (system downtime in last 7 days)
    // -------------------------
    List<SystemDowntime__c> downtimeRecords = [
        SELECT Id 
        FROM SystemDowntime__c 
        WHERE CreatedDate >= :DateTime.now().addDays(-7)
        // Use INCLUDES only if Impact__c is a multi-select picklist
        AND Impact__c INCLUDES ('DOCUMENT_ACCESS')
    ];
    if (!downtimeRecords.isEmpty()) {
        riskScore += 25; // Increase risk if downtime occurred
    }
    
    // -------------------------
    // 2. Check backup status (latest backup for this document)
    // -------------------------
    List<DocumentBackup__c> backupRecords = [
        SELECT Backup_Status__c 
        FROM DocumentBackup__c 
        WHERE Document__c = :documentId 
        ORDER BY CreatedDate DESC 
        LIMIT 1
    ];
    if (backupRecords.isEmpty() || backupRecords[0].Backup_Status__c != 'SUCCESS') {
        riskScore += 30; // Increase risk if no successful recent backup
    }
    
    // -------------------------
    // 3. Check version control (too many versions = possible chaos)
    // -------------------------
    List<ContentVersion> versions = [
        SELECT Id 
        FROM ContentVersion 
        WHERE ContentDocumentId = :documentId
    ];
    if (versions.size() > 10) {
        riskScore += 15;
    }
    
    // -------------------------
    // 4. Check collaborative access (too many active sessions)
    // -------------------------
    List<CollaborativeSession__c> activeSessions = [
        SELECT Id 
        FROM CollaborativeSession__c 
        WHERE Document__c = :documentId 
        AND Status__c = 'ACTIVE'
    ];
    if (activeSessions.size() > 5) {
        riskScore += 20;
    }
    
    // -------------------------
    // Final: Cap risk score at 100
    // -------------------------
    return Math.min(100, riskScore);
}

    private static Decimal assessPrivacyRisk(String documentId, DocumentAnalysisRecord__c analysis) {
        Decimal riskScore = 0;
        
        // Check for personal data
        List<String> topics = analysis.Key_Topics__c != null ? 
            analysis.Key_Topics__c.split(';') : new List<String>();
        
        Boolean hasPersonalData = topics.contains('PERSONAL_DATA');
        Boolean hasBiometricData = topics.contains('BIOMETRIC');
        Boolean hasFinancialData = topics.contains('FINANCIAL');
        Boolean hasMedicalData = topics.contains('MEDICAL');
        
        if (hasPersonalData) riskScore += 25;
        if (hasBiometricData) riskScore += 35;
        if (hasFinancialData) riskScore += 30;
        if (hasMedicalData) riskScore += 40;
        
        // Check data retention compliance
        List<DocumentRetentionApplication__c> retentionApps = [
            SELECT Status__c FROM DocumentRetentionApplication__c 
            WHERE Document__c = :documentId
        ];
        if (retentionApps.isEmpty()) {
            riskScore += 25;
        }
        
        // Check consent management
        List<ConsentManagement__c> consents = [
            SELECT Consent_Status__c FROM ConsentManagement__c 
            WHERE Document__c = :documentId 
            AND Data_Subject_Type__c = 'INDIVIDUAL'
        ];
        if (hasPersonalData && consents.isEmpty()) {
            riskScore += 30;
        }
        
        // Check data sharing restrictions
        List<DataSharingRestriction__c> restrictions = [
            SELECT Id FROM DataSharingRestriction__c 
            WHERE Document__c = :documentId 
            AND Status__c = 'ACTIVE'
        ];
        if (hasPersonalData && restrictions.isEmpty()) {
            riskScore += 20;
        }
        
        return Math.min(100, riskScore);
    }
    
    private static Decimal assessReputationalRisk(String documentId, DocumentAnalysisRecord__c analysis) {
        Decimal riskScore = 0;
        
        // Check document classification
        String docType = analysis.Document_Type__c;
        if (docType == 'LEGAL_CONTRACT' || docType == 'POLICY_DOCUMENT') {
            riskScore += 20; // Higher reputational risk for legal/policy docs
        }
        
        // Check public access
        List<ContentDocumentLink> publicLinks = [
            SELECT Visibility FROM ContentDocumentLink 
            WHERE ContentDocumentId = :documentId 
            AND Visibility = 'AllUsers'
        ];
        if (!publicLinks.isEmpty() && analysis.Sensitivity_Level__c != 'LOW') {
            riskScore += 40;
        }
        
        // Check recent security incidents
        List<SecurityIncident__c> incidents = [
            SELECT Severity__c FROM SecurityIncident__c 
            WHERE Document__c = :documentId 
            AND CreatedDate >= :DateTime.now().addDays(-30)
        ];
        for (SecurityIncident__c incident : incidents) {
            if (incident.Severity__c == 'HIGH') {
                riskScore += 30;
            } else if (incident.Severity__c == 'MEDIUM') {
                riskScore += 15;
            }
        }
        
        // Check media attention indicators
        List<MediaMention__c> mentions = [
            SELECT Sentiment__c FROM MediaMention__c 
            WHERE Related_Document__c = :documentId 
            AND CreatedDate >= :DateTime.now().addDays(-90)
        ];
        for (MediaMention__c mention : mentions) {
            if (mention.Sentiment__c == 'NEGATIVE') {
                riskScore += 25;
            }
        }
        
        return Math.min(100, riskScore);
    }
    
    private static Decimal assessFinancialRisk(String documentId, DocumentAnalysisRecord__c analysis) {
        Decimal riskScore = 0;
        
        // Check document type
        String docType = analysis.Document_Type__c;
        if (docType == 'FINANCIAL_DOCUMENT' || docType == 'LEGAL_CONTRACT') {
            riskScore += 25;
        }
        
        // Check potential liability
        List<LiabilityAssessment__c> liabilities = [
            SELECT Estimated_Cost__c FROM LiabilityAssessment__c 
            WHERE Document__c = :documentId 
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
        if (!liabilities.isEmpty() && liabilities[0].Estimated_Cost__c > 100000) {
            riskScore += 35;
        }
        
        // Check compliance penalties
        List<ComplianceValidationRecord__c> complianceRecords = [
            SELECT Overall_Status__c FROM ComplianceValidationRecord__c 
            WHERE Document__c = :documentId 
            AND Overall_Status__c = 'NON_COMPLIANT'
        ];
        if (!complianceRecords.isEmpty()) {
            riskScore += 30; // Non-compliance can lead to fines
        }
        
        // Check insurance coverage
        List<InsuranceCoverage__c> coverage = [
            SELECT Coverage_Amount__c FROM InsuranceCoverage__c 
            WHERE Document__c = :documentId 
            AND Status__c = 'ACTIVE'
        ];
        if (coverage.isEmpty()) {
            riskScore += 20;
        }
        
        return Math.min(100, riskScore);
    }
    
    private static Decimal calculateOverallRiskScore(RiskAssessmentResult result) {
        // Weighted average of risk categories
        Map<String, Decimal> weights = new Map<String, Decimal>{
            'security' => 0.25,
            'compliance' => 0.20,
            'privacy' => 0.20,
            'operational' => 0.15,
            'reputational' => 0.10,
            'financial' => 0.10
        };
        
        Decimal weightedScore = 
            (result.securityRiskScore * weights.get('security')) +
            (result.complianceRiskScore * weights.get('compliance')) +
            (result.privacyRiskScore * weights.get('privacy')) +
            (result.operationalRiskScore * weights.get('operational')) +
            (result.reputationalRiskScore * weights.get('reputational')) +
            (result.financialRiskScore * weights.get('financial'));
            
        return Math.round(weightedScore);
    }
    
    private static String determineRiskLevel(Decimal overallScore) {
        if (overallScore >= 80) return 'CRITICAL';
        if (overallScore >= 60) return 'HIGH';
        if (overallScore >= 40) return 'MEDIUM';
        if (overallScore >= 20) return 'LOW';
        return 'MINIMAL';
    }
    
    private static List<String> identifyRiskFactors(String documentId, DocumentAnalysisRecord__c analysis, RiskAssessmentResult result) {
        List<String> factors = new List<String>();
        
        if (result.securityRiskScore > 50) {
            factors.add('Inadequate security controls');
        }
        if (result.complianceRiskScore > 50) {
            factors.add('Compliance violations detected');
        }
        if (result.privacyRiskScore > 50) {
            factors.add('Privacy protection deficiencies');
        }
        if (result.reputationalRiskScore > 50) {
    factors.add('Reputational exposure concerns');
}
if (result.financialRiskScore > 50) {
    factors.add('Financial liability risks');
}

// Specific risk factors based on document characteristics
if (analysis.Sensitivity_Level__c == 'CRITICAL') {
    factors.add('Critical sensitivity classification');
}

if (analysis.Document_Type__c == 'LEGAL_CONTRACT') {
    factors.add('Legal contractual obligations');
}

List<String> topics = analysis.Key_Topics__c != null ? analysis.Key_Topics__c.split(';') : new List<String>();
if (topics.contains('PERSONAL_DATA')) {
    factors.add('Personal data processing');
}
if (topics.contains('BIOMETRIC')) {
    factors.add('Biometric data handling');
}
if (topics.contains('FINANCIAL')) {
    factors.add('Financial information exposure');
}

return factors;
}

private static List<String> generateMitigationRecommendations(RiskAssessmentResult result) {
    List<String> recommendations = new List<String>();
    
    // Security-specific recommendations
    if (result.securityRiskScore > 50) {
        recommendations.add('Implement advanced encryption protocols (AES-256)');
        recommendations.add('Enable multi-factor authentication for document access');
        recommendations.add('Configure automated tamper detection systems');
        recommendations.add('Establish regular security audits and penetration testing');
    }
    
    // Compliance-specific recommendations
    if (result.complianceRiskScore > 50) {
        recommendations.add('Conduct comprehensive regulatory compliance assessment');
        recommendations.add('Implement automated compliance monitoring');
        recommendations.add('Establish regular compliance training programs');
        recommendations.add('Create compliance violation response procedures');
    }
    
    // Privacy-specific recommendations
    if (result.privacyRiskScore > 50) {
        recommendations.add('Implement data minimization principles');
        recommendations.add('Establish consent management processes');
        recommendations.add('Configure data retention and deletion policies');
        recommendations.add('Implement privacy-by-design frameworks');
    }
    
    // Operational recommendations
    if (result.operationalRiskScore > 50) {
        recommendations.add('Establish robust backup and recovery procedures');
        recommendations.add('Implement document version control systems');
        recommendations.add('Create disaster recovery and business continuity plans');
        recommendations.add('Establish clear collaboration and access protocols');
    }
    
    // General recommendations for high overall risk
    if (result.overallRiskScore > 70) {
        recommendations.add('Conduct immediate comprehensive risk assessment');
        recommendations.add('Engage external security and compliance consultants');
        recommendations.add('Implement executive-level risk governance');
        recommendations.add('Create detailed incident response procedures');
    }
    
    return recommendations;
}

private static DocumentSecurityConfig__c getSecurityConfig(String documentId) {
    try {
        return [
            SELECT Encryption_Enabled__c, Encryption_Type__c
            FROM DocumentSecurityConfig__c 
            WHERE Document__c = :documentId 
            AND Status__c = 'ACTIVE' 
            LIMIT 1
        ];
    } catch (QueryException e) {
        return null;
    }
}

public class RiskAssessmentResult {
    public Decimal securityRiskScore;
    public Decimal complianceRiskScore;
    public Decimal operationalRiskScore;
    public Decimal privacyRiskScore;
    public Decimal reputationalRiskScore;
    public Decimal financialRiskScore;
    public Decimal overallRiskScore;
    public String riskLevel;
    public List<String> riskFactors;
    public List<String> mitigationRecommendations;
    public String assessmentError;
    
    public RiskAssessmentResult() {
        this.riskFactors = new List<String>();
        this.mitigationRecommendations = new List<String>();
    }
}
}

