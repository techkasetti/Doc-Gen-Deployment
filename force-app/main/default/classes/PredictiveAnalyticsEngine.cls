public with sharing class PredictiveAnalyticsEngine {

    // =====================================
    // Inner Class: Prediction Result
    // =====================================
    public class PredictionResult {
        @AuraEnabled public String  predictionId   { get; set; }
        @AuraEnabled public String  predictionType { get; set; }
        @AuraEnabled public Map<String, Object> predictions { get; set; }
        @AuraEnabled public Decimal confidence    { get; set; }
        @AuraEnabled public DateTime generatedAt  { get; set; }
        @AuraEnabled public String  status        { get; set; }

        public PredictionResult() {
            this.predictions = new Map<String, Object>();
            this.generatedAt = DateTime.now();
            this.status      = 'SUCCESS';
        }
    }

    // =====================================
    // 1. Signature Completion Rate Prediction
    // =====================================
    @AuraEnabled
    public static PredictionResult predictSignatureCompletionRates(Map<String, Object> documentData) {
        PredictionResult result = new PredictionResult();
        try {
            result.predictionId   = generatePredictionId();
            result.predictionType = 'SIGNATURE_COMPLETION';

            // Historical Data Analysis
            String documentType = (String) documentData.get('documentType');
            String region       = (String) documentData.get('region');

            // Guarded aggregate query (best-effort)
            Decimal baseCompletionRate = 75.0;
            try {
                List<AggregateResult> historicalData = Database.query(
                    'SELECT AVG(Completion_Rate__c) avgCompletionRate, COUNT(Id) totalDocuments ' +
                    'FROM Signature_Request__c ' +
                    'WHERE Document_Type__c = \'' + String.escapeSingleQuotes(String.valueOf(documentType)) + '\' ' +
                    'AND Region__c = \'' + String.escapeSingleQuotes(String.valueOf(region)) + '\' ' +
                    'AND CreatedDate >= ' + formatDateTimeForSOQL(DateTime.now().addDays(-90))
                );
                if (!historicalData.isEmpty() && historicalData[0].get('avgCompletionRate') != null) {
                    Object v = historicalData[0].get('avgCompletionRate');
                    baseCompletionRate = (v instanceof Decimal) ? (Decimal) v : Decimal.valueOf(String.valueOf(v));
                }
            } catch (Exception ex) {
                System.debug('Historical completion query skipped/failed: ' + ex.getMessage());
            }

            // Predictive Adjustments
            Decimal predictedRate = baseCompletionRate;

            Integer pageCount = (documentData.containsKey('pageCount') && documentData.get('pageCount') != null)
                ? Integer.valueOf(String.valueOf(documentData.get('pageCount'))) : 0;
            if (pageCount > 10)       predictedRate -= 5;
            else if (pageCount < 3)   predictedRate += 3;

            Boolean isUrgent = (documentData.containsKey('isUrgent') && documentData.get('isUrgent') != null)
                ? (Boolean) documentData.get('isUrgent') : false;
            if (isUrgent) predictedRate += 10;

            Integer signerCount = (documentData.containsKey('signerCount') && documentData.get('signerCount') != null)
                ? Integer.valueOf(String.valueOf(documentData.get('signerCount'))) : 0;
            if (signerCount > 5)       predictedRate -= (signerCount - 5) * 2;
            else if (signerCount == 1) predictedRate += 5;

            Integer currentMonth = DateTime.now().month();
            if (currentMonth == 12 || currentMonth == 1)          predictedRate -= 8;
            else if (currentMonth >= 9 && currentMonth <= 11)     predictedRate += 3;

            // Bound prediction
            predictedRate = Math.max(10, Math.min(95, predictedRate));

            // Populate predictions
            result.predictions.put('completionRate',         predictedRate);
            result.predictions.put('expectedCompletionDays', calculateExpectedDays(predictedRate));
            result.predictions.put('riskFactors',            identifyRiskFactors(documentData));
            result.confidence = calculatePredictionConfidence(documentData);

            // Store prediction (best-effort)
            try { storePrediction(result); } catch (Exception se) {
                System.debug('Storing prediction failed: ' + se.getMessage());
            }
            return result;
        } catch (Exception e) {
            result.status = 'ERROR';
            result.predictions.put('error', e.getMessage());
            return result;
        }
    }

    // =====================================
    // 2. Document Trend Forecasting
    // =====================================
    @AuraEnabled
    public static PredictionResult forecastDocumentTrends(String timeframe, String documentType) {
        PredictionResult result = new PredictionResult();
        try {
            result.predictionId   = generatePredictionId();
            result.predictionType = 'DOCUMENT_TRENDS';

            DateTime endDate   = DateTime.now();
            DateTime startDate;

            String tf = (timeframe == null) ? '' : timeframe.toLowerCase();
            if      (tf == 'weekly')    startDate = endDate.addDays(-7);
            else if (tf == 'monthly')   startDate = endDate.addDays(-30);
            else if (tf == 'quarterly') startDate = endDate.addDays(-90);
            else                        startDate = endDate.addDays(-30);

            // Historical document volumes (guarded)
            List<Decimal> volumes = new List<Decimal>();
            try {
                List<AggregateResult> volumeData = Database.query(
                    'SELECT DAY_ONLY(CreatedDate) createdDate, COUNT(Id) documentCount ' +
                    'FROM Document_Generation_Request__c ' +
                    'WHERE Document_Type__c = \'' + String.escapeSingleQuotes(String.valueOf(documentType)) + '\' ' +
                    'AND CreatedDate >= ' + formatDateTimeForSOQL(startDate) +
                    ' AND CreatedDate <= ' + formatDateTimeForSOQL(endDate) +
                    ' GROUP BY DAY_ONLY(CreatedDate) ORDER BY DAY_ONLY(CreatedDate)'
                );
                for (AggregateResult ar : volumeData) {
                    Object cnt = ar.get('documentCount');
                    Decimal dcnt = (cnt instanceof Decimal) ? (Decimal) cnt : Decimal.valueOf(String.valueOf(cnt));
                    volumes.add(dcnt);
                }
            } catch (Exception ex) {
                System.debug('Volume history query failed: ' + ex.getMessage());
            }

            // Analyze trends
            Map<String, Object> trendAnalysis = analyzeTrend(volumes);
            result.predictions.putAll(trendAnalysis);

            Integer forecastDays = getForecastDays(timeframe);
            List<Decimal> forecast = generateForecast(volumes, forecastDays);
            result.predictions.put('forecast', forecast);

            result.confidence = calculateTrendConfidence(volumes);
            return result;
        } catch (Exception e) {
            result.status = 'ERROR';
            result.predictions.put('error', e.getMessage());
            return result;
        }
    }

    // =====================================
    // 3. Compliance Risk Assessment
    // =====================================
    @AuraEnabled
    public static PredictionResult assessComplianceRisks(Id documentId, String jurisdiction) {
        PredictionResult result = new PredictionResult();
        try {
            result.predictionId   = generatePredictionId();
            result.predictionType = 'COMPLIANCE_RISK';

            // Document details (guarded)
            SObject document;
            try {
                document = Database.query(
                    'SELECT Id, Document_Type__c, Region__c, Content__c, Status__c ' +
                    'FROM Document_Generation_Request__c WHERE Id = \'' +
                    String.escapeSingleQuotes(String.valueOf(documentId)) + '\' LIMIT 1'
                );
            } catch (Exception ex) {
                result.status = 'ERROR';
                result.predictions.put('error', 'Document not found or inaccessible: ' + ex.getMessage());
                return result;
            }

            // Risk analysis
            Decimal riskScore = 0;
            List<String> riskFactors = new List<String>();

            // Jurisdiction rules (guarded)
            try {
                String docTypeVal = String.valueOf(document.get('Document_Type__c'));
                List<SObject> rules = Database.query(
                    'SELECT Rule_Name__c, Risk_Weight__c, Description__c ' +
                    'FROM Compliance_Rule__c ' +
                    'WHERE Jurisdiction__c = \'' + String.escapeSingleQuotes(String.valueOf(jurisdiction)) + '\' ' +
                    'AND Document_Type__c = \'' + String.escapeSingleQuotes(docTypeVal) + '\' ' +
                    'AND Is_Active__c = true'
                );
                for (SObject r : rules) {
                    Boolean noncompliant = assessRuleCompliance((Document_Generation_Request__c) document, (Compliance_Rule__c) r);
                    if (noncompliant) {
                        Object w = r.get('Risk_Weight__c');
                        Decimal weight = (w instanceof Decimal) ? (Decimal) w : (w != null ? Decimal.valueOf(String.valueOf(w)) : 0);
                        riskScore += weight;
                        riskFactors.add(String.valueOf(r.get('Description__c')));
                    }
                }
            } catch (Exception ex) {
                System.debug('Compliance rules fetch failed: ' + ex.getMessage());
            }

            // Historical violations (guarded)
            try {
                String docTypeVal = String.valueOf(document.get('Document_Type__c'));
                Integer pastViolations = Database.countQuery(
                    'SELECT COUNT() FROM Compliance_Violation__c ' +
                    'WHERE Document_Type__c = \'' + String.escapeSingleQuotes(docTypeVal) + '\' ' +
                    'AND Jurisdiction__c = \'' + String.escapeSingleQuotes(String.valueOf(jurisdiction)) + '\' ' +
                    'AND CreatedDate >= ' + formatDateTimeForSOQL(DateTime.now().addDays(-180))
                );
                if (pastViolations > 5) {
                    riskScore += 15;
                    riskFactors.add('High frequency of past violations for this document type');
                }
            } catch (Exception ex) {
                System.debug('Past violations count failed: ' + ex.getMessage());
            }

            // Risk level determination
            String riskLevel = 'LOW';
            if      (riskScore >= 50) riskLevel = 'CRITICAL';
            else if (riskScore >= 30) riskLevel = 'HIGH';
            else if (riskScore >= 15) riskLevel = 'MEDIUM';

            // Populate predictions
            result.predictions.put('riskScore',        riskScore);
            result.predictions.put('riskLevel',        riskLevel);
            result.predictions.put('riskFactors',      riskFactors);
            result.predictions.put('jurisdiction',     jurisdiction);
            result.predictions.put('recommendations',  generateComplianceRecommendations(riskLevel, riskFactors));

            Integer rulesCount = result.predictions.containsKey('rulesCount')
                ? (Integer) result.predictions.get('rulesCount') : 0;
            result.confidence = calculateComplianceConfidence(riskScore, rulesCount);

            return result;
        } catch (Exception e) {
            result.status = 'ERROR';
            result.predictions.put('error', e.getMessage());
            return result;
        }
    }

    // =====================================
    // 4. User Behavior Pattern Analysis
    // =====================================
    @AuraEnabled
    public static List<Map<String, Object>> analyzeUserBehaviorPatterns(String userId, String timeframe) {
        List<Map<String, Object>> patterns = new List<Map<String, Object>>();
        try {
            DateTime startDate = getStartDateForTimeframe(timeframe);

            // Activity patterns (guarded)
            try {
                List<AggregateResult> activityData = Database.query(
                    'SELECT HOUR_IN_DAY(CreatedDate) hour, COUNT(Id) activityCount ' +
                    'FROM Feature_Usage_Log__c WHERE User__c = \'' + String.escapeSingleQuotes(String.valueOf(userId)) + '\' ' +
                    'AND CreatedDate >= ' + formatDateTimeForSOQL(startDate) +
                    ' GROUP BY HOUR_IN_DAY(CreatedDate) ORDER BY COUNT(Id) DESC'
                );

                Map<String, Object> activityPattern = new Map<String, Object>();
                activityPattern.put('patternType', 'ACTIVITY_HOURS');
                activityPattern.put('data', activityData);
                patterns.add(activityPattern);
            } catch (Exception ex) {
                System.debug('Activity pattern query failed: ' + ex.getMessage());
            }

            // Feature usage (guarded)
            try {
                List<AggregateResult> featureUsage = Database.query(
                    'SELECT Feature_Name__c feature, COUNT(Id) usageCount, AVG(Processing_Time_Ms__c) avgProcessingTime ' +
                    'FROM Feature_Usage_Log__c WHERE User__c = \'' + String.escapeSingleQuotes(String.valueOf(userId)) + '\' ' +
                    'AND CreatedDate >= ' + formatDateTimeForSOQL(startDate) +
                    ' GROUP BY Feature_Name__c ORDER BY COUNT(Id) DESC'
                );

                Map<String, Object> featurePattern = new Map<String, Object>();
                featurePattern.put('patternType', 'FEATURE_USAGE');
                featurePattern.put('data', featureUsage);
                patterns.add(featurePattern);
            } catch (Exception ex) {
                System.debug('Feature usage query failed: ' + ex.getMessage());
            }

            // Anomalies
            List<Map<String, Object>> anomalies = detectUserAnomalies(userId, startDate);
            if (!anomalies.isEmpty()) {
                Map<String, Object> anomalyPattern = new Map<String, Object>();
                anomalyPattern.put('patternType', 'ANOMALIES');
                anomalyPattern.put('data', anomalies);
                patterns.add(anomalyPattern);
            }

            return patterns;
        } catch (Exception e) {
            Map<String, Object> errorPattern = new Map<String, Object>();
            errorPattern.put('patternType', 'ERROR');
            errorPattern.put('error', e.getMessage());
            patterns.add(errorPattern);
            return patterns;
        }
    }

    // =====================================
    // Helper Methods
    // =====================================
    private static Integer calculateExpectedDays(Decimal completionRate) {
        if (completionRate >= 85) return 1;
        if (completionRate >= 70) return 3;
        if (completionRate >= 50) return 7;
        return 14;
    }

    private static List<String> identifyRiskFactors(Map<String, Object> documentData) {
        List<String> riskFactors = new List<String>();

        Integer pageCount = (documentData.containsKey('pageCount') && documentData.get('pageCount') != null)
            ? Integer.valueOf(String.valueOf(documentData.get('pageCount'))) : 0;
        if (pageCount > 20) riskFactors.add('High page count may reduce completion rate');

        Integer signerCount = (documentData.containsKey('signerCount') && documentData.get('signerCount') != null)
            ? Integer.valueOf(String.valueOf(documentData.get('signerCount'))) : 0;
        if (signerCount > 3) riskFactors.add('Multiple signers increase coordination complexity');

        String language = (documentData.containsKey('language') && documentData.get('language') != null)
            ? String.valueOf(documentData.get('language')) : '';
        if (language != 'English') riskFactors.add('Non-English documents may have lower completion rates');

        return riskFactors;
    }

    private static Decimal calculatePredictionConfidence(Map<String, Object> documentData) {
        Decimal confidence = 80.0;
        Integer dataPoints = 0;
        if (documentData.containsKey('documentType')) dataPoints++;
        if (documentData.containsKey('region'))       dataPoints++;
        if (documentData.containsKey('pageCount'))    dataPoints++;
        if (documentData.containsKey('signerCount'))  dataPoints++;
        confidence += (dataPoints * 3);
        return Math.min(confidence, 95.0);
    }

    private static Map<String, Object> analyzeTrend(List<Decimal> volumes) {
        Map<String, Object> analysis = new Map<String, Object>();
        if (volumes.size() < 3) {
            analysis.put('trend', 'INSUFFICIENT_DATA');
            return analysis;
        }

        Decimal sum = 0;
        for (Integer i = 0; i < volumes.size(); i++) {
            sum += volumes[i] * (i + 1); // Weighted by recency
        }
        Decimal average       = sum / volumes.size();
        Decimal recentAverage = (volumes[volumes.size() - 1] + volumes[volumes.size() - 2]) / 2;

        if      (recentAverage > average * 1.1) analysis.put('trend', 'INCREASING');
        else if (recentAverage < average * 0.9) analysis.put('trend', 'DECREASING');
        else                                     analysis.put('trend', 'STABLE');

        analysis.put('currentVolume',  volumes[volumes.size() - 1]);
        analysis.put('averageVolume',  average);
        analysis.put('volatility',     calculateVolatility(volumes));
        return analysis;
    }

    private static List<Decimal> generateForecast(List<Decimal> historical, Integer forecastDays) {
        List<Decimal> forecast = new List<Decimal>();
        if (historical.isEmpty()) return forecast;

        Decimal movingAverage = 0;
        Integer window = Math.min(7, historical.size());
        for (Integer i = historical.size() - window; i < historical.size(); i++) {
            movingAverage += historical[i];
        }
        movingAverage = movingAverage / window;

        for (Integer i = 0; i < forecastDays; i++) {
            Double variation = (Math.random() - 0.5) * 0.2; // +/-10%
            Double f = movingAverage.doubleValue() * (1 + variation);
            forecast.add(Decimal.valueOf(f));
        }
        return forecast;
    }

    // Decimal arithmetic for variance; only use Math.sqrt on Double
    private static Decimal calculateVolatility(List<Decimal> values) {
        if (values.size() < 2) return 0;
        Decimal mean = 0;
        for (Decimal v : values) mean += v;
        mean = mean / values.size();

        Decimal varianceSum = 0;
        for (Decimal v : values) {
            Decimal diff = v - mean;
            varianceSum += diff * diff;
        }
        Decimal variance = varianceSum / values.size();
        Double  std      = Math.sqrt(variance.doubleValue());
        return Decimal.valueOf(std);
    }

    private static Boolean assessRuleCompliance(Document_Generation_Request__c document, Compliance_Rule__c rule) {
        String content = document.Content__c != null ? document.Content__c.toLowerCase() : '';
        if (rule.Rule_Name__c != null && rule.Rule_Name__c.contains('Privacy'))   return !content.contains('privacy policy');
        if (rule.Rule_Name__c != null && rule.Rule_Name__c.contains('Signature')) return !content.contains('electronic signature');
        if (rule.Rule_Name__c != null && rule.Rule_Name__c.contains('Terms'))     return !content.contains('terms and conditions');
        return false;
    }

    private static List<String> generateComplianceRecommendations(String riskLevel, List<String> riskFactors) {
        List<String> recommendations = new List<String>();
        if      (riskLevel == 'CRITICAL') {
            recommendations.add('Immediate legal review required before proceeding');
            recommendations.add('Consider engaging external compliance consultant');
            recommendations.add('Implement additional approval workflow');
        } else if (riskLevel == 'HIGH') {
            recommendations.add('Legal team review recommended');
            recommendations.add('Add compliance checkpoints in approval process');
            recommendations.add('Consider regional legal variations');
        } else if (riskLevel == 'MEDIUM') {
            recommendations.add('Review document against compliance checklist');
            recommendations.add('Consider automated compliance scanning');
        } else {
            recommendations.add('Standard compliance review sufficient');
        }
        return recommendations;
    }

    private static Decimal calculateComplianceConfidence(Decimal riskScore, Integer ruleCount) {
        Decimal confidence = 70.0;
        confidence += Math.min(ruleCount * 2, 20);
        if (riskScore < 10)      confidence += 10;
        else if (riskScore > 40) confidence -= 5;
        return Math.min(confidence, 95.0);
    }

    private static DateTime getStartDateForTimeframe(String timeframe) {
        DateTime now = DateTime.now();
        if (timeframe == null) return now.addDays(-7);

        switch on timeframe.toLowerCase() {
            when 'hour'  { return now.addHours(-1); }
            when 'day'   { return now.addDays(-1);  }
            when 'week'  { return now.addDays(-7);  }
            when 'month' { return now.addDays(-30); }
            when else    { return now.addDays(-7);  }
        }
    }

    private static List<Map<String, Object>> detectUserAnomalies(String userId, DateTime startDate) {
        List<Map<String, Object>> anomalies = new List<Map<String, Object>>();
        try {
            // Daily anomalies
            List<AggregateResult> dailyActivity = Database.query(
                'SELECT DAY_ONLY(CreatedDate) activityDate, COUNT(Id) activityCount ' +
                'FROM Feature_Usage_Log__c WHERE User__c = \'' + String.escapeSingleQuotes(String.valueOf(userId)) + '\' ' +
                'AND CreatedDate >= ' + formatDateTimeForSOQL(startDate) +
                ' GROUP BY DAY_ONLY(CreatedDate)'
            );

            Decimal totalActivity = 0;
            for (AggregateResult r : dailyActivity) {
                Object v = r.get('activityCount');
                Integer c = (v instanceof Decimal) ? ((Decimal) v).intValue() :
                            (v instanceof Integer) ? (Integer) v : Integer.valueOf(String.valueOf(v));
                totalActivity += c;
            }

            if (dailyActivity.size() > 0) {
                Decimal avgDaily  = totalActivity / dailyActivity.size();
                Decimal threshold = avgDaily * 3;

                for (AggregateResult r : dailyActivity) {
                    Object v = r.get('activityCount');
                    Integer dayActivity = (v instanceof Decimal) ? ((Decimal) v).intValue() :
                                          (v instanceof Integer) ? (Integer) v : Integer.valueOf(String.valueOf(v));

                    if (dayActivity > threshold) {
                        Map<String, Object> anomaly = new Map<String, Object>();
                        anomaly.put('type',          'HIGH_ACTIVITY');
                        anomaly.put('date',          r.get('activityDate'));
                        anomaly.put('activityCount', dayActivity);
                        anomaly.put('threshold',     threshold);
                        anomaly.put('severity',      (dayActivity > (threshold * 2)) ? 'HIGH' : 'MEDIUM');
                        anomalies.add(anomaly);
                    }
                }
            }

            // Off-hours activity
            List<AggregateResult> hourlyActivity = Database.query(
                'SELECT HOUR_IN_DAY(CreatedDate) hour, COUNT(Id) hourlyCount ' +
                'FROM Feature_Usage_Log__c WHERE User__c = \'' + String.escapeSingleQuotes(String.valueOf(userId)) + '\' ' +
                'AND CreatedDate >= ' + formatDateTimeForSOQL(startDate) +
                ' GROUP BY HOUR_IN_DAY(CreatedDate)'
            );

            for (AggregateResult r : hourlyActivity) {
                Integer hour  = Integer.valueOf(String.valueOf(r.get('hour')));
                Object  v     = r.get('hourlyCount');
                Integer count = (v instanceof Decimal) ? ((Decimal) v).intValue() :
                                (v instanceof Integer) ? (Integer) v : Integer.valueOf(String.valueOf(v));

                if ((hour < 9 || hour > 18) && count > 10) {
                    Map<String, Object> anomaly = new Map<String, Object>();
                    anomaly.put('type',          'OFF_HOURS_ACTIVITY');
                    anomaly.put('hour',          hour);
                    anomaly.put('activityCount', count);
                    anomaly.put('severity',      (hour < 6 || hour > 22) ? 'HIGH' : 'MEDIUM');
                    anomalies.add(anomaly);
                }
            }
        } catch (Exception e) {
            System.debug('Anomaly detection failed: ' + e.getMessage());
        }
        return anomalies;
    }

    private static String generatePredictionId() {
        return 'PRED' + String.valueOf(DateTime.now().getTime()) + '_' + String.valueOf(Math.round(Math.random() * 1000));
    }

    private static void storePrediction(PredictionResult result) {
        try {
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            if (!gd.containsKey('Prediction_Log__c')) return;

            SObject log = gd.get('Prediction_Log__c').newSObject();
            log.put('Prediction_ID__c',     result.predictionId);
            log.put('Prediction_Type__c',   result.predictionType);
            log.put('Prediction_Data__c',   JSON.serialize(result.predictions));
            log.put('Confidence_Score__c',  result.confidence);
            log.put('Status__c',            result.status);
            log.put('Generated_At__c',      result.generatedAt);
            log.put('User_Id__c',           UserInfo.getUserId());

            insert log;
        } catch (Exception e) {
            System.debug('Error storing prediction: ' + e.getMessage());
        }
    }

    private static Integer getForecastDays(String timeframe) {
        if (timeframe == null) return 14;
        switch on timeframe.toLowerCase() {
            when 'weekly'    { return 7;  }
            when 'monthly'   { return 30; }
            when 'quarterly' { return 90; }
            when else        { return 14; }
        }
    }

    private static Decimal calculateTrendConfidence(List<Decimal> volumes) {
        if (volumes.size() < 5) return 60.0;
        Decimal confidence = 75.0;
        confidence += Math.min(volumes.size(), 20);
        Decimal volatility = calculateVolatility(volumes);
        if      (volatility < 5)  confidence += 10;
        else if (volatility > 20) confidence -= 10;
        return Math.min(confidence, 95.0);
    }

    // Utility for formatting DateTime to inline SOQL literal
    private static String formatDateTimeForSOQL(DateTime dt) {
        if (dt == null) dt = DateTime.now();
        return '\'' + dt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') + '\'';
    }
}