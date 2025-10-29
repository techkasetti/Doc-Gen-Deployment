public class ComplianceAnalysisResult {
public Integer overallScore;
public Map<String, Boolean> frameworkCompliance;
public List<String> violations;
public List<String> recommendations;
public Map<String, Integer> riskScores;
public String classification;
public DateTime analyzedDate;
public Map<String, Object> details;
public ComplianceAnalysisResult() {
this.overallScore = 0;
this.frameworkCompliance = new Map<String, Boolean>();
this.violations = new List<String>();
this.recommendations = new List<String>();
this.riskScores = new Map<String, Integer>();
this.classification = 'UNCLASSIFIED';
this.analyzedDate = DateTime.now();
this.details = new Map<String, Object>();
}
// Optional helper to add a violation and decrement score heuristically
public void addViolation(String v, Integer penaltyPoints) {
this.violations.add(v);
this.overallScore = Math.max(0, this.overallScore - (penaltyPoints == null ? 10 : penaltyPoints));
}
}