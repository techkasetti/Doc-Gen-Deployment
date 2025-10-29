public with sharing class DockerController {
    @AuraEnabled
    public static Map<String,Object> startContainer(String image, String tag) {
        Map<String,Object> out = new Map<String,Object>{'ok'=>false};
        if (String.isBlank(image)) return out;
        try {
            // Stub: orchestration call
            out.put('ok', true);
            out.put('image', image);
            out.put('tag', String.isBlank(tag)? 'latest' : tag);
            out.put('startedAt', String.valueOf(Datetime.now()));
            return out;
        } catch (Exception ex) {
            out.put('error', ex.getMessage());
            return out;
        }
    }
}