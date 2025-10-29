public class AIAnalysisResult {
    public Id documentId;
    public Datetime analysisStartTime;
    public Datetime analysisEndTime;
    public Long totalProcessingTime;
    public Boolean success;
    public String errorMessage;
    public String extractedText;
    public Integer extractedTextLength;
    public NLPResult nlpResult;
    public ClassificationResult classification;
    public ComplianceAnalysisResult complianceAnalysis;
    public Boolean complianceImpact;
    public RiskAssessmentResult riskAssessment;
    public VectorEmbeddingResult embeddings;
    public Decimal overallConfidenceScore;
    public Boolean requiresHumanReview;
    public String modelVersion;

    public AIAnalysisResult() {
        this.success = false;
        this.totalProcessingTime = 0;
        this.extractedText = null;
        this.extractedTextLength = 0;
        this.nlpResult = new NLPResult();
        this.classification = new ClassificationResult();
        this.complianceAnalysis = new ComplianceAnalysisResult();
        this.complianceImpact = false;
        this.riskAssessment = new RiskAssessmentResult();
        this.embeddings = new VectorEmbeddingResult();
        this.overallConfidenceScore = 0;
        this.requiresHumanReview = false;
        this.modelVersion = null;
    }

    // --- Lightweight placeholder types so this file compiles even when the org
    //     does not contain separate Apex types for these results. ---
    public class NLPResult {
        public Map<String, Object> tokensByType;
        public Map<String, Object> sentiment;
        public Map<String, Object> entities;
        public Map<String, Object> extras;

        public NLPResult() {
            tokensByType = new Map<String, Object>();
            sentiment = new Map<String, Object>();
            entities = new Map<String, Object>();
            extras = new Map<String, Object>();
        }
    }

    public class ClassificationResult {
        public String topLabel;
        public Decimal confidence;
        public List<String> tags;
        public Map<String, Decimal> tagConfidences;

        public ClassificationResult() {
            topLabel = null;
            confidence = 0;
            tags = new List<String>();
            tagConfidences = new Map<String, Decimal>();
        }
    }

    public class ComplianceAnalysisResult {
        public Boolean hasComplianceImplications;
        public Map<String, Object> frameworkScores;
        public List<String> findings;
        public List<String> recommendedActions;

        public ComplianceAnalysisResult() {
            hasComplianceImplications = false;
            frameworkScores = new Map<String, Object>();
            findings = new List<String>();
            recommendedActions = new List<String>();
        }
    }

    public class RiskAssessmentResult {
        public Decimal overallRiskScore;
        public Map<String, Decimal> categoryScores;
        public List<String> riskFactors;
        public List<String> mitigationRecommendations;

        public RiskAssessmentResult() {
            overallRiskScore = 0;
            categoryScores = new Map<String, Decimal>();
            riskFactors = new List<String>();
            mitigationRecommendations = new List<String>();
        }
    }

    public class VectorEmbeddingResult {
        public String modelName;
        public Integer dimensions;
        public List<Decimal> vectorData;
        public Decimal confidence;
        public String snowflakeId;
        public Map<String, Object> metadata;

        public VectorEmbeddingResult() {
            modelName = null;
            dimensions = 0;
            vectorData = new List<Decimal>();
            confidence = 0;
            snowflakeId = null;
            metadata = new Map<String, Object>();
        }
    }
}