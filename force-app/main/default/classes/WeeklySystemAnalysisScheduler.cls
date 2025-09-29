public class WeeklySystemAnalysisScheduler implements Schedulable {
    public void execute(SchedulableContext ctx) {
        // Generate comprehensive weekly report
        try {
            Map<String, Object> weeklyReport = generateComprehensiveHealthReport(DateTime.now().addDays(-7));
            
            // Store report for historical tracking
            Weekly_System_Report__c report = new Weekly_System_Report__c(
                Report_Date__c = Date.today(),
                Overall_Health_Score__c = (Decimal)((Map<String, Object>)weeklyReport.get('executiveSummary')).get('overallHealthScore'),
                System_Status__c = (String)((Map<String, Object>)weeklyReport.get('executiveSummary')).get('systemStatus'),
                Report_Data__c = JSON.serialize(weeklyReport),
                Generated_By__c = 'SYSTEM_SCHEDULER'
            );
            insert report;

        } catch (Exception e) {
            System.debug('Weekly analysis failed: ' + e.getMessage());
        }
    }
}