public with sharing class DataScienceController {
    @AuraEnabled
    public static Map<String,Object> runExperiment(String experimentId, Map<String,Object> params) {
        Map<String,Object> out = new Map<String,Object>{ 'experimentId' => experimentId, 'status' => 'scheduled' };
        // TODO: enqueue experiment pipeline
        out.put('scheduledAt', String.valueOf(Datetime.now()));
        return out;
    }
}
