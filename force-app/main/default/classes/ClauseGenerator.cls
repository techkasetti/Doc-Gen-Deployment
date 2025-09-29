public with sharing class ClauseGenerator {
    
    //  private static final Map<String, Map<String, String>> CLAUSE_TEMPLATES = new Map<String, Map<String, String>>{
    //     'US' => new Map<String, String>{
    //         'Employment' => 'This employment agreement adheres to US federal employment laws and ',
    //         'NDA' => 'This non-disclosure agreement follows US confidentiality standards and ',
    //         'SLA' => 'This service level agreement meets US commercial standards and '
    //     },
    //     'EU' => new Map<String, String>{
    //         'Employment' => 'This employment agreement complies with GDPR regulations and EU employment laws and ',
    //         'NDA' => 'This non-disclosure agreement adheres to EU data protection directives and ',
    //         'SLA' => 'This service level agreement meets EU commercial regulations and '
    //     }
    // };
    
    // Static clause templates for different scenarios
    private static final Map<String, Map<String, String>> CLAUSE_TEMPLATES = new Map<String, Map<String, String>>{
        'US' => new Map<String, String>{
            'Employment' => 'This employment agreement is governed by the laws of the United States. The employee acknowledges that they are an at-will employee and that employment may be terminated by either party with or without cause. The employee agrees to maintain confidentiality of all proprietary information and agrees that any disputes will be resolved through binding arbitration.',
            'NDA' => 'This Non-Disclosure Agreement is governed by United States federal and state laws. The receiving party agrees to maintain strict confidentiality of all disclosed information for a period of five (5) years from the date of disclosure. Violation of this agreement may result in injunctive relief and monetary damages.',
            'SLA' => 'This Service Level Agreement establishes performance standards and remedies under United States commercial law. Service provider guarantees 99.9% uptime with penalties for non-compliance. All disputes shall be resolved in United States courts.'
        },
        'EU' => new Map<String, String>{
            'Employment' => 'This employment contract complies with European Union employment directives and GDPR data protection requirements. The employee has the right to data portability and erasure as defined under GDPR Article 17. This agreement is subject to the employment laws of the European Union member state where services are performed.',
            'NDA' => 'This Non-Disclosure Agreement is GDPR-compliant and respects the data subject rights under European Union law. Personal data processing is limited to legitimate business interests. Data retention is limited to three (3) years unless legal obligations require longer retention.',
            'SLA' => 'This Service Level Agreement complies with EU Digital Services Act and GDPR requirements. Data processing activities are documented and data subjects retain full rights under GDPR. Cross-border data transfers comply with Standard Contractual Clauses (SCCs).'
        },
        'APAC' => new Map<String, String>{
            'Employment' => 'This employment agreement is subject to local labor laws and regulations in the Asia-Pacific region. The employee acknowledges compliance with local data protection laws and agrees to dispute resolution through local arbitration procedures.',
            'NDA' => 'This Non-Disclosure Agreement respects local privacy and data protection laws in the Asia-Pacific region. Confidential information is protected according to local standards with appropriate cross-border transfer safeguards.',
            'SLA' => 'This Service Level Agreement complies with regional technology and data localization requirements. Service delivery meets local regulatory standards with appropriate data residency controls.'
        }
    };

    //  private static final Map<String, String> ROLE_SPECIFIC_CLAUSES = new Map<String, String>{
    //     'Manager' => 'includes management responsibilities and authorized signatory powers. ',
    //     'Employee' => 'defines standard employee obligations and rights. ',
    //     'Developer' => 'includes intellectual property and confidentiality obligations. ',
    //     'Admin' => 'defines administrative access and system management responsibilities. '
    // };
    
    private static final Map<String, String> ROLE_SPECIFIC_CLAUSES = new Map<String, String>{
        'Manager' => 'As a management-level employee, you acknowledge additional fiduciary responsibilities and agree to act in the best interests of the company. You are authorized to make decisions within your scope of authority and are responsible for team performance and compliance.',
        'Employee' => 'As an employee, you agree to perform your duties diligently and in accordance with company policies. You acknowledge receipt of the employee handbook and agree to comply with all applicable procedures and standards.',
        'Developer' => 'As a technical team member, you acknowledge access to proprietary code, technical documentation, and system architecture. You agree to follow secure coding practices and protect intellectual property rights in all software development activities.',
        'Admin' => 'As an administrative user, you acknowledge access to sensitive system configurations and data. You agree to maintain system security, follow change management procedures, and protect confidential administrative information.'
    };
    
    /**
     * Generate AI-powered clause based on context
     * @param region Geographic region (US, EU, APAC)
     * @param role User role (Manager, Employee, Developer, Admin)
     * @param contractType Type of contract (Employment, NDA, SLA)
     * @return Generated clause text
     */
    //       public static String generateClause(String region, String role, String contractType) {

    //                 try {
    //         String clauseContent = buildDynamicClause(region, role, contractType);
    //         logClauseGeneration(region, role, contractType, clauseContent);
    //         return clauseContent;
    //     } catch (Exception e) {
                
    //         return getDefaultClause(contractType);
    //     }

    //     // try {
    //     //     String generatedClause = buildDynamicClause(region, role, contractType);
    //     //     logClauseGeneration(region, role, contractType, generatedClause);
    //     //     return generatedClause;
    //     // } catch (Exception e) {
    //     //     System.debug('Clause generation failed: ' + e.getMessage());
    //     //     return getDefaultClause(contractType);
    //     // }
    // }
    private static String getDefaultClause(String contractType) {
        return 'Standard ' + contractType + ' clause applies as per company policy.';
    }

    private static String buildDynamicClause(String region, String role, String contractType) {
        String baseClause = '';
        
        // Region-specific adaptations
        if (region == 'EU') {
            baseClause += 'In accordance with GDPR regulations, ';
        } else if (region == 'US') {
            baseClause += 'Subject to applicable state and federal laws, ';
        }
        
        // Role-specific clauses
        if (role == 'Manager') {
            baseClause += 'the authorized signatory hereby confirms ';
        } else if (role == 'Employee') {
            baseClause += 'the employee acknowledges and agrees ';
        }
        
        // Contract type specific terms
        if (contractType == 'Employment') {
            baseClause += 'to the terms and conditions of employment as outlined herein.';
        } else if (contractType == 'NDA') {
            baseClause += 'to maintain confidentiality of all disclosed information.';
        }
        
        return baseClause;
    }

       
    // public static String generateClause(String region, String role, String contractType) {
    //     try {
    //         String baseClause = getBaseClause(region, contractType);
    //         String enhancedClause = enhanceWithAI(baseClause, region, role, contractType);
    //         logClauseGeneration(region, role, contractType, 'SUCCESS', enhancedClause.length());
    //         return enhancedClause;
    //     } catch (Exception e) {
    //         logClauseGeneration(region, role, contractType, 'ERROR', 0);
    //         throw new ClauseGenerationException('Failed to generate clause: ' + e.getMessage());
    //     }
    // }
    
    @AuraEnabled
    public static String generateClause(String region, String role, String contractType) {
        System.debug('Generating clause for: Region=' + region + ', Role=' + role + ', Type=' + contractType);
        
        try {
            // Input validation
            if (String.isBlank(region) || String.isBlank(role) || String.isBlank(contractType)) {
                throw new IllegalArgumentException('All parameters (region, role, contractType) are required');
            }
            
            // Get base clause template
            String baseClause = getBaseClause(region, contractType);
            if (String.isBlank(baseClause)) {
                throw new ClauseGenerationException('No template found for region: ' + region + ', contract type: ' + contractType);
            }
            
            // Add role-specific clause
            String roleClause = ROLE_SPECIFIC_CLAUSES.get(role);
            if (String.isBlank(roleClause)) {
                throw new ClauseGenerationException('No role-specific clause found for role: ' + role);
            }
            
            // Combine clauses
            String generatedClause = baseClause + '\n\n' + roleClause;
            
            // Add AI enhancements if enabled
            generatedClause = enhanceWithAI(generatedClause, region, role, contractType);
            
            // Log successful generation
            logClauseGeneration(region, role, contractType, 'SUCCESS', generatedClause.length());
            
            System.debug('✓ Clause generated successfully, length: ' + generatedClause.length());
            return generatedClause;
            
        } catch (Exception e) {
            System.debug('✗ Clause generation failed: ' + e.getMessage());
            logClauseGeneration(region, role, contractType, 'ERROR', 0);
            throw new AuraHandledException('Clause generation failed: ' + e.getMessage());
        }
    }
      @AuraEnabled
    public static String generateClause(String region, String role, String contractType, List<String> clauses) {
        try {
            // Build dynamic clause based on parameters
            String generatedClause = buildClauseContent(region, role, contractType, clauses);
            
            // Log the generation activity
            logClauseGeneration(region, role, contractType, generatedClause);
            
            return generatedClause;
            
        } catch (Exception e) {
            System.debug('Error in generateClause: ' + e.getMessage());
            throw new AuraHandledException('Failed to generate clause: ' + e.getMessage());
        }
    }
       private static String buildClauseContent(String region, String role, String contractType, List<String> clauses) {
        StringBuilder clauseBuilder = new StringBuilder();
        
        // Base clause structure
        clauseBuilder.append('This agreement ');
        
        // Add region-specific compliance
        if (region == 'EU') {
            clauseBuilder.append('complies with GDPR requirements for EU-based ');
        } else if (region == 'US') {
            clauseBuilder.append('adheres to US federal and state regulations for ');
        } else if (region == 'IN') {
            clauseBuilder.append('follows Indian legal requirements for ');
        }
        
        // Add role-specific terms
        clauseBuilder.append(role.toLowerCase() + 's. ');
        
        // Add contract type specifics
        switch on contractType {
            when 'Employment' {
                clauseBuilder.append('The employment terms include standard confidentiality and non-compete provisions. ');
            }
            when 'NDA' {
                clauseBuilder.append('Confidential information shall remain protected for a period of 5 years. ');
            }
            when 'SLA' {
                clauseBuilder.append('Service level commitments are guaranteed with 99.9% uptime. ');
            }
        }
        
        // Add specific clauses if provided
        if (clauses != null && !clauses.isEmpty()) {
            for (String clause : clauses) {
                if (String.isNotBlank(clause)) {
                    clauseBuilder.append(clause + '. ');
                }
            }
        }
        
        return clauseBuilder.toString();
    }

    /**
     * Get base clause template for region and contract type
     */
      private static String getBaseClause(String region, String contractType) {
        if (CLAUSE_TEMPLATES.containsKey(region) && 
            CLAUSE_TEMPLATES.get(region).containsKey(contractType)) {
            return CLAUSE_TEMPLATES.get(region).get(contractType);
        }
        return 'This ' + contractType.toLowerCase() + ' agreement ';
    }
    
    // @TestVisible
    // private static String getBaseClause(String region, String contractType) {
    //     if (CLAUSE_TEMPLATES.containsKey(region)) {
    //         Map<String, String> regionTemplates = CLAUSE_TEMPLATES.get(region);
    //         return regionTemplates.get(contractType);
    //     }
    //     return null;
    // }
    
    /**
     * Enhance clause with AI-powered improvements
     */

    //   private static String enhanceWithAI(String baseClause, String region, String role, String contractType) {
    //     String enhancedClause = baseClause;
        
    //     // Add role-specific terms
    //     if (ROLE_SPECIFIC_CLAUSES.containsKey(role)) {
    //         enhancedClause += ROLE_SPECIFIC_CLAUSES.get(role);
    //     }
        
    //     // Add contract type specifics
    //     if (contractType == 'Employment') {
    //         enhancedClause += 'Terms include compensation, benefits, confidentiality, and termination procedures.';
    //     } else if (contractType == 'NDA') {
    //         enhancedClause += 'Confidentiality obligations and non-disclosure terms apply.';
    //     } else if (contractType == 'SLA') {
    //         enhancedClause += 'Service level commitments and performance metrics are defined.';
    //     }
        
    //     return enhancedClause;
    // }
    
    @TestVisible
    private static String enhanceWithAI(String baseClause, String region, String role, String contractType) {
        try {
            // Check if AI processing is enabled for this configuration
            List<DocumentLifecycleConfiguration__c> configs = [
                SELECT AIProcessingEnabled__c 
                FROM DocumentLifecycleConfiguration__c 
                WHERE Region__c = :region AND Role__c = :role AND ContractType__c = :contractType 
                LIMIT 1
            ];
            
            if (configs.isEmpty() || !configs[0].AIProcessingEnabled__c) {
                System.debug('AI processing disabled, returning base clause');
                return baseClause;
            }
            
            // AI enhancement logic
            String enhancedClause = baseClause;
            
            // Add contextual improvements based on current date and regulations
            enhancedClause += '\n\nThis agreement incorporates the latest regulatory requirements as of ' + 
                            Date.today().format() + ' and will be updated to reflect any changes in applicable law.';
            
            // Add role-specific security clauses for sensitive roles
            if (role == 'Admin' || role == 'Developer') {
                enhancedClause += '\n\nAdditional Security Requirements: You acknowledge that your role requires ' +
                                'enhanced security measures including multi-factor authentication, regular security ' +
                                'training, and compliance with data classification policies.';
            }
            
            // Add region-specific data residency clauses
            if (region == 'EU') {
                enhancedClause += '\n\nData Residency: All personal data will be processed and stored within ' +
                                'European Union boundaries unless explicit consent is provided for cross-border transfers ' +
                                'under approved mechanisms (SCCs, Adequacy Decisions, or Binding Corporate Rules).';
            }
            
            System.debug('✓ Clause enhanced with AI improvements');
            return enhancedClause;
            
        } catch (Exception e) {
            System.debug('⚠ AI enhancement failed, returning base clause: ' + e.getMessage());
            return baseClause;
        }
    }
    
    /**
     * Generate multiple clause variations for A/B testing
     */
     
    // public static List<String> generateClauseVariations(String region, String role, String contractType, Integer variationCount) {
    //     List<String> variations = new List<String>();
    //     String baseClause = generateClause(region, role, contractType);
        
    //     for (Integer i = 0; i < variationCount; i++) {
    //         variations.add(generateClauseVariation(baseClause, i));
    //     }
        
    //     return variations;
    // }
    @AuraEnabled
    public static List<String> generateClauseVariations(String region, String role, String contractType, Integer variationCount) {
        List<String> variations = new List<String>();
        
        try {
            if (variationCount == null || variationCount <= 0) {
                variationCount = 3; // Default to 3 variations
            }
            
            // Generate base clause
            String baseClause = generateClause(region, role, contractType);
            variations.add(baseClause);
            
            // Generate variations with different tones and structures
            for (Integer i = 1; i < variationCount; i++) {
                String variation = generateClauseVariation(baseClause, i);
                variations.add(variation);
            }
            
            System.debug('✓ Generated ' + variations.size() + ' clause variations');
            
        } catch (Exception e) {
            System.debug('✗ Clause variation generation failed: ' + e.getMessage());
            throw new AuraHandledException('Failed to generate clause variations: ' + e.getMessage());
        }
        
        return variations;
    }
    
    /**
     * Generate a single variation of the base clause
     */ 
    // private static String generateClauseVariation(String baseClause, Integer variationType) {
    //     // Generate different variations for A/B testing
    //     switch on variationType {
    //         when 0 { return baseClause + ' [Formal variation]'; }
    //         when 1 { return baseClause + ' [Detailed variation]'; }
    //         when else { return baseClause + ' [Standard variation]'; }
    //     }
    // }
    
    @TestVisible
    private static String generateClauseVariation(String baseClause, Integer variationType) {
        String variation = baseClause;
        
        switch on variationType {
            when 1 {
                // Formal variation
                variation = variation.replace('you acknowledge', 'the party acknowledges');
                variation = variation.replace('You agree', 'The party agrees');
                variation += '\n\nFormal Addendum: This agreement constitutes the entire understanding between the parties.';
            }
            when 2 {
                // Detailed variation
                variation += '\n\nDetailed Provisions: This clause includes specific performance metrics, ' +
                           'compliance checkpoints, and regular review procedures to ensure ongoing adherence ' +
                           'to all stated obligations and requirements.';
            }
            when else {
                // Standard variation with additional context
                variation += '\n\nImplementation Note: All provisions of this clause take effect immediately ' +
                           'upon signature and remain binding throughout the duration of the agreement.';
            }
        }
        
        return variation;
    }
    
    /**
     * Get clause generation statistics
     */ 
    // public static Map<String, Object> getGenerationStatistics() {
    //     List<AuditTrail__c> auditRecords = [SELECT Action__c, AdditionalInfo__c, CreatedDate 
    //                                       FROM AuditTrail__c 
    //                                       WHERE Action__c = 'CLAUSE_GENERATED' 
    //                                       ORDER BY CreatedDate DESC LIMIT 1000];
        
    //     Map<String, Object> stats = new Map<String, Object>();
    //     stats.put('totalGenerations', auditRecords.size());
    //     stats.put('successRate', calculateSuccessRate(auditRecords));
        
    //     return stats;
    // }
      private static Decimal calculateSuccessRate(List<AuditTrail__c> records) {
        if (records.isEmpty()) return 0;
        
        Integer successCount = 0;
        for (AuditTrail__c record : records) {
            if (record.AdditionalInfo__c != null && record.AdditionalInfo__c.contains('SUCCESS')) {
                successCount++;
            }
        }
        
        return (Decimal.valueOf(successCount) / records.size()) * 100;
    }
    // @AuraEnabled
    // public static Map<String, Object> getGenerationStatistics() {
    //     Map<String, Object> stats = new Map<String, Object>();
        
    //         try {
    //             // Get audit trail statistics
    //             List<AggregateResult> auditStats = [
    //                 SELECT 
    //                     COUNT(Id) totalGenerations,
    //                     COUNT_DISTINCT(UserDetails__c) uniqueUsers
    //                 FROM AuditTrail__c 
    //                 WHERE Action__c = 'CLAUSE_GENERATED'
    //                 AND CreatedDate = LAST_N_DAYS:30
    //             ];
                
    //             if (!auditStats.isEmpty()) {
    //                 stats.put('totalGenerations', auditStats[0].get('totalGenerations'));
    //                 stats.put('uniqueUsers', auditStats[0].get('uniqueUsers'));
    //             }
                
    //             // Get success rate
    //             List<AggregateResult> successStats = [
    //                 SELECT 
    //                     Status__c,
    //                     COUNT(Id) count
    //                 FROM AuditTrail__c 
    //                 WHERE Action__c = 'CLAUSE_GENERATED'
    //                 AND CreatedDate = LAST_N_DAYS:30
    //                 GROUP BY Status__c
    //             ];
                
    //             Integer totalAttempts = 0;
    //             Integer successfulAttempts = 0;
                
    //             for (AggregateResult result : successStats) {
    //                 Integer count = (Integer)result.get('count');
    //                 totalAttempts += count;
                    
    //                 if ('SUCCESS'.equals(result.get('Status__c'))) {
    //                     successfulAttempts += count;
    //                 }
    //             }
                
    //             Decimal successRate = totalAttempts > 0 ? 
    //                 (Decimal.valueOf(successfulAttempts) / Decimal.valueOf(totalAttempts)) * 100 : 0;
                
    //             stats.put('successRate', successRate);
    //             stats.put('totalAttempts', totalAttempts);
    //             stats.put('lastUpdated', DateTime.now());
                
    //             System.debug('✓ Generation statistics calculated: ' + stats);
                
    //         } catch (Exception e) {
    //             System.debug('✗ Statistics calculation failed: ' + e.getMessage());
    //             stats.put('error', e.getMessage());
    //         }
            
    //         return stats;
    //     }
           @AuraEnabled
public static Map<String, Object> getGenerationStatistics() {
    Map<String, Object> stats = new Map<String, Object>();
    
    try {
        // ✅ Total generations (last 30 days)
        Integer totalGenerations = [
            SELECT COUNT()
            FROM AuditTrail__c 
            WHERE Action__c = 'CLAUSE_GENERATED'
            AND CreatedDate = LAST_N_DAYS:30
        ];
        stats.put('totalGenerations', totalGenerations);

        // ✅ Unique users (collect distinct values in Apex)
        Set<Id> uniqueUsers = new Set<Id>();
        for (AuditTrail__c audit : [
            SELECT UserDetails__c
            FROM AuditTrail__c
            WHERE Action__c = 'CLAUSE_GENERATED'
            AND CreatedDate = LAST_N_DAYS:30
            AND UserDetails__c != null
        ]) {
            uniqueUsers.add(audit.UserDetails__c);
        }
        stats.put('uniqueUsers', uniqueUsers.size());
        
        // ✅ Success rate stats
        List<AggregateResult> successStats = [
            SELECT 
                Status__c,
                COUNT(Id) total
            FROM AuditTrail__c 
            WHERE Action__c = 'CLAUSE_GENERATED'
            AND CreatedDate = LAST_N_DAYS:30
            GROUP BY Status__c
        ];
        
        Integer totalAttempts = 0;
        Integer successfulAttempts = 0;
        
        for (AggregateResult result : successStats) {
            Integer count = (Integer)result.get('total');
            totalAttempts += count;
            
            if ('SUCCESS'.equals(result.get('Status__c'))) {
                successfulAttempts += count;
            }
        }
        
        Decimal successRate = totalAttempts > 0 
            ? (Decimal.valueOf(successfulAttempts) / Decimal.valueOf(totalAttempts)) * 100 
            : 0;
        
        stats.put('successRate', successRate.setScale(2)); // round to 2 decimals
        stats.put('totalAttempts', totalAttempts);
        stats.put('lastUpdated', DateTime.now());
        
        System.debug('✓ Generation statistics calculated: ' + stats);
        
    } catch (Exception e) {
        System.debug('✗ Statistics calculation failed: ' + e.getMessage());
        stats.put('error', e.getMessage());
    }
    
    return stats;
}
 
    private static void logClauseGeneration(String region, String role, String contractType, String generatedClause) {
        ContractAudit__c audit = new ContractAudit__c(
            Timestamp__c   = System.now(),
            ClauseText__c  = generatedClause,
            UserId__c      = UserInfo.getUserId(),
            Action__c      = 'Clause Generated',
            Region__c      = region,
            Role__c        = role,
            ContractType__c= contractType
        );
        insert audit;
    }

        /**
         * Log clause generation activity
         */
    //      private static void logClauseGeneration(String region, String role, String contractType, String status, Integer clauseLength) {
    //     AuditTrail__c audit = new AuditTrail__c(
    //         Action__c = 'CLAUSE_GENERATED',
    //         Timestamp__c = DateTime.now(),
    //         UserDetails__c = UserInfo.getUserName(),
    //         AdditionalInfo__c = 'Region: ' + region + ', Role: ' + role + ', Type: ' + contractType + ', Status: ' + status + ', Length: ' + clauseLength
    //     );
    //     insert audit;
    // }
    
        @TestVisible
        private static void logClauseGeneration(String region, String role, String contractType, String status, Integer clauseLength) {
            try {
                AuditTrail__c auditLog = new AuditTrail__c(
                    Action__c = 'CLAUSE_GENERATED',
                    Status__c = status,
                    Timestamp__c = DateTime.now(),
                    UserDetails__c = UserInfo.getName() + ' (' + UserInfo.getUsername() + ')',
                    SystemInfo__c = 'Generated clause for ' + region + ' ' + role + ' ' + contractType,
                    AdditionalData__c = JSON.serialize(new Map<String, Object>{
                        'region' => region,
                        'role' => role,
                        'contractType' => contractType,
                        'clauseLength' => clauseLength,
                        'timestamp' => DateTime.now().format(),
                        'userId' => UserInfo.getUserId()
                    })
                );
                
                insert auditLog;
            } catch (Exception e) {
                System.debug('⚠ Could not log clause generation: ' + e.getMessage());
            }
        }
        
        /**
         * Custom exception for clause generation errors
         */
        public class ClauseGenerationException extends Exception {}
    }
