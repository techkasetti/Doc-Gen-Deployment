public class DocumentLifecycleStatus {
    public Id documentId;
    public DateTime assessmentTime;
    public Object retentionCompliance;
    public Object archivalStatus;
    public Object securityPosture;
    public List<String> upcomingActions = new List<String>();
    public Boolean requiresAction;
}