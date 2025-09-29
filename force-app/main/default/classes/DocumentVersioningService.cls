public class DocumentVersioningService {
    public class DocumentVersion {
        @AuraEnabled public String versionId;
        @AuraEnabled public String documentId;
        @AuraEnabled public Integer versionNumber;
        @AuraEnabled public String versionLabel;
        @AuraEnabled public String status;
        @AuraEnabled public String content;
        @AuraEnabled public Map<String, Object> metadata;
        @AuraEnabled public String createdBy;
        @AuraEnabled public DateTime createdDate;
        @AuraEnabled public String changeDescription;
        @AuraEnabled public List<String> changes;
    }

    public class VersionComparisonResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String sourceVersionId;
        @AuraEnabled public String targetVersionId;
        @AuraEnabled public List<Map<String, Object>> differences;
        @AuraEnabled public Map<String, Object> summary;
        @AuraEnabled public String errorMessage;
    }

    public static Id createVersion(Id documentId, String snapshotJson) {
        if (documentId == null || String.isBlank(snapshotJson)) return null;
        if (!Schema.getGlobalDescribe().containsKey('Document_Version__c')) return null;
        Document_Version__c v = new Document_Version__c(Document__c = documentId, Snapshot__c = snapshotJson, CreatedAt__c = Datetime.now());
        insert v;
        return v.Id;
    }

    @AuraEnabled(cacheable=false)
    public static DocumentVersion createDocumentVersion(String documentId, String content, String changeDescription) {
        DocumentVersion newVersion = new DocumentVersion();
        
        try {
            // Get current document
            DocumentLifecycleConfiguration__c document = [
                SELECT Id, Name, Document_Type__c, Content__c, Version__c
                FROM DocumentLifecycleConfiguration__c 
                WHERE Id = :documentId 
                LIMIT 1
            ];
            
            if (document == null) {
                return null;
            }
            
            // Get next version number
            Integer nextVersionNumber = getNextVersionNumber(documentId);
            
            // Create version record
            Document_Version__c version = new Document_Version__c(
                Document_Id__c = documentId,
                Version_Number__c = nextVersionNumber,
                Version_Label__c = 'v' + nextVersionNumber + '.0',
                Content__c = content,
                Status__c = 'Draft',
                Change_Description__c = changeDescription,
                Created_By__c = UserInfo.getUserId(),
                Created_Date__c = DateTime.now(),
                Is_Current__c = false
            );
            
            insert version;
            
            // Calculate differences from previous version
            List<String> changes = calculateChanges(document.Content__c, content);
            
            // Update version with changes
            version.Changes_Summary__c = String.join(changes, '; ');
            update version;
            
            // Create audit trail entry
            createVersionAuditTrail(version.Id, 'VERSION_CREATED', changeDescription);
            
            // Populate return object
            newVersion.versionId = version.Id;
            newVersion.documentId = documentId;
            newVersion.versionNumber = nextVersionNumber;
            newVersion.versionLabel = version.Version_Label__c;
            newVersion.status = version.Status__c;
            newVersion.content = content;
            newVersion.createdBy = UserInfo.getName();
            newVersion.createdDate = DateTime.now();
            newVersion.changeDescription = changeDescription;
            newVersion.changes = changes;
            
        } catch (Exception e) {
            System.debug('Failed to create document version: ' + e.getMessage());
            return null;
        }
        
        return newVersion;
    }

    @AuraEnabled(cacheable=false)
    public static Boolean publishDocumentVersion(String versionId) {
        try {
            Document_Version__c version = [
                SELECT Id, Document_Id__c, Version_Number__c, Status__c
                FROM Document_Version__c 
                WHERE Id = :versionId 
                LIMIT 1
            ];
            
            if (version == null || version.Status__c == 'Published') {
                return false;
            }
            
            // Mark all other versions as not current
            List<Document_Version__c> otherVersions = [
                SELECT Id FROM Document_Version__c 
                WHERE Document_Id__c = :version.Document_Id__c AND Id != :versionId
            ];
            
            for (Document_Version__c otherVersion : otherVersions) {
                otherVersion.Is_Current__c = false;
            }
            
            if (!otherVersions.isEmpty()) {
                update otherVersions;
            }
            
            // Update current version
            version.Status__c = 'Published';
            version.Is_Current__c = true;
            version.Published_Date__c = DateTime.now();
            version.Published_By__c = UserInfo.getUserId();
            update version;
            
            // Update main document record
            DocumentLifecycleConfiguration__c document = [
                SELECT Id FROM DocumentLifecycleConfiguration__c 
                WHERE Id = :version.Document_Id__c 
                LIMIT 1
            ];
            
            if (document != null) {
                document.Current_Version__c = version.Id;
                document.Version__c = version.Version_Number__c;
                document.Last_Modified_Date__c = DateTime.now();
                update document;
            }
            
            // Create audit trail
            createVersionAuditTrail(versionId, 'VERSION_PUBLISHED', 'Version published and set as current');
            
            return true;
            
        } catch (Exception e) {
            System.debug('Failed to publish document version: ' + e.getMessage());
            return false;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<DocumentVersion> getDocumentVersionHistory(String documentId) {
        List<DocumentVersion> versions = new List<DocumentVersion>();
        
        try {
            List<Document_Version__c> versionRecords = [
                SELECT Id, Version_Number__c, Version_Label__c, Status__c, Content__c,
                       Change_Description__c, Changes_Summary__c, Created_Date__c,
                       CreatedBy.Name, Published_Date__c, Is_Current__c
                FROM Document_Version__c 
                WHERE Document_Id__c = :documentId
                ORDER BY Version_Number__c DESC
            ];
            
            for (Document_Version__c versionRecord : versionRecords) {
                DocumentVersion version = new DocumentVersion();
                version.versionId = versionRecord.Id;
                version.documentId = documentId;
                version.versionNumber = Integer.valueOf(versionRecord.Version_Number__c);
                version.versionLabel = versionRecord.Version_Label__c;
                version.status = versionRecord.Status__c;
                version.content = versionRecord.Content__c;
                version.createdBy = versionRecord.CreatedBy.Name;
                version.createdDate = versionRecord.Created_Date__c;
                version.changeDescription = versionRecord.Change_Description__c;
                
                if (String.isNotBlank(versionRecord.Changes_Summary__c)) {
                    version.changes = versionRecord.Changes_Summary__c.split('; ');
                } else {
                    version.changes = new List<String>();
                }
                
                versions.add(version);
            }
            
        } catch (Exception e) {
            System.debug('Error retrieving document version history: ' + e.getMessage());
        }
        
        return versions;
    }

    @AuraEnabled(cacheable=false)
    public static VersionComparisonResult compareVersions(String sourceVersionId, String targetVersionId) {
        VersionComparisonResult result = new VersionComparisonResult();
        result.sourceVersionId = sourceVersionId;
        result.targetVersionId = targetVersionId;
        result.differences = new List<Map<String, Object>>();
        result.summary = new Map<String, Object>();
        
        try {
            Document_Version__c sourceVersion = [
                SELECT Id, Content__c, Version_Label__c
                FROM Document_Version__c 
                WHERE Id = :sourceVersionId 
                LIMIT 1
            ];
            
            Document_Version__c targetVersion = [
                SELECT Id, Content__c, Version_Label__c
                FROM Document_Version__c 
                WHERE Id = :targetVersionId 
                LIMIT 1
            ];
            
            if (sourceVersion == null || targetVersion == null) {
                result.success = false;
                result.errorMessage = 'One or both versions not found';
                return result;
            }
            
            // Perform content comparison
            List<String> sourceLines = sourceVersion.Content__c != null ? 
                sourceVersion.Content__c.split('\n') : new List<String>();
            List<String> targetLines = targetVersion.Content__c != null ? 
                targetVersion.Content__c.split('\n') : new List<String>();
            
            Integer additions = 0;
            Integer deletions = 0;
            Integer modifications = 0;
            
            // Simple line-by-line comparison
            Integer maxLines = Math.max(sourceLines.size(), targetLines.size());
            
            for (Integer i = 0; i < maxLines; i++) {
                String sourceLine = i < sourceLines.size() ? sourceLines[i] : '';
                String targetLine = i < targetLines.size() ? targetLines[i] : '';
                
                if (sourceLine != targetLine) {
                    Map<String, Object> difference = new Map<String, Object>();
                    difference.put('lineNumber', i + 1);
                    difference.put('sourceLine', sourceLine);
                    difference.put('targetLine', targetLine);
                    
                    if (String.isBlank(sourceLine)) {
                        difference.put('changeType', 'ADDITION');
                        additions++;
                    } else if (String.isBlank(targetLine)) {
                        difference.put('changeType', 'DELETION');
                        deletions++;
                    } else {
                        difference.put('changeType', 'MODIFICATION');
                        modifications++;
                    }
                    
                    result.differences.add(difference);
                }
            }
            
            // Populate summary
            result.summary.put('totalChanges', result.differences.size());
            result.summary.put('additions', additions);
            result.summary.put('deletions', deletions);
            result.summary.put('modifications', modifications);
            result.summary.put('sourceVersion', sourceVersion.Version_Label__c);
            result.summary.put('targetVersion', targetVersion.Version_Label__c);
            
            result.success = true;
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
        }
        
        return result;
    }

    @AuraEnabled(cacheable=false)
    public static Boolean rollbackToVersion(String versionId) {
        try {
            Document_Version__c version = [
                SELECT Id, Document_Id__c, Content__c, Version_Number__c
                FROM Document_Version__c 
                WHERE Id = :versionId 
                LIMIT 1
            ];
            
            if (version == null) {
                return false;
            }
            
            // Create new version with rolled back content
            Integer nextVersionNumber = getNextVersionNumber(version.Document_Id__c);
            
            Document_Version__c rollbackVersion = new Document_Version__c(
                Document_Id__c = version.Document_Id__c,
                Version_Number__c = nextVersionNumber,
                Version_Label__c = 'v' + nextVersionNumber + '.0 (Rollback)',
                Content__c = version.Content__c,
                Status__c = 'Published',
                Is_Current__c = true,
                Change_Description__c = 'Rolled back to version ' + version.Version_Number__c,
                Created_By__c = UserInfo.getUserId(),
                Created_Date__c = DateTime.now(),
                Published_Date__c = DateTime.now(),
                Published_By__c = UserInfo.getUserId()
            );
            
            insert rollbackVersion;
            
            // Mark other versions as not current
            List<Document_Version__c> otherVersions = [
                SELECT Id FROM Document_Version__c 
                WHERE Document_Id__c = :version.Document_Id__c AND Id != :rollbackVersion.Id
            ];
            
            for (Document_Version__c otherVersion : otherVersions) {
                otherVersion.Is_Current__c = false;
            }
            
            if (!otherVersions.isEmpty()) {
                update otherVersions;
            }
            
            // Update main document
            DocumentLifecycleConfiguration__c document = [
                SELECT Id FROM DocumentLifecycleConfiguration__c 
                WHERE Id = :version.Document_Id__c 
                LIMIT 1
            ];
            
            if (document != null) {
                document.Current_Version__c = rollbackVersion.Id;
                document.Version__c = nextVersionNumber;
                document.Content__c = version.Content__c;
                document.Last_Modified_Date__c = DateTime.now();
                update document;
            }
            
            // Create audit trail
            createVersionAuditTrail(rollbackVersion.Id, 'VERSION_ROLLBACK', 
                'Document rolled back to version ' + version.Version_Number__c);
            
            return true;
            
        } catch (Exception e) {
            System.debug('Failed to rollback to version: ' + e.getMessage());
            return false;
        }
    }

    @AuraEnabled(cacheable=false)
    public static Boolean deleteVersion(String versionId) {
        try {
            Document_Version__c version = [
                SELECT Id, Is_Current__c, Status__c
                FROM Document_Version__c 
                WHERE Id = :versionId 
                LIMIT 1
            ];
            
            if (version == null) {
                return false;
            }
            
            // Cannot delete current or published versions
            if (version.Is_Current__c || version.Status__c == 'Published') {
                return false;
            }
            
            // Create audit trail before deletion
            createVersionAuditTrail(versionId, 'VERSION_DELETED', 'Document version deleted');
            
            delete version;
            
            return true;
            
        } catch (Exception e) {
            System.debug('Failed to delete version: ' + e.getMessage());
            return false;
        }
    }

    private static Integer getNextVersionNumber(String documentId) {
        try {
            List<AggregateResult> maxVersionResult = [
                SELECT MAX(Version_Number__c) maxVersion
                FROM Document_Version__c 
                WHERE Document_Id__c = :documentId
            ];
            
            if (!maxVersionResult.isEmpty() && maxVersionResult[0].get('maxVersion') != null) {
                Decimal maxVersion = (Decimal)maxVersionResult[0].get('maxVersion');
                return Integer.valueOf(maxVersion) + 1;
            }
        } catch (Exception e) {
            System.debug('Error getting next version number: ' + e.getMessage());
        }
        
        return 1; // First version
    }

    private static List<String> calculateChanges(String oldContent, String newContent) {
        List<String> changes = new List<String>();
        
        try {
            if (String.isBlank(oldContent) && String.isNotBlank(newContent)) {
                changes.add('Document created');
                return changes;
            }
            
            if (String.isBlank(newContent) && String.isNotBlank(oldContent)) {
                changes.add('Document content removed');
                return changes;
            }
            
            if (oldContent == newContent) {
                changes.add('No content changes');
                return changes;
            }
            
            // Calculate basic metrics
            Integer oldLength = oldContent != null ? oldContent.length() : 0;
            Integer newLength = newContent != null ? newContent.length() : 0;
            Integer lengthDifference = newLength - oldLength;
            
            if (lengthDifference > 0) {
                changes.add(lengthDifference + ' characters added');
            } else if (lengthDifference < 0) {
                changes.add(Math.abs(lengthDifference) + ' characters removed');
            }
            
            // Count line changes
            List<String> oldLines = oldContent != null ? oldContent.split('\n') : new List<String>();
            List<String> newLines = newContent != null ? newContent.split('\n') : new List<String>();
            
            Integer linesAdded = 0;
            Integer linesRemoved = 0;
            Integer linesModified = 0;
            
            Integer maxLines = Math.max(oldLines.size(), newLines.size());
            
            for (Integer i = 0; i < maxLines; i++) {
                String oldLine = i < oldLines.size() ? oldLines[i] : '';
                String newLine = i < newLines.size() ? newLines[i] : '';
                
                if (String.isBlank(oldLine) && String.isNotBlank(newLine)) {
                    linesAdded++;
                } else if (String.isNotBlank(oldLine) && String.isBlank(newLine)) {
                    linesRemoved++;
                } else if (oldLine != newLine) {
                    linesModified++;
                }
            }
            
            if (linesAdded > 0) {
                changes.add(linesAdded + ' lines added');
            }
            if (linesRemoved > 0) {
                changes.add(linesRemoved + ' lines removed');
            }
            if (linesModified > 0) {
                changes.add(linesModified + ' lines modified');
            }
            
        } catch (Exception e) {
            changes.add('Unable to calculate changes: ' + e.getMessage());
        }
        
        return changes;
    }

    private static void createVersionAuditTrail(String versionId, String actionType, String description) {
        try {
            Audit_Trail__c auditRecord = new Audit_Trail__c(
                Document_Version_Id__c = versionId,
                Action_Type__c = actionType,
                Description__c = description,
                User_Id__c = UserInfo.getUserId(),
                Action_Date__c = DateTime.now(),
                IP_Address__c = 'System',
                User_Agent__c = 'Salesforce Internal'
            );
            insert auditRecord;
        } catch (Exception e) {
            System.debug('Failed to create version audit trail: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getVersionStatistics(String documentId) {
        Map<String, Object> statistics = new Map<String, Object>();
        
        try {
            // Basic version counts
            Integer totalVersions = [SELECT COUNT() FROM Document_Version__c WHERE Document_Id__c = :documentId];
            Integer publishedVersions = [SELECT COUNT() FROM Document_Version__c WHERE Document_Id__c = :documentId AND Status__c = 'Published'];
            Integer draftVersions = [SELECT COUNT() FROM Document_Version__c WHERE Document_Id__c = :documentId AND Status__c = 'Draft'];
            
            statistics.put('totalVersions', totalVersions);
            statistics.put('publishedVersions', publishedVersions);
            statistics.put('draftVersions', draftVersions);
            
            // Version activity over time
            DateTime thirtyDaysAgo = DateTime.now().addDays(-30);
            List<AggregateResult> recentActivity = [
                SELECT DAY_ONLY(Created_Date__c) day, COUNT(Id) versionCount
                FROM Document_Version__c 
                WHERE Document_Id__c = :documentId AND Created_Date__c >= :thirtyDaysAgo
                GROUP BY DAY_ONLY(Created_Date__c)
                ORDER BY DAY_ONLY(Created_Date__c)
            ];
            
            List<Map<String, Object>> activityData = new List<Map<String, Object>>();
            for (AggregateResult ar : recentActivity) {
                Date activityDate = (Date)ar.get('day');
                Integer versionCount = (Integer)ar.get('versionCount');
                
                activityData.add(new Map<String, Object>{
                    'date' => activityDate,
                    'count' => versionCount
                });
            }
            statistics.put('recentActivity', activityData);
            
            // Contributors
            List<AggregateResult> contributors = [
                SELECT CreatedBy.Name contributor, COUNT(Id) contributions
                FROM Document_Version__c 
                WHERE Document_Id__c = :documentId
                GROUP BY CreatedBy.Name
                ORDER BY COUNT(Id) DESC
                LIMIT 10
            ];
            
            List<Map<String, Object>> contributorData = new List<Map<String, Object>>();
            for (AggregateResult ar : contributors) {
                String contributor = (String)ar.get('contributor');
                Integer contributions = (Integer)ar.get('contributions');
                
                contributorData.add(new Map<String, Object>{
                    'name' => contributor,
                    'count' => contributions
                });
            }
            statistics.put('contributors', contributorData);
            
        } catch (Exception e) {
            statistics.put('error', e.getMessage());
        }
        
        return statistics;
    }
}