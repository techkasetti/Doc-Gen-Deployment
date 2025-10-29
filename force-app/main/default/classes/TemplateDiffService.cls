public with sharing class TemplateDiffService {
    public static Map<String,Object> diffVersions(Id v1, Id v2) {
        Map<String,Object> out = new Map<String,Object>{'ok'=>true,'diff'=>new List<String>()};
        return out;
    }
}