public with sharing class ContinuousIntegrationManager {
    @AuraEnabled
    public static Map<String,Object> triggerPipeline(String pipelineName, Map<String,Object> variables) {
        Map<String,Object> out = new Map<String,Object>{ 'pipeline' => pipelineName, 'status' => 'requested', 'requestedAt' => String.valueOf(Datetime.now()) };
        if (String.isBlank(pipelineName)) {
            out.put('status','error');
            out.put('error','missing_pipelineName');
            return out;
        }
        // TODO: call CI system via Named Credential
        out.put('status','triggered');
        out.put('runId','run-'+String.valueOf(Datetime.now().getTime()));
        return out;
    }
}