public with sharing class PredictiveAnalyticsEngine {
    
    // =====================================
    // Inner Class: Prediction Result
    // =====================================
    public class PredictionResult {
        @AuraEnabled public String predictionId { get; set; }
        @AuraEnabled public String predictionType { get; set; }
        @AuraEnabled public Map<String, Object> predictions { get; set; }
        @AuraEnabled public Decimal confidence { get; set; }
        @AuraEnabled public DateTime generatedAt { get; set; }
        @AuraEnabled public String status { get; set; }
        
        public PredictionResult() {
            this.predictions = new Map<String, Object>();
            this.generatedAt = DateTime.now();
            this.status = 'SUCCESS';
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
            
            List<AggregateResult> historicalData = [
                SELECT AVG(Completion_Rate__c) avgCompletionRate,
                       COUNT(Id) totalDocuments
                FROM Signature_Request__c
                WHERE Document_Type__c = :documentType
                  AND Region__c = :region
                  AND CreatedDate >= :DateTime.now().addDays(-90)
            ];
            
            Decimal baseCompletionRate = 75.0; // Default
            if (!historicalData.isEmpty() && historicalData[0].get('avgCompletionRate') != null) {
                baseCompletionRate = (Decimal) historicalData[0].get('avgCompletionRate');
            }
            
            // Predictive Adjustments
            Decimal predictedRate = baseCompletionRate;
            
            // Document complexity factor
            Integer pageCount = (Integer) documentData.get('pageCount');
            if (pageCount > 10) {
                predictedRate -= 5;
            } else if (pageCount < 3) {
                predictedRate += 3;
            }
            
            // Urgency factor
            Boolean isUrgent = (Boolean) documentData.get('isUrgent');
            if (isUrgent == true) {
                predictedRate += 10; // Urgent documents complete faster
            }
            
            // Signer count factor
            Integer signerCount = (Integer) documentData.get('signerCount');
            if (signerCount > 5) {
                predictedRate -= (signerCount - 5) * 2;
            } else if (signerCount == 1) {
                predictedRate += 5;
            }
            
            // Seasonal factor
            Integer currentMonth = DateTime.now().month();
            if (currentMonth == 12 || currentMonth == 1) {
                predictedRate -= 8; // Holiday impact
            } else if (currentMonth >= 9 && currentMonth <= 11) {
                predictedRate += 3; // End-of-year push
            }
            
            // Bound prediction
            predictedRate = Math.max(10, Math.min(95, predictedRate));
            
            // Populate predictions
            result.predictions.put('completionRate', predictedRate);
            result.predictions.put('expectedCompletionDays', calculateExpectedDays(predictedRate));
            result.predictions.put('riskFactors', identifyRiskFactors(documentData));
            result.confidence = calculatePredictionConfidence(documentData);
            
            // Store prediction log
            storePrediction(result);
            
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
            
            DateTime startDate;
            DateTime endDate = DateTime.now();
            
            switch on timeframe.toLowerCase() {
                when 'weekly'    { startDate = endDate.addDays(-7);  }
                when 'monthly'   { startDate = endDate.addDays(-30); }
                when 'quarterly' { startDate = endDate.addDays(-90); }
                when else        { startDate = endDate.addDays(-30); }
            }
            
            // Historical document volumes
            List<AggregateResult> volumeData = [
                SELECT DAY_ONLY(CreatedDate) createdDate,
                       COUNT(Id) documentCount
                FROM Document_Generation_Request__c
                WHERE Document_Type__c = :documentType
                  AND CreatedDate >= :startDate
                  AND CreatedDate <= :endDate
                GROUP BY DAY_ONLY(CreatedDate)
                ORDER BY DAY_ONLY(CreatedDate)
            ];
            
            // Extract volumes
            List<Decimal> volumes = new List<Decimal>();
            for (AggregateResult data : volumeData) {
                volumes.add((Decimal) data.get('documentCount'));
            }
            
            // Analyze trends
            Map<String, Object> trendAnalysis = analyzeTrend(volumes);
            result.predictions.putAll(trendAnalysis);
            
            // Forecast
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
    public static PredictionResult assessComplianceRisks(String documentId, String jurisdiction) {
        PredictionResult result = new PredictionResult();
        try {
            result.predictionId   = generatePredictionId();
            result.predictionType = 'COMPLIANCE_RISK';
            
            // Document details
            Document_Generation_Request__c document = [
                SELECT Id, Document_Type__c, Region__c, Content__c, Status__c
                FROM Document_Generation_Request__c
                WHERE Id = :documentId
                LIMIT 1
            ];
            
            // Risk analysis
            Decimal riskScore = 0;
            List<String> riskFactors = new List<String>();
            
            // Jurisdiction rules
            List<Compliance_Rule__c> rules = [
                SELECT Rule_Name__c, Risk_Weight__c, Description__c
                FROM Compliance_Rule__c
                WHERE Jurisdiction__c = :jurisdiction
                  AND Document_Type__c = :document.Document_Type__c
                  AND Is_Active__c = true
            ];
            
            for (Compliance_Rule__c rule : rules) {
                if (assessRuleCompliance(document, rule)) {
                    riskScore += rule.Risk_Weight__c;
                    riskFactors.add(rule.Description__c);
                }
            }
            
            // Historical violations
            Integer pastViolations = [
                SELECT COUNT()
                FROM Compliance_Violation__c
                WHERE Document_Type__c = :document.Document_Type__c
                  AND Jurisdiction__c = :jurisdiction
                  AND CreatedDate >= :DateTime.now().addDays(-180)
            ];
            
            if (pastViolations > 5) {
                riskScore += 15;
                riskFactors.add('High frequency of past violations for this document type');
            }
            
            // Risk level determination
            String riskLevel = 'LOW';
            if (riskScore >= 50) {
                riskLevel = 'CRITICAL';
            } else if (riskScore >= 30) {
                riskLevel = 'HIGH';
            } else if (riskScore >= 15) {
                riskLevel = 'MEDIUM';
            }
            
            // Populate predictions
            result.predictions.put('riskScore', riskScore);
            result.predictions.put('riskLevel', riskLevel);
            result.predictions.put('riskFactors', riskFactors);
            result.predictions.put('jurisdiction', jurisdiction);
            result.predictions.put('recommendations',
                                   generateComplianceRecommendations(riskLevel, riskFactors));
            
            result.confidence = calculateComplianceConfidence(riskScore, rules.size());
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
            
            // Activity patterns
            List<AggregateResult> activityData = [
                SELECT HOUR_IN_DAY(CreatedDate) hour, COUNT(Id) activityCount
                FROM Feature_Usage_Log__c
                WHERE User__c = :userId
                  AND CreatedDate >= :startDate
                GROUP BY HOUR_IN_DAY(CreatedDate)
                ORDER BY COUNT(Id) DESC
            ];
            
            Map<String, Object> activityPattern = new Map<String, Object>();
            activityPattern.put('patternType', 'ACTIVITY_HOURS');
            activityPattern.put('data', activityData);
            patterns.add(activityPattern);
            
            // Feature usage
            List<AggregateResult> featureUsage = [
                SELECT Feature_Name__c feature, COUNT(Id) usageCount,
                       AVG(Processing_Time_Ms__c) avgProcessingTime
                FROM Feature_Usage_Log__c
                WHERE User__c = :userId
                  AND CreatedDate >= :startDate
                GROUP BY Feature_Name__c
                ORDER BY COUNT(Id) DESC
            ];
            
            Map<String, Object> featurePattern = new Map<String, Object>();
            featurePattern.put('patternType', 'FEATURE_USAGE');
            featurePattern.put('data', featureUsage);
            patterns.add(featurePattern);
            
            // Anomaly detection
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
        
        Integer pageCount = (Integer) documentData.get('pageCount');
        if (pageCount > 20) {
            riskFactors.add('High page count may reduce completion rate');
        }
        
        Integer signerCount = (Integer) documentData.get('signerCount');
        if (signerCount > 3) {
            riskFactors.add('Multiple signers increase coordination complexity');
        }
        
        String language = (String) documentData.get('language');
        if (language != 'English') {
            riskFactors.add('Non-English documents may have lower completion rates');
        }
        
        return riskFactors;
    }
    
    private static Decimal calculatePredictionConfidence(Map<String, Object> documentData) {
        Decimal confidence = 80.0; // Base
        Integer dataPoints = 0;
        
        if (documentData.containsKey('documentType')) dataPoints++;
        if (documentData.containsKey('region')) dataPoints++;
        if (documentData.containsKey('pageCount')) dataPoints++;
        if (documentData.containsKey('signerCount')) dataPoints++;
        
        confidence += (dataPoints * 3); // +3% per datapoint
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
        
        if (recentAverage > average * 1.1) {
            analysis.put('trend', 'INCREASING');
        } else if (recentAverage < average * 0.9) {
            analysis.put('trend', 'DECREASING');
        } else {
            analysis.put('trend', 'STABLE');
        }
        
        analysis.put('currentVolume', volumes[volumes.size() - 1]);
        analysis.put('averageVolume', average);
        analysis.put('volatility', calculateVolatility(volumes));
        
        return analysis;
    }
    
    private static List<Decimal> generateForecast(List<Decimal> historical, Integer forecastDays) {
        List<Decimal> forecast = new List<Decimal>();
        if (historical.isEmpty()) return forecast;
        
        // Moving average
        Decimal movingAverage = 0;
        Integer window = Math.min(7, historical.size());
        
        for (Integer i = historical.size() - window; i < historical.size(); i++) {
            movingAverage += historical[i];
        }
        movingAverage = movingAverage / window;
        
        // Forecast with ±10% variation
        for (Integer i = 0; i < forecastDays; i++) {
            Decimal variation = (Math.random() - 0.5) * 0.2;
            forecast.add(movingAverage * (1 + variation));
        }
        
        return forecast;
    }
    
    private static Decimal calculateVolatility(List<Decimal> values) {
        if (values.size() < 2) return 0;
        
        Decimal mean = 0;
        for (Decimal v : values) {
            mean += v;
        }
        mean = mean / values.size();
        
        Decimal variance = 0;
        for (Decimal v : values) {
            variance += Math.pow(v - mean, 2);
        }
        variance = variance / values.size();
        
        return Math.sqrt(variance);
    }
    
    private static Boolean assessRuleCompliance(Document_Generation_Request__c document,
                                                Compliance_Rule__c rule) {
        String content = document.Content__c != null ? document.Content__c.toLowerCase() : '';
        
        if (rule.Rule_Name__c.contains('Privacy')) {
            return !content.contains('privacy policy');
        }
        if (rule.Rule_Name__c.contains('Signature')) {
            return !content.contains('electronic signature');
        }
        if (rule.Rule_Name__c.contains('Terms')) {
            return !content.contains('terms and conditions');
        }
        return false;
    }
    
    private static List<String> generateComplianceRecommendations(String riskLevel, List<String> riskFactors) {
        List<String> recommendations = new List<String>();
        
        switch on riskLevel {
            when 'CRITICAL' {
                recommendations.add('Immediate legal review required before proceeding');
                recommendations.add('Consider engaging external compliance consultant');
                recommendations.add('Implement additional approval workflow');
            }
            when 'HIGH' {
                recommendations.add('Legal team review recommended');
                recommendations.add('Add compliance checkpoints in approval process');
                recommendations.add('Consider regional legal variations');
            }
            when 'MEDIUM' {
                recommendations.add('Review document against compliance checklist');
                recommendations.add('Consider automated compliance scanning');
            }
            when else {
                recommendations.add('Standard compliance review sufficient');
            }
        }
        return recommendations;
    }
    
    private static Decimal calculateComplianceConfidence(Decimal riskScore, Integer ruleCount) {
        Decimal confidence = 70.0;
        confidence += Math.min(ruleCount * 2, 20);
        
        if (riskScore < 10) {
            confidence += 10;
        } else if (riskScore > 40) {
            confidence -= 5;
        }
        
        return Math.min(confidence, 95.0);
    }
    
    private static DateTime getStartDateForTimeframe(String timeframe) {
        DateTime now = DateTime.now();
        switch on timeframe.toLowerCase() {
            when 'hour'  { return now.addHours(-1); }
            when 'day'   { return now.addDays(-1); }
            when 'week'  { return now.addDays(-7); }
            when 'month' { return now.addDays(-30); }
            when else    { return now.addDays(-7); }
        }
    }
    
    private static List<Map<String, Object>> detectUserAnomalies(String userId, DateTime startDate) {
        List<Map<String, Object>> anomalies = new List<Map<String, Object>>();
        
        // Daily activity anomalies
        List<AggregateResult> dailyActivity = [
            SELECT DAY_ONLY(CreatedDate) activityDate, COUNT(Id) activityCount
            FROM Feature_Usage_Log__c
            WHERE User__c = :userId
              AND CreatedDate >= :startDate
            GROUP BY DAY_ONLY(CreatedDate)
        ];
        
        Decimal totalActivity = 0;
        for (AggregateResult r : dailyActivity) {
            totalActivity += (Integer) r.get('activityCount');
        }
        
        if (dailyActivity.size() > 0) {
            Decimal avgDaily = totalActivity / dailyActivity.size();
            Decimal threshold = avgDaily * 3;
            
            for (AggregateResult r : dailyActivity) {
                Integer dayActivity = (Integer) r.get('activityCount');
                if (dayActivity > threshold) {
                    Map<String, Object> anomaly = new Map<String, Object>();
                    anomaly.put('type', 'HIGH_ACTIVITY');
                    anomaly.put('date', r.get('activityDate'));
                    anomaly.put('activityCount', dayActivity);
                    anomaly.put('threshold', threshold);
                    anomaly.put('severity', dayActivity > threshold * 2 ? 'HIGH' : 'MEDIUM');
                    anomalies.add(anomaly);
                }
            }
        }
        
        // Hourly anomalies
        List<AggregateResult> hourlyActivity = [
            SELECT HOUR_IN_DAY(CreatedDate) hour, COUNT(Id) hourlyCount
            FROM Feature_Usage_Log__c
            WHERE User__c = :userId
              AND CreatedDate >= :startDate
            GROUP BY HOUR_IN_DAY(CreatedDate)
        ];
        
        for (AggregateResult r : hourlyActivity) {
            Integer hour  = (Integer) r.get('hour');
            Integer count = (Integer) r.get('hourlyCount');
            
            if ((hour < 9 || hour > 18) && count > 10) {
                Map<String, Object> anomaly = new Map<String, Object>();
                anomaly.put('type', 'OFF_HOURS_ACTIVITY');
                anomaly.put('hour', hour);
                anomaly.put('activityCount', count);
                anomaly.put('severity', (hour < 6 || hour > 22) ? 'HIGH' : 'MEDIUM');
                anomalies.add(anomaly);
            }
        }
        
        return anomalies;
    }
    
    private static String generatePredictionId() {
        return 'PRED_' +
               String.valueOf(DateTime.now().getTime()) + '_' +
               String.valueOf(Math.random() * 1000).substring(0, 3);
    }
    
    private static void storePrediction(PredictionResult result) {
        try {
            Prediction_Log__c log = new Prediction_Log__c(
                Prediction_ID__c    = result.predictionId,
                Prediction_Type__c  = result.predictionType,
                Prediction_Data__c  = JSON.serialize(result.predictions),
                Confidence_Score__c = result.confidence,
                Status__c           = result.status,
                Generated_At__c     = result.generatedAt,
                User_Id__c          = UserInfo.getUserId()
            );
            insert log;
        } catch (Exception e) {
            System.debug('Error storing prediction: ' + e.getMessage());
        }
    }
    
    private static Integer getForecastDays(String timeframe) {
        switch on timeframe.toLowerCase() {
            when 'weekly'    { return 7; }
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
        if (volatility < 5) {
            confidence += 10;
        } else if (volatility > 20) {
            confidence -= 10;
        }
        
        return Math.min(confidence, 95.0);
    }
}
