public class MonthlyArchivalScheduler implements Schedulable {
    public void execute(SchedulableContext ctx) {
        // Archive old data and generate monthly summary
        try {
            archiveOldSystemData();
            generateMonthlyComplianceReport();
        } catch (Exception e) {
            System.debug('Monthly archival failed: ' + e.getMessage());
        }
    }

    // ----------------------
    // Helper: archive old data
    // Defensive: checks for object existence before DML
    // ----------------------
    private void archiveOldSystemData() {
        try {
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            Date cutoff = Date.today().addMonths(-12); // archive items older than 12 months

            // 1) If a custom Document__c exists, mark Purged__c = true (best-effort)
            if (gd.containsKey('Document__c')) {
                try {
                    // Select a small batch to avoid hitting limits
                    List<SObject> docs = Database.query(
                        'SELECT Id, Purged__c FROM Document__c WHERE Purged__c = false AND CreatedDate <= '
                        + formatDateTimeForSOQL(DateTime.newInstance(cutoff.year(), cutoff.month(), cutoff.day(), 0, 0, 0))
                        + ' LIMIT 200'
                    );
                    if (!docs.isEmpty()) {
                        for (SObject s : docs) {
                            s.put('Purged__c', true);
                        }
                        update docs;
                        System.debug('Marked ' + docs.size() + ' Document__c records as Purged.');
                    } else {
                        System.debug('No Document__c rows to purge.');
                    }
                } catch (Exception e) {
                    System.debug('Document__c archival step failed: ' + e.getMessage());
                }
            } else {
                System.debug('Document__c absent - skipping Document archival.');
            }

            // 2) If ContentDocument-based archival record type exists, create archival entries (best-effort)
            if (gd.containsKey('DocumentArchivalRecord__c')) {
                try {
                    // Summarize archival activity for the month
                    SObject archiveSummary = gd.get('DocumentArchivalRecord__c').newSObject();
                    archiveSummary.put('Archive_Month__c', Date.today().toStartOfMonth());
                    archiveSummary.put('Archived_Count__c', 0);
                    archiveSummary.put('Notes__c', 'Monthly archival run executed by MonthlyArchivalScheduler');
                    try {
                        insert archiveSummary;
                        System.debug('Inserted DocumentArchivalRecord__c summary.');
                    } catch (Exception e) {
                        System.debug('Failed to insert DocumentArchivalRecord__c summary: ' + e.getMessage());
                    }
                } catch (Exception e) {
                    System.debug('DocumentArchivalRecord__c handling failed: ' + e.getMessage());
                }
            } else {
                System.debug('DocumentArchivalRecord__c absent - skipping archival record creation.');
            }

            // 3) Evidence bundles (if present) - mark archived older than cutoff
            if (gd.containsKey('Evidence_Bundle__c')) {
                try {
                    List<SObject> bundles = Database.query(
                        'SELECT Id, Archived__c FROM Evidence_Bundle__c WHERE Archived__c = false AND CreatedAt__c <= '
                        + formatDateTimeForSOQL(DateTime.newInstance(cutoff.year(), cutoff.month(), cutoff.day(), 0, 0, 0))
                        + ' LIMIT 200'
                    );
                    if (!bundles.isEmpty()) {
                        for (SObject b : bundles) b.put('Archived__c', true);
                        update bundles;
                        System.debug('Archived ' + bundles.size() + ' Evidence_Bundle__c rows.');
                    } else {
                        System.debug('No Evidence_Bundle__c rows to archive.');
                    }
                } catch (Exception e) {
                    System.debug('Evidence_Bundle__c archival step failed: ' + e.getMessage());
                }
            } else {
                System.debug('Evidence_Bundle__c absent - skipping evidence archival.');
            }

        } catch (Exception e) {
            System.debug('archiveOldSystemData top-level error: ' + e.getMessage());
        }
    }

    // ----------------------
    // Helper: monthly compliance summary
    // Creates a simple monthly summary record in a safe way
    // ----------------------
    private void generateMonthlyComplianceReport() {
        try {
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            Date firstOfMonth = Date.today().toStartOfMonth();
            DateTime startDt = DateTime.newInstance(firstOfMonth.year(), firstOfMonth.month(), firstOfMonth.day(), 0, 0, 0);
            DateTime endDt = DateTime.now();

            Integer openFindings = 0;
            Integer criticalFindings = 0;
            if (gd.containsKey('DocumentComplianceFinding__c')) {
                try {
                    openFindings = Database.countQuery(
                        'SELECT COUNT() FROM DocumentComplianceFinding__c WHERE CreatedDate >= ' + formatDateTimeForSOQL(startDt)
                        + ' AND CreatedDate <= ' + formatDateTimeForSOQL(endDt)
                    );
                    criticalFindings = Database.countQuery(
                        'SELECT COUNT() FROM DocumentComplianceFinding__c WHERE Severity__c = \'CRITICAL\' AND CreatedDate >= '
                        + formatDateTimeForSOQL(startDt) + ' AND CreatedDate <= ' + formatDateTimeForSOQL(endDt)
                    );
                } catch (Exception e) {
                    System.debug('Compliance finding counts failed: ' + e.getMessage());
                }
            } else {
                System.debug('DocumentComplianceFinding__c absent - skipping finding counts.');
            }

            // Create a monthly summary record if the custom object exists (fallback to SystemReport__c)
            if (gd.containsKey('Monthly_Archival_Report__c')) {
                try {
                    SObject report = gd.get('Monthly_Archival_Report__c').newSObject();
                    report.put('Report_Month__c', firstOfMonth);
                    report.put('Open_Findings__c', openFindings);
                    report.put('Critical_Findings__c', criticalFindings);
                    report.put('Generated_At__c', DateTime.now());
                    try {
                        insert report;
                        System.debug('Inserted Monthly_Archival_Report__c summary.');
                    } catch (Exception e) {
                        System.debug('Failed to insert Monthly_Archival_Report__c: ' + e.getMessage());
                    }
                } catch (Exception e) {
                    System.debug('Monthly_Archival_Report__c handling failed: ' + e.getMessage());
                }
            } else if (gd.containsKey('SystemReport__c')) {
                try {
                    SystemReport__c sr = new SystemReport__c();
                    sr.ReportType__c = 'MONTHLY_ARCHIVAL';
                    sr.ReportDate__c = firstOfMonth;
                    sr.ReportData__c = JSON.serialize(new Map<String, Object>{ 'openFindings' => openFindings, 'criticalFindings' => criticalFindings });
                    insert sr;
                    System.debug('Inserted SystemReport__c monthly archival summary.');
                } catch (Exception e) {
                    System.debug('Failed to insert SystemReport__c summary: ' + e.getMessage());
                }
            } else {
                // No custom report object available — log counts only
                System.debug('No Monthly_Archival_Report__c or SystemReport__c found. Open findings: ' + openFindings + ', Critical: ' + criticalFindings);
            }

        } catch (Exception e) {
            System.debug('generateMonthlyComplianceReport top-level error: ' + e.getMessage());
        }
    }

    // ----------------------
    // Small utility: format DateTime for inline SOQL literal
    // ----------------------
    private String formatDateTimeForSOQL(DateTime dt) {
        if (dt == null) dt = DateTime.now();
        return '\'' + dt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') + '\'';
    }
}