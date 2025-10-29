public with sharing class RetentionService {

    /**
     * Evaluate retention candidates older than `days`.
     * Returns a Map with ok:boolean, candidates:Integer, samples:List<Map<String,Object>>.
     */
    @AuraEnabled
    public static Map<String, Object> evaluateRetention(Integer days) {
        Map<String, Object> out = new Map<String, Object>{
            'ok' => false, 
            'candidates' => 0, 
            'samples' => new List<Map<String,Object>>()
        };
        if (days == null || days <= 0) days = 30;

        try {
            Datetime cutoff = Datetime.now().addDays(-days);

            // Count ContentDocuments older than cutoff
            Integer candidateCount = 0;
            try {
                candidateCount = [SELECT COUNT() FROM ContentDocument WHERE CreatedDate <= :cutoff];
            } catch (Exception eCount) {
                System.debug('RetentionService.evaluateRetention: ContentDocument count failed: ' + eCount.getMessage());
            }

            out.put('ok', true);
            out.put('candidates', candidateCount);

            // Return up to 50 sample documents
            try {
                List<ContentDocument> docs = [
                    SELECT Id, Title, CreatedDate 
                    FROM ContentDocument 
                    WHERE CreatedDate <= :cutoff 
                    ORDER BY CreatedDate ASC 
                    LIMIT 50
                ];
                List<Map<String,Object>> samples = new List<Map<String,Object>>();
                for (ContentDocument cd : docs) {
                    Map<String,Object> m = new Map<String,Object>();
                    m.put('Id', cd.Id);
                    m.put('Title', cd.Title);
                    m.put('CreatedDate', cd.CreatedDate);
                    samples.add(m);
                }
                out.put('samples', samples);
            } catch (Exception eSamples) {
                System.debug('RetentionService.evaluateRetention: sample fetch failed: ' + eSamples.getMessage());
            }

            return out;
        } catch (Exception e) {
            out.put('ok', false);
            out.put('error', e.getMessage());
            return out;
        }
    }

    /**
     * Schedule a retention purge job by recording a Retention_Task__c (if that custom object exists).
     */
    @AuraEnabled
    public static Boolean scheduleRetentionPurge(Integer olderThanDays) {
        if (olderThanDays == null) return false;

        try {
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            if (!gd.containsKey('Retention_Task__c')) {
                System.debug('RetentionService.scheduleRetentionPurge: Retention_Task__c not present - skipping schedule.');
                return false;
            }

            SObject task = gd.get('Retention_Task__c').newSObject();
            try { task.put('TriggerDays__c', olderThanDays); } catch (Exception ok) {}
            try { task.put('ScheduledAt__c', Datetime.now()); } catch (Exception ok) {}
            insert task;
            return true;
        } catch (Exception e) {
            System.debug('RetentionService.scheduleRetentionPurge: failed: ' + e.getMessage());
            return false;
        }
    }

    /**
     * Perform a best-effort purge of documents older than `olderThanDays`.
     */
    @AuraEnabled
    public static Map<String, Object> performPurge(Integer olderThanDays) {
        Map<String, Object> out = new Map<String, Object>{
            'ok' => false, 
            'deletedCount' => 0, 
            'markedCount' => 0, 
            'errors' => new List<String>()
        };

        if (olderThanDays == null || olderThanDays < 0) olderThanDays = 365;
       
        Datetime cutoff = Datetime.now().addDays(-olderThanDays);

        try {
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

            // If Document__c exists and has Purged__c field
            if (gd.containsKey('Document__c')) {
                DescribeSObjectResult dr = gd.get('Document__c').getDescribe();
                Map<String, Schema.SObjectField> fields = dr.fields.getMap();
                if (fields.containsKey('Purged__c')) {
                    // Build dynamic SOQL string correctly
                    String query = 'SELECT Id FROM Document__c WHERE CreatedDate <= ' +
                        ':' + 'cutoff' + ' ORDER BY CreatedDate ASC LIMIT ' ;
                    
                    List<SObject> docs = Database.query(
                        'SELECT Id FROM Document__c WHERE CreatedDate <= ' + 
                        cutoff.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') + 
                        ' LIMIT ' 
                    );

                    Integer marked = 0;
                    List<SObject> updates = new List<SObject>();
                    for (SObject s : docs) {
                        s.put('Purged__c', true);
                        updates.add(s);
                    }
                    if (!updates.isEmpty()) {
                        try { 
                            update updates; 
                            marked = updates.size();
                        } catch (Exception eUpd) {
                            ((List<String>)out.get('errors')).add('Failed to mark Document__c records: ' + eUpd.getMessage());
                        }
                    }
                    out.put('ok', true);
                    out.put('markedCount', marked);
                    return out;
                }
            }

            // Fallback: purge ContentDocument
            List<ContentDocument> toDelete = [
                SELECT Id FROM ContentDocument WHERE CreatedDate <= :cutoff ORDER BY CreatedDate ASC LIMIT 1000
            ];
            Integer deleted = 0;
            if (!toDelete.isEmpty()) {
                try {
                    delete toDelete;
                    deleted = toDelete.size();
                } catch (Exception eDel) {
                    ((List<String>)out.get('errors')).add('ContentDocument delete failed: ' + eDel.getMessage());
                    // Optional fallback: archival records
                    try {
                        if (gd.containsKey('DocumentArchivalRecord__c')) {
                            List<SObject> archivalInserts = new List<SObject>();
                            for (ContentDocument cd : toDelete) {
                                SObject ar = gd.get('DocumentArchivalRecord__c').newSObject();
                                try { ar.put('Document_Id__c', cd.Id); } catch (Exception ok) {}
                                try { ar.put('Archive_Status__c', 'PENDING_PURGE'); } catch (Exception ok) {}
                                archivalInserts.add(ar);
                            }
                            if (!archivalInserts.isEmpty()) insert archivalInserts;
                        }
                    } catch (Exception eArch) {
                        ((List<String>)out.get('errors')).add('Archival fallback failed: ' + eArch.getMessage());
                    }
                }
            }

            out.put('ok', true);
            out.put('deletedCount', deleted);
            return out;

        } catch (Exception e) {
            out.put('ok', false);
            ((List<String>)out.get('errors')).add('performPurge exception: ' + e.getMessage());
            return out;
        }
    }

    /**
     * Simple health check for retention subsystem
     */
    @AuraEnabled
    public static Map<String, Object> healthCheck() {
        Map<String, Object> out = new Map<String, Object>{ 'ok' => true, 'message' => 'RetentionService reachable' };
        try {
            Integer cnt = 0;
            try { 
                cnt = [SELECT COUNT() FROM ContentDocument LIMIT 1]; 
            } catch (Exception e) { 
                out.put('ok', false); 
                out.put('message', 'ContentDocument query failed: ' + e.getMessage()); 
                return out; 
            }
            out.put('contentDocumentSampleCount', cnt);

            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            out.put('hasRetentionTask', gd.containsKey('Retention_Task__c'));
            out.put('hasDocumentCustom', gd.containsKey('Document__c'));
            return out;
        } catch (Exception e) {
            out.put('ok', false);
            out.put('message', e.getMessage());
            return out;
        }
    }
}