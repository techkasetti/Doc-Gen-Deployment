public with sharing class AdminJobRetryWorker implements Queueable {
    private Id jobRunId;
    public AdminJobRetryWorker(Id jobRunId){ this.jobRunId = jobRunId; }
    public void execute(QueueableContext qc) {
        if (jobRunId == null) return;
        // stub: perform retry operations
    }
}