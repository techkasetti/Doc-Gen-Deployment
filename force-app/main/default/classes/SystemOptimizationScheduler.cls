public class SystemOptimizationScheduler implements Schedulable {
    public void execute(SchedulableContext ctx) {
        SystemHealthMonitor monitor = new SystemHealthMonitor();
        Database.executeBatch(monitor, 200);
    }
}