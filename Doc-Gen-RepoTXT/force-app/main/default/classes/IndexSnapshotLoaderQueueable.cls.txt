public with sharing class IndexSnapshotLoaderQueueable implements Queueable {
    private String snapshotUrl;
    public IndexSnapshotLoaderQueueable(String snapshotUrl){ this.snapshotUrl = snapshotUrl; }
    public void execute(QueueableContext qc) {
        if (String.isBlank(snapshotUrl)) return;
        // stub: call out to loader; record Integration_Call__c if present
        if (Schema.getGlobalDescribe().containsKey('Integration_Call__c')) {
            try { insert new Integration_Call__c(Endpoint__c=snapshotUrl, StatusCode__c=200, Response__c='loaded'); } catch(Exception e) {}
        }
    }
}
