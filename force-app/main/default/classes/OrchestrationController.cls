public with sharing class OrchestrationController {
    /**
     * Retrieve orchestration status for a jobId (similar to getWorkflowStatus).
     */
    @AuraEnabled
    public static Map<String, Object> getOrchestrationStatus(String jobId) {
        Map<String, Object> out = new Map<String, Object>();
        out.put('jobId', jobId);
        out.put('status', 'UNKNOWN');

        if (String.isBlank(jobId)) {
            out.put('status', 'ERROR');
            out.put('message', 'missing_jobId');
            return out;
        }

        Integer h = Math.abs(jobId.hashCode());
        String status = (Math.mod(h, 2) == 0) ? 'COMPLETED' : 'RUNNING';
        out.put('status', status);
        out.put('checkedAt', String.valueOf(Datetime.now()));
        out.put('progressPercent', Math.mod(h, 101)); // 0..100
        return out;
    }

    /**
     * Start a workflow job (lightweight, no external dependencies).
     * Returns a small payload with a generated jobId and metadata.
     */
    @AuraEnabled
    public static Map<String, Object> startWorkflow(String workflowKey, Map<String, Object> payload) {
        Map<String, Object> out = new Map<String, Object>();
        out.put('ok', false);
        out.put('message', null);
        out.put('workflowKey', workflowKey);

        if (String.isBlank(workflowKey)) {
            out.put('message', 'missing_workflowKey');
            return out;
        }

        String jobId = generateJobId();
        out.put('ok', true);
        out.put('startedAt', String.valueOf(Datetime.now()));
        out.put('jobId', jobId);
        out.put('receivedPayloadSize', payload == null ? 0 : payload.size());
        return out;
    }

    /**
     * Retrieve a deterministic, lightweight status for a jobId.
     * This is intentionally simple so it compiles & runs in any org.
     */
    @AuraEnabled
    public static Map<String, Object> getWorkflowStatus(String jobId) {
        Map<String, Object> out = new Map<String, Object>();
        out.put('jobId', jobId);
        out.put('status', 'UNKNOWN');

        if (String.isBlank(jobId)) {
            out.put('status', 'ERROR');
            out.put('message', 'missing_jobId');
            return out;
        }

        // Deterministic status: derive an integer from the jobId hashcode
        Integer h = Math.abs(jobId.hashCode());
        String status = (Math.mod(h, 2) == 0) ? 'COMPLETED' : 'RUNNING';
        out.put('status', status);
        out.put('checkedAt', String.valueOf(Datetime.now()));
        out.put('progressPercent', Math.mod(h, 101)); // 0..100
        return out;
    }

    /**
     * Cancel a workflow job (best-effort, no external system calls).
     * Returns true when a non-empty jobId is provided.
     */
    @AuraEnabled
    public static Boolean cancelWorkflow(String jobId) {
        if (String.isBlank(jobId)) return false;
        // No external records to update in this generic implementation.
        return true;
    }

    // ----- Helpers -----

    private static String generateJobId() {
        // Uses timestamp to ensure uniqueness without relying on custom APIs
        Long t = Datetime.now().getTime();
        Long modVal = Math.abs(Math.mod(t, 100000));
        return 'job-' + String.valueOf(t) + '-' + String.valueOf(modVal);
    }
}