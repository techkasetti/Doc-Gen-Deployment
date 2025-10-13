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
}
