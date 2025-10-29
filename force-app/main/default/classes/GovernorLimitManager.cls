public with sharing class GovernorLimitManager {

    // Test visibility so unit tests can verify behavior
    @TestVisible private static Map<String, Integer> SOFT_LIMITS = new Map<String, Integer>{
        'SOQL_QUERIES'  => 80,
        'DML_STATEMENTS'=> 150,
        'CPU_TIME_MS'   => 10000,
        'HEAP_SIZE_BYTES' => 100000000, // 100MB as a soft marker
        'CALLOUTS'      => 100
    };

    // Return a snapshot of current governor usage and limits
    @AuraEnabled public static Map<String, Object> getCurrentUsage() {
        Map<String, Object> usage = new Map<String, Object>();
        try {
            usage.put('soqlUsed', Limits.getQueries());
            usage.put('soqlLimit', Limits.getLimitQueries());
            usage.put('dmlUsed', Limits.getDMLStatements());
            usage.put('dmlLimit', Limits.getLimitDMLStatements());
            usage.put('cpuUsedMs', Limits.getCpuTime());
            usage.put('cpuLimitMs', Limits.getLimitCpuTime());
            usage.put('heapUsedBytes', Limits.getHeapSize());
            usage.put('heapLimitBytes', Limits.getLimitHeapSize());
            usage.put('calloutsUsed', Limits.getCallouts());
            usage.put('calloutsLimit', Limits.getLimitCallouts());
        } catch (Exception e) {
            // Ensure the method always returns a map even on unexpected errors
            usage.put('error', e.getMessage());
        }
        return usage;
    }

    // Return usage percentages for common limits (0-100)
    @AuraEnabled public static Map<String, Decimal> getUsagePercentages() {
        Map<String, Decimal> pct = new Map<String, Decimal>();
        try {
            Map<String, Object> u = getCurrentUsage();

            Integer soqlUsed    = u.get('soqlUsed')    != null ? (Integer)u.get('soqlUsed')    : 0;
            Integer soqlLimit   = u.get('soqlLimit')   != null ? (Integer)u.get('soqlLimit')   : null;
            pct.put('soqlPct', safePct(soqlUsed, soqlLimit));

            Integer dmlUsed     = u.get('dmlUsed')     != null ? (Integer)u.get('dmlUsed')     : 0;
            Integer dmlLimit    = u.get('dmlLimit')    != null ? (Integer)u.get('dmlLimit')    : null;
            pct.put('dmlPct', safePct(dmlUsed, dmlLimit));

            Integer cpuUsed     = u.get('cpuUsedMs')   != null ? (Integer)u.get('cpuUsedMs')   : 0;
            Integer cpuLimit    = u.get('cpuLimitMs')  != null ? (Integer)u.get('cpuLimitMs')  : null;
            pct.put('cpuPct', safePct(cpuUsed, cpuLimit));

            Integer heapUsed    = u.get('heapUsedBytes') != null ? (Integer)u.get('heapUsedBytes') : 0;
            Integer heapLimit   = u.get('heapLimitBytes')!= null ? (Integer)u.get('heapLimitBytes') : null;
            pct.put('heapPct', safePct(heapUsed, heapLimit));

            Integer calloutsUsed  = u.get('calloutsUsed') != null ? (Integer)u.get('calloutsUsed') : 0;
            Integer calloutsLimit = u.get('calloutsLimit')!= null ? (Integer)u.get('calloutsLimit') : null;
            pct.put('calloutsPct', safePct(calloutsUsed, calloutsLimit));

        } catch (Exception e) {
            // Provide a minimal safety response
            pct.put('error', Decimal.valueOf(0));
        }
        return pct;
    }

    // Check whether a specific limit is approaching soft limit threshold
    // limitKey must be one of the keys in SOFT_LIMITS, thresholdPct optional (default 90)
    @AuraEnabled public static Map<String, Object> isApproachingSoftLimit(String limitKey, Decimal thresholdPct) {
        Map<String, Object> out = new Map<String, Object>{ 'approaching' => false, 'reason' => null };
        try {
            if (String.isBlank(limitKey)) { out.put('reason', 'limitKey missing'); return out; }
            if (thresholdPct == null) thresholdPct = 90;

            Integer soft = SOFT_LIMITS.containsKey(limitKey) ? SOFT_LIMITS.get(limitKey) : null;
            if (soft == null) { out.put('reason', 'unknown limitKey: ' + limitKey); return out; }

            Map<String, Object> u = getCurrentUsage();
            Integer current = 0;
            if (limitKey == 'SOQL_QUERIES') current = u.get('soqlUsed')    != null ? (Integer)u.get('soqlUsed')    : 0;
            else if (limitKey == 'DML_STATEMENTS') current = u.get('dmlUsed') != null ? (Integer)u.get('dmlUsed') : 0;
            else if (limitKey == 'CPU_TIME_MS') current = u.get('cpuUsedMs')  != null ? (Integer)u.get('cpuUsedMs')  : 0;
            else if (limitKey == 'HEAP_SIZE_BYTES') current = u.get('heapUsedBytes') != null ? (Integer)u.get('heapUsedBytes') : 0;
            else if (limitKey == 'CALLOUTS') current = u.get('calloutsUsed') != null ? (Integer)u.get('calloutsUsed') : 0;
            else { out.put('reason', 'limitKey not supported for runtime check'); return out; }

            Decimal usedPct = (soft == 0)
                ? Decimal.valueOf(0)
                : ( Decimal.valueOf(current).divide(Decimal.valueOf(soft), 6, RoundingMode.HALF_UP) * 100 );

            Boolean approaching = usedPct >= thresholdPct;
            out.put('approaching', approaching);
            out.put('used', current);
            out.put('softLimit', soft);
            // Round to two decimals for readability
            out.put('usedPctOfSoft', usedPct.setScale(2, RoundingMode.HALF_UP));

        } catch (Exception e) {
            out.put('reason', 'error: ' + e.getMessage());
        }
        return out;
    }

    // Update in-transaction soft-limit values (not persisted across transactions)
    // Returns the new soft limit map snapshot
    @AuraEnabled public static Map<String, Integer> configureSoftLimit(String limitKey, Integer newValue) {
        Map<String, Integer> snapshot = new Map<String, Integer>();
        try {
            if (String.isBlank(limitKey)) throw new IllegalArgumentException('limitKey required');
            if (newValue == null || newValue < 0) throw new IllegalArgumentException('newValue must be non-negative');

            SOFT_LIMITS.put(limitKey, newValue);
            for (String k : SOFT_LIMITS.keySet()) snapshot.put(k, SOFT_LIMITS.get(k));
        } catch (Exception e) {
            // Return current snapshot and include error as -1 marker for visibility
            for (String k : SOFT_LIMITS.keySet()) snapshot.put(k, SOFT_LIMITS.get(k));
            snapshot.put('error', -1);
        }
        return snapshot;
    }

    // Utility: return a clean snapshot of configured soft limits
    @AuraEnabled public static Map<String, Integer> getSoftLimits() {
        Map<String, Integer> snapshot = new Map<String, Integer>();
        for (String k : SOFT_LIMITS.keySet()) snapshot.put(k, SOFT_LIMITS.get(k));
        return snapshot;
    }

    // Helper: a safe "can proceed" check for operations that may consume limits.
    // callers pass expected additional usage to validate (e.g., expectSoql=2)
    @AuraEnabled public static Map<String, Object> canProceedWithExpectedUsage(
        Integer expectSoql, Integer expectDml, Integer expectCallouts, Integer expectHeapBytes, Integer expectCpuMs
    ) {
        Map<String, Object> out = new Map<String, Object>{ 'ok' => true, 'reasons' => new List<String>() };
        try {
            Map<String, Object> u = getCurrentUsage();

            Integer soqlUsed    = u.get('soqlUsed')    != null ? (Integer)u.get('soqlUsed')    : 0;
            Integer soqlLimit   = u.get('soqlLimit')   != null ? (Integer)u.get('soqlLimit')   : null;
            Integer dmlUsed     = u.get('dmlUsed')     != null ? (Integer)u.get('dmlUsed')     : 0;
            Integer dmlLimit    = u.get('dmlLimit')    != null ? (Integer)u.get('dmlLimit')    : null;
            Integer calloutsUsed  = u.get('calloutsUsed') != null ? (Integer)u.get('calloutsUsed') : 0;
            Integer calloutsLimit = u.get('calloutsLimit')!= null ? (Integer)u.get('calloutsLimit') : null;
            Integer heapUsed    = u.get('heapUsedBytes') != null ? (Integer)u.get('heapUsedBytes') : 0;
            Integer heapLimit   = u.get('heapLimitBytes')!= null ? (Integer)u.get('heapLimitBytes') : null;
            Integer cpuUsed     = u.get('cpuUsedMs')   != null ? (Integer)u.get('cpuUsedMs')   : 0;
            Integer cpuLimit    = u.get('cpuLimitMs')  != null ? (Integer)u.get('cpuLimitMs')  : null;

            if (expectSoql == null) expectSoql = 0;
            if (expectDml == null) expectDml = 0;
            if (expectCallouts == null) expectCallouts = 0;
            if (expectHeapBytes == null) expectHeapBytes = 0;
            if (expectCpuMs == null) expectCpuMs = 0;

            if (soqlLimit != null && soqlUsed + expectSoql > soqlLimit) {
                out.put('ok', false);
                ((List<String>)out.get('reasons')).add('SOQL limit would be exceeded');
            }
            if (dmlLimit != null && dmlUsed + expectDml > dmlLimit) {
                out.put('ok', false);
                ((List<String>)out.get('reasons')).add('DML limit would be exceeded');
            }
            if (calloutsLimit != null && calloutsUsed + expectCallouts > calloutsLimit) {
                out.put('ok', false);
                ((List<String>)out.get('reasons')).add('Callouts limit would be exceeded');
            }
            if (heapLimit != null && heapUsed + expectHeapBytes > heapLimit) {
                out.put('ok', false);
                ((List<String>)out.get('reasons')).add('Heap size limit would be exceeded');
            }
            if (cpuLimit != null && cpuUsed + expectCpuMs > cpuLimit) {
                out.put('ok', false);
                ((List<String>)out.get('reasons')).add('CPU time limit would be exceeded');
            }

        } catch (Exception e) {
            out.put('ok', false);
            ((List<String>)out.get('reasons')).add('runtime error: ' + e.getMessage());
        }
        return out;
    }

    // ----- Private helpers -----
    // Safely compute percentage used (returns a Decimal 0..100 scaled to 2 decimals)
    private static Decimal safePct(Integer used, Integer maxLimit) {
        try {
            if (maxLimit == null || maxLimit == 0) return Decimal.valueOf(0);
            Decimal dUsed  = Decimal.valueOf( used != null ? used : 0 );
            Decimal dLimit = Decimal.valueOf( maxLimit );
            Decimal pct = dUsed.divide(dLimit, 6, RoundingMode.HALF_UP) * 100;
            return pct.setScale(2, RoundingMode.HALF_UP);
        } catch (Exception e) {
            return Decimal.valueOf(0);
        }
    }
}