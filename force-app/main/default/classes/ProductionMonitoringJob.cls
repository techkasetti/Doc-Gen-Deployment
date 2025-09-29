global class ProductionMonitoringJob implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Monitor system health every hour
        ProductionHealthMonitor.performHealthCheck();
        
        // Generate daily analytics report at 9 AM
        if (System.now().hour() == 9) {
            ProductionAnalytics.generateDailyReport();
        }

        // Weekly comprehensive report at 8 AM on Monday
        if (System.now().format('E', 'en_US') == 'Mon' && System.now().hour() == 8) {
            ProductionAnalytics.generateWeeklyReport();
        }

        // Monthly executive dashboard at 7 AM on first day of month
        if (System.now().day() == 1 && System.now().hour() == 7) {
            ProductionAnalytics.generateMonthlyExecutiveReport();
        }
    }
}
