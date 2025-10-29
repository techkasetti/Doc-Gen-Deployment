public with sharing class DocumentThumbnailQueueable implements Queueable {
    private Id documentId;
    public DocumentThumbnailQueueable(Id documentId) { this.documentId = documentId; }
    public void execute(QueueableContext qc) {
        if (documentId == null) return;
        DocumentThumbnailService.generateThumbnail(documentId);
    }
}