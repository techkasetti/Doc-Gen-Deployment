// Inner class for component health results
public class ComponentHealthResult {
    public String status;
    public Integer healthScore;
    public Integer responseTime;
    
    public ComponentHealthResult() {
        this.status = 'UNKNOWN';
        this.healthScore = 0;
        this.responseTime = 0;
    }
}
