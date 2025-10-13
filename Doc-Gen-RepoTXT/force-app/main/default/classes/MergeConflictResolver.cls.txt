public with sharing class MergeConflictResolver {
    public static String resolveConflicts(Map<String,String> left, Map<String,String> right) {
        if (left == null && right == null) return null;
        // simple deterministic merge: prefer left
        Map<String,String> merged = new Map<String,String>();
        if (right != null) merged.putAll(right);
        if (left != null) merged.putAll(left);
        return JSON.serialize(merged);
    }
}