public class AnalyticsDataProcessorBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    private String processingType;
    private Date startDate;
    private Date endDate;
    private Integer recordsProcessed = 0;

    // ----------------------------------------
    // Constructor
    // ----------------------------------------
    public AnalyticsDataProcessorBatch(String processingType, Date startDate, Date endDate) {
        this.processingType = processingType;
        this.startDate = startDate;
        this.endDate = endDate;
    }

    // ----------------------------------------
    // Batchable Interface Methods
    // ----------------------------------------
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Choose query dynamically based on processing type
        if (processingType == 'Document') {
            return Database.getQueryLocator([
                SELECT Id, Name, CreatedDate FROM Document
                WHERE CreatedDate >= :startDate AND CreatedDate <= :endDate
            ]);
        } else if (processingType == 'Signature') {
            return Database.getQueryLocator([
                SELECT Id, Name, CreatedDate FROM Signature_Request__c
                WHERE CreatedDate >= :startDate AND CreatedDate <= :endDate
            ]);
        } else if (processingType == 'User') {
            return Database.getQueryLocator([
                SELECT Id, Name, CreatedDate FROM User
                WHERE CreatedDate >= :startDate AND CreatedDate <= :endDate
            ]);
        }
        return Database.getQueryLocator([SELECT Id FROM Analytics_Record__c WHERE Id = null]); // Empty fallback
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        if (scope.isEmpty()) return;

        if (processingType == 'Document') {
            processDocumentAnalytics((List<Document>) scope);
        } else if (processingType == 'Signature') {
            processSignatureAnalytics((List<Signature_Request__c>) scope);
        } else if (processingType == 'User') {
            processUserAnalytics((List<User>) scope);
        }

        recordsProcessed += scope.size();
    }

    public void finish(Database.BatchableContext bc) {
        sendProcessingNotification('Completed', recordsProcessed);
    }

    // ----------------------------------------
    // Data Processing Methods
    // ----------------------------------------
    private void processDocumentAnalytics(List<Document> documents) {
        aggregateMetrics(new List<sObject>(documents));
    }

    private void processSignatureAnalytics(List<Signature_Request__c> requests) {
        aggregateMetrics(new List<sObject>(requests));
    }

    private void processUserAnalytics(List<User> users) {
        aggregateMetrics(new List<sObject>(users));
    }

    private void aggregateMetrics(List<sObject> records) {
        Map<String, Object> processedData = calculateTrendMetrics(records);
        generateInsights(processedData);
    }

    private void generateInsights(Map<String, Object> processedData) {
        // Convert processed data into Analytics_Record__c entries
        List<Analytics_Record__c> analyticsRecords = new List<Analytics_Record__c>();
        for (String key : processedData.keySet()) {
            analyticsRecords.add(new Analytics_Record__c(
                Name = key,
                Metric_Value__c = String.valueOf(processedData.get(key))
            ));
        }
        updateAnalyticsRecords(analyticsRecords);
    }

    // ----------------------------------------
    // Helper Methods
    // ----------------------------------------
    private void updateAnalyticsRecords(List<Analytics_Record__c> records) {
        if (!records.isEmpty()) {
            upsert records;
        }
    }

    private void sendProcessingNotification(String status, Integer recordsProcessed) {
        System.debug('Analytics Batch ' + status + ' - Total Records Processed: ' + recordsProcessed);
    }

    private Map<String, Object> calculateTrendMetrics(List<sObject> data) {
        Map<String, Object> metrics = new Map<String, Object>();
        metrics.put('Total Records', data.size());
        metrics.put('Processing Date', DateTime.now());
        return metrics;
    }
}
