public class ConflictResolutionResult {
    public Id documentId;
    public DateTime resolutionStartTime;
    public DateTime resolutionEndTime;
    public Long totalResolutionTime;
    public Boolean conflictsFound = false;
    public String resolution;
    public Id mergedVersionId;
    public Integer totalConflicts = 0;
    public Integer autoResolvedConflicts = 0;
    public Integer requiresReview = 0;
    public Boolean success = false;
    public String errorMessage;
    public List<SObject> resolvedConflicts = new List<SObject>();
}