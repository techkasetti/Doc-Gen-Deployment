// ===================================
// RegulatoryComplianceEngine Class
// Comprehensive compliance validation across multiple regulatory frameworks
// ===================================

public class RegulatoryComplianceEngine {

    // ===============================
    // Entry Point: Validate Document Compliance
    // ===============================
    public static ComplianceValidationResult validateDocumentCompliance(
        String documentId,
        List<String> requiredFrameworks
    ) {
        ComplianceValidationResult result = new ComplianceValidationResult();
        result.documentId = documentId;
        result.validationTimestamp = DateTime.now();
        result.frameworkResults = new Map<String, FrameworkComplianceResult>();

        for (String framework : requiredFrameworks) {
            FrameworkComplianceResult frameworkResult = validateFrameworkCompliance(documentId, framework);
            result.frameworkResults.put(framework, frameworkResult);

            // Calculate overall score (take lowest)
            if (result.overallComplianceScore == null ||
                frameworkResult.complianceScore < result.overallComplianceScore) {
                result.overallComplianceScore = frameworkResult.complianceScore;
            }
        }

        // Determine overall compliance status
        result.overallStatus = determineOverallComplianceStatus(result.overallComplianceScore);

        // Create compliance validation record
        createComplianceValidationRecord(result);

        return result;
    }

    // ===============================
    // Framework Dispatcher
    // ===============================
    private static FrameworkComplianceResult validateFrameworkCompliance(String documentId, String framework) {
        FrameworkComplianceResult result = new FrameworkComplianceResult();
        result.framework = framework;
        result.validationItems = new List<ComplianceValidationItem>();

        switch on framework.toUpperCase() {
            when 'GDPR'    { result = validateGDPRCompliance(documentId); }
            when 'HIPAA'   { result = validateHIPAACompliance(documentId); }
            when 'SOX'     { result = validateSOXCompliance(documentId); }
            when 'PCI_DSS' { result = validatePCIDSSCompliance(documentId); }
            when 'UIDAI'   { result = validateUIDAICompliance(documentId); }
            when 'SEBI'    { result = validateSEBICompliance(documentId); }
            when else      { result = createUnknownFrameworkResult(framework); }
        }

        return result;
    }

    // ===============================
    // GDPR Compliance Validation
    // ===============================
    private static FrameworkComplianceResult validateGDPRCompliance(String documentId) {
        FrameworkComplianceResult result = new FrameworkComplianceResult();
        result.framework = 'GDPR';
        result.validationItems = new List<ComplianceValidationItem>();

        // GDPR Article 5 - Principles
        result.validationItems.add(validateDataMinimization(documentId));
        result.validationItems.add(validatePurposeLimitation(documentId));
        result.validationItems.add(validateDataAccuracy(documentId));
        result.validationItems.add(validateStorageLimitation(documentId));

        // GDPR Article 6 - Lawfulness
        result.validationItems.add(validateProcessingLawfulness(documentId));

        // GDPR Article 13-14 - Information
        result.validationItems.add(validateTransparencyInformation(documentId));

        // GDPR Article 17 - Right to Erasure
        result.validationItems.add(validateRightToErasure(documentId));

        // GDPR Article 25 - Data protection by design
        result.validationItems.add(validateDataProtectionByDesign(documentId));

        // GDPR Article 30 - Records of processing
        result.validationItems.add(validateProcessingRecords(documentId));

        // GDPR Article 32 - Security of processing
        result.validationItems.add(validateSecurityOfProcessing(documentId));

        // Calculate score & status
        result.complianceScore = calculateFrameworkScore(result.validationItems);
        result.status = (result.complianceScore >= 80) ? 'COMPLIANT' : 'NON_COMPLIANT';
        result.recommendedActions = generateGDPRRecommendations(result.validationItems);

        return result;
    }

    // ===============================
    // HIPAA Compliance Validation
    // ===============================
    private static FrameworkComplianceResult validateHIPAACompliance(String documentId) {
        FrameworkComplianceResult result = new FrameworkComplianceResult();
        result.framework = 'HIPAA';
        result.validationItems = new List<ComplianceValidationItem>();

        // HIPAA Security Rule - Administrative Safeguards
        result.validationItems.add(validateSecurityOfficer(documentId));
        result.validationItems.add(validateWorkforceTraining(documentId));
        result.validationItems.add(validateAccessManagement(documentId));
        result.validationItems.add(validateSecurityIncidentProcedures(documentId));

        // HIPAA Security Rule - Physical Safeguards
        result.validationItems.add(validatePhysicalAccess(documentId));
        result.validationItems.add(validateWorkstationSecurity(documentId));
        result.validationItems.add(validateMediaControls(documentId));

        // HIPAA Security Rule - Technical Safeguards
        result.validationItems.add(validateAccessControl(documentId));
        result.validationItems.add(validateAuditControls(documentId));
        result.validationItems.add(validateIntegrity(documentId));
        result.validationItems.add(validateTransmissionSecurity(documentId));

        // HIPAA Privacy Rule
        result.validationItems.add(validateMinimumNecessary(documentId));
        result.validationItems.add(validatePatientRights(documentId));
        result.validationItems.add(validateBusinessAssociateAgreements(documentId));

        // Calculate score & status
        result.complianceScore = calculateFrameworkScore(result.validationItems);
        result.status = (result.complianceScore >= 85) ? 'COMPLIANT' : 'NON_COMPLIANT';
        result.recommendedActions = generateHIPAARecommendations(result.validationItems);

        return result;
    }

    // ===============================
    // SOX Compliance Validation
    // ===============================
    private static FrameworkComplianceResult validateSOXCompliance(String documentId) {
        FrameworkComplianceResult result = new FrameworkComplianceResult();
        result.framework = 'SOX';
        result.validationItems = new List<ComplianceValidationItem>();

        // SOX Section 302
        result.validationItems.add(validateCEOCFOCertification(documentId));
        result.validationItems.add(validateInternalControlsCertification(documentId));

        // SOX Section 404
        result.validationItems.add(validateInternalControlsAssessment(documentId));
        result.validationItems.add(validateControlDeficiencyReporting(documentId));

        // SOX Section 409
        result.validationItems.add(validateRealTimeDisclosure(documentId));

        // SOX Section 802
        result.validationItems.add(validateDocumentRetention(documentId));
        result.validationItems.add(validateAuditWorkpaperRetention(documentId));

        // SOX Section 906
        result.validationItems.add(validateFinancialStatementCertification(documentId));

        // Calculate score & status
        result.complianceScore = calculateFrameworkScore(result.validationItems);
        result.status = (result.complianceScore >= 90) ? 'COMPLIANT' : 'NON_COMPLIANT';
        result.recommendedActions = generateSOXRecommendations(result.validationItems);

        return result;
    }

    // ===============================
    // UIDAI Compliance Validation
    // ===============================
    private static FrameworkComplianceResult validateUIDAICompliance(String documentId) {
        FrameworkComplianceResult result = new FrameworkComplianceResult();
        result.framework = 'UIDAI';
        result.validationItems = new List<ComplianceValidationItem>();

        // Aadhaar Act 2016 - Section 8
        result.validationItems.add(validateBiometricDataProtection(documentId));
        result.validationItems.add(validateCoreVsDemographicData(documentId));

        // Section 29 - Restrictions on sharing
        result.validationItems.add(validateDataSharingRestrictions(documentId));
        result.validationItems.add(validateConsentRequirements(documentId));

        // Section 33 - Disclosure
        result.validationItems.add(validateDisclosureRestrictions(documentId));
        result.validationItems.add(validateCourtOrderCompliance(documentId));

        // UIDAI Regulations - Authentication
        result.validationItems.add(validateAuthenticationProtocols(documentId));
        result.validationItems.add(validateAuditTrailRequirements(documentId));

        // UIDAI Regulations - Data security
        result.validationItems.add(validateEncryptionCompliance(documentId));
        result.validationItems.add(validateDataLocalization(documentId));

        // Calculate score & status
        result.complianceScore = calculateFrameworkScore(result.validationItems);
        result.status = (result.complianceScore >= 95) ? 'COMPLIANT' : 'NON_COMPLIANT';
        result.recommendedActions = generateUIDAIRecommendations(result.validationItems);

        return result;
    }

    // ===============================
    // Utility & Shared Methods (Samples)
    // ===============================

    private static Boolean checkDataClassificationTags(String documentId) {
        List<ContentDocumentLink> links = [
            SELECT ContentDocument.Title
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :documentId
            AND LinkedEntity.Type = 'DataClassification__c'
        ];
        return links.size() > 0;
    }

    private static Decimal calculateFrameworkScore(List<ComplianceValidationItem> validationItems) {
        if (validationItems.isEmpty()) return 0;
        Decimal totalScore = 0;
        for (ComplianceValidationItem item : validationItems) {
            totalScore += item.score;
        }
        return totalScore / validationItems.size();
    }

    private static String determineOverallComplianceStatus(Decimal overallScore) {
        if (overallScore >= 90) return 'FULLY_COMPLIANT';
        if (overallScore >= 75) return 'SUBSTANTIALLY_COMPLIANT';
        if (overallScore >= 50) return 'PARTIALLY_COMPLIANT';
        return 'NON_COMPLIANT';
    }

    // ===============================
    // Record Creation
    // ===============================
    private static void createComplianceValidationRecord(ComplianceValidationResult result) {
        ComplianceValidationRecord__c record = new ComplianceValidationRecord__c(
            Document__c               = result.documentId,
            Validation_Date__c        = result.validationTimestamp,
            Overall_Compliance_Score__c = result.overallComplianceScore,
            Overall_Status__c         = result.overallStatus,
            Frameworks_Tested__c      = String.join(new List<String>(result.frameworkResults.keySet()), ';'),
            Validation_Summary__c     = generateValidationSummary(result),
            Risk_Level__c             = determineRiskLevel(result.overallComplianceScore),
            Next_Review_Date__c       = Date.today().addDays(30),
            Remediation_Required__c   = result.overallComplianceScore < 75,
            Critical_Issues_Count__c  = countCriticalIssues(result),
            Recommendations_Generated__c = true
        );
        insert record;

        // Insert framework-level details
        for (String framework : result.frameworkResults.keySet()) {
            createFrameworkValidationRecord(record.Id, result.frameworkResults.get(framework));
        }
    }

    private static void createFrameworkValidationRecord(
        String validationRecordId,
        FrameworkComplianceResult frameworkResult
    ) {
        FrameworkValidationRecord__c record = new FrameworkValidationRecord__c(
            Compliance_Validation__c  = validationRecordId,
            Framework_Name__c         = frameworkResult.framework,
            Compliance_Score__c       = frameworkResult.complianceScore,
            Compliance_Status__c      = frameworkResult.status,
            Items_Tested__c           = frameworkResult.validationItems.size(),
            Compliant_Items__c        = countCompliantItems(frameworkResult.validationItems),
            Critical_Failures__c      = countCriticalFailures(frameworkResult.validationItems),
            Recommended_Actions__c    = String.join(frameworkResult.recommendedActions, '\n'),
            Framework_Summary__c      = generateFrameworkSummary(frameworkResult),
            Risk_Rating__c            = determineFrameworkRisk(frameworkResult.complianceScore)
        );
        insert record;
    }

// ===================================
// RegulatoryComplianceEngine (Continuation)
// ===================================


    private static Integer countCriticalIssues(ComplianceValidationResult result) {
        Integer criticalCount = 0;
        for (FrameworkComplianceResult frameworkResult : result.frameworkResults.values()) {
            criticalCount += countCriticalFailures(frameworkResult.validationItems);
        }
        return criticalCount;
    }

    private static Integer countCompliantItems(List<ComplianceValidationItem> items) {
        Integer compliantCount = 0;
        for (ComplianceValidationItem item : items) {
            if (item.complianceStatus == 'COMPLIANT') {
                compliantCount++;
            }
        }
        return compliantCount;
    }

    private static Integer countCriticalFailures(List<ComplianceValidationItem> items) {
        Integer criticalCount = 0;
        for (ComplianceValidationItem item : items) {
            if (item.complianceStatus == 'NON_COMPLIANT' && item.score < 25) {
                criticalCount++;
            }
        }
        return criticalCount;
    }

    private static String generateFrameworkSummary(FrameworkComplianceResult result) {
        return result.framework + ' validation: ' +
               countCompliantItems(result.validationItems) + ' of ' +
               result.validationItems.size() + ' requirements met. Score: ' +
               result.complianceScore + '%.';
    }

    private static String determineFrameworkRisk(Decimal score) {
        if (score < 60) return 'HIGH_RISK';
        if (score < 80) return 'MEDIUM_RISK';
        if (score < 95) return 'LOW_RISK';
        return 'MINIMAL_RISK';
    }

    // ===============================
    // Recommendations Generators
    // ===============================

    private static List<String> generateGDPRRecommendations(List<ComplianceValidationItem> items) {
        List<String> recommendations = new List<String>();
        for (ComplianceValidationItem item : items) {
            if (item.complianceStatus != 'COMPLIANT') {
                recommendations.addAll(item.recommendedActions);
            }
        }
        if (recommendations.isEmpty()) {
            recommendations.add('Maintain current GDPR compliance measures');
            recommendations.add('Schedule regular compliance audits');
        }
        return recommendations;
    }

    private static List<String> generateHIPAARecommendations(List<ComplianceValidationItem> items) {
        List<String> recommendations = new List<String>();
        for (ComplianceValidationItem item : items) {
            if (item.complianceStatus != 'COMPLIANT') {
                recommendations.addAll(item.recommendedActions);
            }
        }
        if (recommendations.isEmpty()) {
            recommendations.add('Continue HIPAA compliance monitoring');
            recommendations.add('Update risk assessments quarterly');
        }
        return recommendations;
    }

    private static List<String> generateSOXRecommendations(List<ComplianceValidationItem> items) {
        List<String> recommendations = new List<String>();
        for (ComplianceValidationItem item : items) {
            if (item.complianceStatus != 'COMPLIANT') {
                recommendations.addAll(item.recommendedActions);
            }
        }
        if (recommendations.isEmpty()) {
            recommendations.add('Maintain SOX compliance documentation');
            recommendations.add('Continue quarterly internal control testing');
        }
        return recommendations;
    }

    private static List<String> generateUIDAIRecommendations(List<ComplianceValidationItem> items) {
        List<String> recommendations = new List<String>();
        for (ComplianceValidationItem item : items) {
            if (item.complianceStatus != 'COMPLIANT') {
                recommendations.addAll(item.recommendedActions);
            }
        }
        if (recommendations.isEmpty()) {
            recommendations.add('Maintain UIDAI compliance measures');
            recommendations.add('Regular biometric data security audits');
        }
        return recommendations;
    }

    // ===============================
    // HIPAA Validation Methods
    // ===============================

    private static ComplianceValidationItem validateSecurityOfficer(String documentId) {
        ComplianceValidationItem item = new ComplianceValidationItem();
        item.requirementId = 'HIPAA_164_308_A1';
        item.requirementName = 'Security Officer';
        item.description = 'Assign security responsibilities to an individual';

        Boolean hasSecurityOfficer = checkSecurityOfficerAssignment(documentId);

        if (hasSecurityOfficer) {
            item.complianceStatus = 'COMPLIANT';
            item.score = 100;
            item.findings = 'Security officer properly assigned';
        } else {
            item.complianceStatus = 'NON_COMPLIANT';
            item.score = 0;
            item.findings = 'No security officer assignment found';
            item.recommendedActions.add('Assign dedicated security officer');
            item.recommendedActions.add('Document security responsibilities');
        }
        return item;
    }

    private static ComplianceValidationItem validateAccessControl(String documentId) {
        ComplianceValidationItem item = new ComplianceValidationItem();
        item.requirementId = 'HIPAA_164_312_A1';
        item.requirementName = 'Access Control';
        item.description = 'Assign unique user identification and automatic logoff';

        Boolean hasAccessControl     = checkAccessControlImplementation(documentId);
        Boolean hasUserIdentification = checkUniqueUserIdentification(documentId);
        Boolean hasAutomaticLogoff    = checkAutomaticLogoff(documentId);

        if (hasAccessControl && hasUserIdentification && hasAutomaticLogoff) {
            item.complianceStatus = 'COMPLIANT';
            item.score = 100;
            item.findings = 'Access control properly implemented';
        } else {
            item.complianceStatus = 'NON_COMPLIANT';
            item.score = 30;
            item.findings = 'Access control implementation incomplete';
            item.recommendedActions.add('Implement unique user identification');
            item.recommendedActions.add('Configure automatic logoff');
            item.recommendedActions.add('Establish role-based access controls');
        }
        return item;
    }

    // ===============================
    // SOX Validation Methods
    // ===============================

    private static ComplianceValidationItem validateCEOCFOCertification(String documentId) {
        ComplianceValidationItem item = new ComplianceValidationItem();
        item.requirementId = 'SOX_302';
        item.requirementName = 'CEO/CFO Certification';
        item.description = 'CEO and CFO must certify financial reports';

        Boolean hasCEOCertification = checkCEOCertification(documentId);
        Boolean hasCFOCertification = checkCFOCertification(documentId);

        if (hasCEOCertification && hasCFOCertification) {
            item.complianceStatus = 'COMPLIANT';
            item.score = 100;
            item.findings = 'CEO and CFO certifications present';
        } else {
            item.complianceStatus = 'NON_COMPLIANT';
            item.score = 0;
            item.findings = 'Missing executive certifications';
            item.recommendedActions.add('Obtain CEO certification');
            item.recommendedActions.add('Obtain CFO certification');
            item.recommendedActions.add('Establish certification process');
        }
        return item;
    }

    // ===============================
    // UIDAI Validation Methods
    // ===============================

    private static ComplianceValidationItem validateBiometricDataProtection(String documentId) {
        ComplianceValidationItem item = new ComplianceValidationItem();
        item.requirementId = 'UIDAI_SECTION8';
        item.requirementName = 'Biometric Data Protection';
        item.description = 'Core biometric information protection requirements';

        Boolean hasBiometricEncryption   = checkBiometricEncryption(documentId);
        Boolean hasAccessRestriction     = checkBiometricAccessRestriction(documentId);
        Boolean hasAuditTrail            = checkBiometricAuditTrail(documentId);

        if (hasBiometricEncryption && hasAccessRestriction && hasAuditTrail) {
            item.complianceStatus = 'COMPLIANT';
            item.score = 100;
            item.findings = 'Biometric data properly protected';
        } else {
            item.complianceStatus = 'NON_COMPLIANT';
            item.score = 10;
            item.findings = 'Biometric protection measures insufficient';
            item.recommendedActions.add('Implement biometric data encryption');
            item.recommendedActions.add('Restrict biometric data access');
            item.recommendedActions.add('Enable biometric audit trails');
        }
        return item;
    }

    // ===============================
    // Utility Check Methods
    // ===============================

    private static Boolean checkSecurityOfficerAssignment(String documentId) {
        List<SecurityOfficerAssignment__c> assignments = [
            SELECT Id
            FROM SecurityOfficerAssignment__c
            WHERE Document__c = :documentId
            AND Status__c = 'ACTIVE'
        ];
        return assignments.size() > 0;
    }

    private static Boolean checkAccessControlImplementation(String documentId) {
        List<AccessControlConfig__c> configs = [
            SELECT Id
            FROM AccessControlConfig__c
            WHERE Document__c = :documentId
            AND Status__c = 'ENABLED'
        ];
        return configs.size() > 0;
    }

    private static Boolean checkUniqueUserIdentification(String documentId) {
        List<UserIdentificationConfig__c> configs = [
            SELECT Id
            FROM UserIdentificationConfig__c
            WHERE Document__c = :documentId
            AND Unique_Identification_Enabled__c = true
        ];
        return configs.size() > 0;
    }

    private static Boolean checkAutomaticLogoff(String documentId) {
        List<SessionManagementConfig__c> configs = [
            SELECT Id
            FROM SessionManagementConfig__c
            WHERE Document__c = :documentId
            AND Auto_Logoff_Enabled__c = true
        ];
        return configs.size() > 0;
    }

    private static Boolean checkCEOCertification(String documentId) {
        List<ExecutiveCertification__c> certifications = [
            SELECT Id
            FROM ExecutiveCertification__c
            WHERE Document__c = :documentId
            AND Executive_Role__c = 'CEO'
            AND Status__c = 'CERTIFIED'
        ];
        return certifications.size() > 0;
    }

    private static Boolean checkCFOCertification(String documentId) {
        List<ExecutiveCertification__c> certifications = [
            SELECT Id
            FROM ExecutiveCertification__c
            WHERE Document__c = :documentId
            AND Executive_Role__c = 'CFO'
            AND Status__c = 'CERTIFIED'
        ];
        return certifications.size() > 0;
    }

    private static Boolean checkBiometricEncryption(String documentId) {
        DocumentSecurityConfig__c config = getDocumentSecurityConfig(documentId);
        return config != null &&
               config.Encryption_Enabled__c &&
               config.Encryption_Type__c.contains('BIOMETRIC');
    }

    private static Boolean checkBiometricAccessRestriction(String documentId) {
        List<BiometricAccessControl__c> controls = [
            SELECT Id
            FROM BiometricAccessControl__c
            WHERE Document__c = :documentId
            AND Access_Restricted__c = true
        ];
        return controls.size() > 0;
    }

    private static Boolean checkBiometricAuditTrail(String documentId) {
        List<BiometricAuditLog__c> logs = [
            SELECT Id
            FROM BiometricAuditLog__c
            WHERE Document__c = :documentId
            AND CreatedDate >= :DateTime.now().addDays(-30)
        ];
        return logs.size() > 0;
    }

    // ===============================
    // GDPR Validation (Example Extra)
    // ===============================

    private static ComplianceValidationItem validateDataAccuracy(String documentId) {
        ComplianceValidationItem item = new ComplianceValidationItem();
        item.requirementId = 'GDPR_ART5_1D';
        item.requirementName = 'Data Accuracy';
        item.description = 'Personal data shall be accurate and kept up to date';

        Boolean hasDataValidation  = checkDataValidationProcess(documentId);
        Boolean hasUpdateProcedures = checkDataUpdateProcedures(documentId);

        if (hasDataValidation && hasUpdateProcedures) {
            item.complianceStatus = 'COMPLIANT';
            item.score = 100;
            item.findings = 'Data accuracy measures in place';
        } else {
            item.complianceStatus = 'NON_COMPLIANT';
            item.score = 40;
            item.findings = 'Data accuracy controls need improvement';
            item.recommendedActions.add('Implement data validation procedures');
            item.recommendedActions.add('Establish data update processes');
        }
        return item;
    }

    private static Boolean checkDataValidationProcess(String documentId) {
        List<DataValidationProcess__c> processes = [
            SELECT Id
            FROM DataValidationProcess__c
            WHERE Document__c = :documentId
            AND Status__c = 'ACTIVE'
        ];
        return processes.size() > 0;
    }

    private static Boolean checkDataUpdateProcedures(String documentId) {
        List<DataUpdateProcedure__c> procedures = [
            SELECT Id
            FROM DataUpdateProcedure__c
            WHERE Document__c = :documentId
            AND Status__c = 'IMPLEMENTED'
        ];
        return procedures.size() > 0;
    }

    // ===============================
    // Unknown Framework Handler
    // ===============================

    private static FrameworkComplianceResult createUnknownFrameworkResult(String framework) {
        FrameworkComplianceResult result = new FrameworkComplianceResult();
        result.framework = framework;
        result.complianceScore = 0;
        result.status = 'UNKNOWN_FRAMEWORK';
        result.validationItems = new List<ComplianceValidationItem>();
        result.recommendedActions = new List<String>{
            'Framework "' + framework + '" is not supported',
            'Contact compliance team for framework assessment',
            'Consider implementing supported regulatory frameworks'
        };

        ComplianceValidationItem unknownItem = new ComplianceValidationItem();
        unknownItem.requirementId = 'UNKNOWN_FRAMEWORK';
        unknownItem.requirementName = 'Unknown Compliance Framework';
        unknownItem.description = 'Framework ' + framework + ' is not supported by the system';
        unknownItem.complianceStatus = 'NOT_EVALUATED';
        unknownItem.score = 0;
        unknownItem.findings = 'Framework validation not available';
        unknownItem.recommendedActions.add('Implement framework-specific validation rules');

        result.validationItems.add(unknownItem);
        return result;
    }

    // ===============================
    // Wrapper Classes
    // ===============================

    public class ComplianceValidationResult {
        public String documentId;
        public DateTime validationTimestamp;
        public Map<String, FrameworkComplianceResult> frameworkResults;
        public Decimal overallComplianceScore;
        public String overallStatus;

        public ComplianceValidationResult() {
            this.frameworkResults = new Map<String, FrameworkComplianceResult>();
            this.overallComplianceScore = 0;
        }
    }

    public class FrameworkComplianceResult {
        public String framework;
        public List<ComplianceValidationItem> validationItems;
        public Decimal complianceScore;
        public String status;
        public List<String> recommendedActions;

        public FrameworkComplianceResult() {
            this.validationItems = new List<ComplianceValidationItem>();
            this.recommendedActions = new List<String>();
            this.complianceScore = 0;
            this.status = 'NOT_EVALUATED';
        }
    }

    public class ComplianceValidationItem {
        public String requirementId;
        public String requirementName;
        public String description;
        public String complianceStatus;
        public Decimal score;
        public String findings;
        public List<String> recommendedActions;

        public ComplianceValidationItem() {
            this.recommendedActions = new List<String>();
            this.score = 0;
            this.complianceStatus = 'NOT_EVALUATED';
        }
    }

public class FrameworkComplianceResult {
    public String status;
    public List<String> recommendedActions;
    public List<ComplianceValidationItem> validationItems;

    public FrameworkComplianceResult() {
        this.validationItems = new List<ComplianceValidationItem>();
        this.recommendedActions = new List<String>();
    }
}

public class ComplianceValidationItem {
    public String requirementId;
    public String requirementName;
    public String description;
    public String complianceStatus;
    public Decimal score;
    public String findings;
    public List<String> recommendedActions;

    public ComplianceValidationItem() {
        this.recommendedActions = new List<String>();
    }
}
}