public with sharing class AdvancedVersionControlManager {
    // ----------------------------
    // Public API (business logic preserved)
    // ----------------------------
    public static void createVersionControlObjects() {
        // Create records only if objects exist in this org (defensive)
        try {
            List<SObject> toInsert = new List<SObject>();

            if (Schema.getGlobalDescribe().containsKey('DocumentVersionTree__c')) {
                SObject versionTree = Schema.getGlobalDescribe().get('DocumentVersionTree__c').newSObject();
                versionTree.put('Document_Master_Id__c', 'parent_document_id');
                versionTree.put('Version_Number__c', '2.1.3');
                versionTree.put('Branch_Name__c', 'legal_review_branch');
                versionTree.put('Parent_Version_Id__c', 'parent_version_id');
                versionTree.put('Version_Type__c', 'MINOR_REVISION');
                versionTree.put('Created_By_User__c', UserInfo.getUserId());
                versionTree.put('Branch_Created_From__c', '2.1.0');
                versionTree.put('Merge_Status__c', 'PENDING_REVIEW');
                versionTree.put('Change_Summary__c', 'Updated GDPR compliance clauses');
                versionTree.put('Impact_Analysis__c', 'Low risk - clause refinement only');
                versionTree.put('Review_Status__c', 'IN_LEGAL_REVIEW');
                versionTree.put('Approval_Required__c', true);
                versionTree.put('Auto_Merge_Eligible__c', false);
                toInsert.add(versionTree);
            }

            if (Schema.getGlobalDescribe().containsKey('VersionComparisonResult__c')) {
                SObject comparison = Schema.getGlobalDescribe().get('VersionComparisonResult__c').newSObject();
                comparison.put('Source_Version__c', 'version_1_id');
                comparison.put('Target_Version__c', 'version_2_id');
                comparison.put('Comparison_Type__c', 'SEMANTIC_DIFF');
                comparison.put('Changes_Detected__c', 47);
                comparison.put('Critical_Changes__c', 3);
                comparison.put('Clause_Additions__c', 5);
                comparison.put('Clause_Deletions__c', 2);
                comparison.put('Clause_Modifications__c', 40);
                comparison.put('Compliance_Impact__c', 'MODERATE');
                comparison.put('AI_Change_Analysis__c', 'Added data retention clauses, modified jurisdiction language');
                comparison.put('Legal_Review_Required__c', true);
                comparison.put('Stakeholder_Notification_Sent__c', false);
                toInsert.add(comparison);
            }

            if (Schema.getGlobalDescribe().containsKey('DocumentBranch__c')) {
                SObject branch = Schema.getGlobalDescribe().get('DocumentBranch__c').newSObject();
                branch.put('Branch_Name__c', 'compliance_update_q4_2025');
                branch.put('Master_Document__c', 'master_doc_id');
                branch.put('Created_From_Version__c', '2.0.0');
                branch.put('Branch_Type__c', 'FEATURE_BRANCH');
                branch.put('Branch_Status__c', 'ACTIVE');
                branch.put('Owner__c', UserInfo.getUserId());
                branch.put('Collaborators__c', 'user1;user2;user3');
                branch.put('Protected_Branch__c', false);
                branch.put('Auto_Merge_Rules__c', 'REQUIRE_APPROVAL;RUN_COMPLIANCE_CHECK;NOTIFY_STAKEHOLDERS');
                branch.put('Branch_Description__c', 'Q4 2025 compliance updates for GDPR and CCPA');
                branch.put('Merge_Target__c', 'main');
                branch.put('Last_Activity__c', Datetime.now());
                toInsert.add(branch);
            }

            if (!toInsert.isEmpty()) {
                insert toInsert;
            }
        } catch (Exception e) {
            // Preserve original behavior: fail-safe logging
            System.debug('createVersionControlObjects error: ' + e.getMessage());
        }
    }

    public static void resolveVersionConflicts(String sourceVersionId, String targetVersionId) {
        // Attempt to find VersionConflict__c records only if that object exists
        if (!Schema.getGlobalDescribe().containsKey('VersionConflict__c')) {
            // Nothing to do if the org doesn't have version conflict records
            return;
        }

        List<SObject> conflicts = new List<SObject>();
        try {
            String q = 'SELECT Id, Conflict_Type__c, Priority__c, AI_Suggested_Resolution__c, Resolution_Strategy__c, Resolution_Status__c FROM VersionConflict__c WHERE Source_Version__c = :sourceVersionId AND Target_Version__c = :targetVersionId';
            conflicts = Database.query(q);
        } catch (Exception e) {
            System.debug('Failed to query VersionConflict__c: ' + e.getMessage());
            return;
        }

        if (conflicts.isEmpty()) return;

        // Update each conflict record defensively (use get/put)
        for (SObject conflict : conflicts) {
            try {
                String conflictType = String.valueOf(conflict.get('Conflict_Type__c'));
                if (String.valueOf(conflictType) == 'FORMATTING_ONLY') {
                    conflict.put('Resolution_Strategy__c', 'AUTO_ACCEPT_TARGET');
                    conflict.put('Resolution_Status__c', 'AUTO_RESOLVED');
                } else if (String.valueOf(conflictType) == 'CONTENT_OVERLAP') {
                    String aiSuggestion = generateAISuggestedResolution(conflict);
                    conflict.put('AI_Suggested_Resolution__c', aiSuggestion);
                    conflict.put('Resolution_Status__c', 'PENDING_HUMAN_REVIEW');
                } else if (String.valueOf(conflictType) == 'LEGAL_CLAUSE_CONFLICT') {
                    conflict.put('Resolution_Status__c', 'REQUIRES_LEGAL_REVIEW');
                    conflict.put('Priority__c', 'CRITICAL');
                    // Notify legal team (defensive call)
                    sendLegalTeamNotification(conflict);
                }
            } catch (Exception ex) {
                System.debug('Error processing conflict ' + String.valueOf(conflict.get('Id')) + ': ' + ex.getMessage());
            }
        }

        // Persist updates
        try {
            update conflicts;
        } catch (Exception e) {
            System.debug('Failed to update conflict records: ' + e.getMessage());
        }
    }

    public static void performIntelligentRollback(String documentId, String targetVersionId) {
        // Create rollback analysis record only if object exists
        try {
            if (Schema.getGlobalDescribe().containsKey('RollbackImpactAnalysis__c')) {
                SObject analysis = Schema.getGlobalDescribe().get('RollbackImpactAnalysis__c').newSObject();
                analysis.put('Document__c', documentId);
                analysis.put('Target_Version__c', targetVersionId);
                analysis.put('Current_Version__c', getCurrentVersion(documentId));
                analysis.put('Impact_Level__c', calculateRollbackImpact(documentId, targetVersionId));
                analysis.put('Affected_Clauses__c', getAffectedClauses(documentId, targetVersionId));
                analysis.put('Compliance_Risk__c', 'LOW');
                analysis.put('Stakeholder_Notification_Required__c', true);
                analysis.put('Rollback_Reason__c', 'Critical compliance issue identified');
                analysis.put('Approved_By__c', UserInfo.getUserId());
                analysis.put('Rollback_Timestamp__c', Datetime.now());
                insert analysis;

                // Execute rollback with audit trail (attempt blockchain audit if helper exists)
                String analysisId = String.valueOf(analysis.get('Id'));
                executeVersionRollback(documentId, targetVersionId, analysisId);
            } else {
                // If the custom object doesn't exist, still attempt rollback audit action()
                executeVersionRollback(documentId, targetVersionId, null);
            }
        } catch (Exception e) {
            System.debug('performIntelligentRollback error: ' + e.getMessage());
        }
    }

    // ----------------------------
    // Helper methods (defensive)
    // ----------------------------
    private static String generateAISuggestedResolution(SObject conflict) {
        // Preserve original hint; could be replaced with an LLM call.
        try {
            return 'AI analysis suggests merging both clauses with conditional logic based on jurisdiction';
        } catch (Exception e) {
            return 'AI suggestion unavailable';
        }
    }

    private static void sendLegalTeamNotification(SObject conflict) {
        // Non-fatal, best-effort notification placeholder
        try {
            // If EmailNotificationService exists, we could call it here; otherwise log.
            System.debug('Legal team notification requested for conflict: ' + String.valueOf(conflict.get('Id')));
        } catch (Exception e) {
            System.debug('sendLegalTeamNotification error: ' + e.getMessage());
        }
    }

    private static String getCurrentVersion(String documentId) {
        try {
            if (!Schema.getGlobalDescribe().containsKey('DocumentVersionTree__c')) return null;
            List<SObject> rows = Database.query('SELECT Version_Number__c FROM DocumentVersionTree__c WHERE Document_Master_Id__c = :documentId ORDER BY CreatedDate DESC LIMIT 1');
            if (!rows.isEmpty()) return String.valueOf(rows[0].get('Version_Number__c'));
        } catch (Exception e) {
            System.debug('getCurrentVersion error: ' + e.getMessage());
        }
        return null;
    }

    private static String calculateRollbackImpact(String documentId, String targetVersionId) {
        // Placeholder for AI-driven calculation (keeps original intent)
        return 'MEDIUM';
    }

    private static String getAffectedClauses(String documentId, String targetVersionId) {
        return 'Data Processing Agreement Section 4.2, Liability Limitations Section 7.1';
    }

    private static void executeVersionRollback(String documentId, String targetVersionId, String analysisId) {
        try {
            // Attempt blockchain audit if manager exists; otherwise log
            if (Type.forName('BlockchainAuditManager') != null) {
                // If BlockchainAuditManager.createImmutableAuditRecord exists in your org, uncomment and use it.
                // BlockchainAuditManager.createImmutableAuditRecord(analysisId, 'VERSION_ROLLBACK_EXECUTED', 'Document rolled back from current version to ' + targetVersionId);
            } else {
                System.debug('Rollback audit (no BlockchainAuditManager) analysisId=' + analysisId + ' doc=' + documentId + ' target=' + targetVersionId);
            }
        } catch (Exception e) {
            // Best-effort logging only
            System.debug('executeVersionRollback error: ' + e.getMessage());
        }
    }
}