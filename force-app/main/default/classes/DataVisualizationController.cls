public with sharing class DataVisualizationController {
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getChart(String chartId, Map<String,Object> options) {
        Map<String,Object> out = new Map<String,Object>{ 'chartId' => chartId, 'data' => new List<Object>() };
        // TODO: fetch series data
        return out;
    }
}