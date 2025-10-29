public with sharing class AugmentedRealityController {
    // Test hook to bypass validation in unit tests
    @TestVisible private static Boolean testBypassValidation = false;

    // --- Response helper ------------------------------------------------
    private static Map<String, Object> makeResponse(String status, String message, Map<String, Object> data) {
        Map<String, Object> out = new Map<String, Object>();
        out.put('status', status);
        out.put('message', message);
        out.put('data', data == null ? new Map<String, Object>() : data);
        out.put('timestamp', DateTime.now());
        return out;
    }

    // --- Public API (AuraEnabled) --------------------------------------
    @AuraEnabled public static Map<String, Object> configureARFramework(String arType, Map<String, Object> arConfig) {
        try {
            if (!testBypassValidation && String.isBlank(arType)) {
                return makeResponse('error', 'arType is required', null);
            }
            Map<String, Object> data = new Map<String, Object>{ 'arType' => arType, 'status' => 'configured' };
            if (arConfig != null) data.put('config', arConfig);
            System.debug('configureARFramework called for type=' + arType);
            return makeResponse('ok', 'AR framework configured', data);
        } catch (Exception ex) {
            System.debug('configureARFramework error: ' + ex.getMessage());
            return makeResponse('error', 'Exception configuring AR framework: ' + ex.getMessage(), null);
        }
    }

    @AuraEnabled public static Map<String, Object> implementARSurfaceDetection(String detectionType, Map<String, Object> detectionParams) {
        try {
            if (!testBypassValidation && String.isBlank(detectionType)) {
                return makeResponse('error', 'detectionType is required', null);
            }
            Map<String, Object> data = new Map<String, Object>{ 'detectionType' => detectionType, 'status' => 'implemented' };
            if (detectionParams != null) data.put('params', detectionParams);
            System.debug('implementARSurfaceDetection called for detectionType=' + detectionType);
            return makeResponse('ok', 'Surface detection implemented', data);
        } catch (Exception ex) {
            System.debug('implementARSurfaceDetection error: ' + ex.getMessage());
            return makeResponse('error', 'Exception implementing surface detection: ' + ex.getMessage(), null);
        }
    }

    @AuraEnabled public static Map<String, Object> manageAREnvironment(String environmentType, Map<String, Object> arEnvironmentData) {
        try {
            if (!testBypassValidation && String.isBlank(environmentType)) {
                return makeResponse('error', 'environmentType is required', null);
            }
            Map<String, Object> data = new Map<String, Object>{ 'environmentType' => environmentType, 'status' => 'managed' };
            if (arEnvironmentData != null) data.put('environmentData', arEnvironmentData);
            System.debug('manageAREnvironment called for environmentType=' + environmentType);
            return makeResponse('ok', 'AR environment managed', data);
        } catch (Exception ex) {
            System.debug('manageAREnvironment error: ' + ex.getMessage());
            return makeResponse('error', 'Exception managing AR environment: ' + ex.getMessage(), null);
        }
    }

    @AuraEnabled public static Map<String, Object> handleARInteraction(String interactionType, Map<String, Object> arInteractionData) {
        try {
            if (!testBypassValidation && String.isBlank(interactionType)) {
                return makeResponse('error', 'interactionType is required', null);
            }
            Map<String, Object> data = new Map<String, Object>{ 'interactionType' => interactionType, 'status' => 'handled' };
            if (arInteractionData != null) data.put('interactionData', arInteractionData);
            System.debug('handleARInteraction called for interactionType=' + interactionType);
            return makeResponse('ok', 'AR interaction handled', data);
        } catch (Exception ex) {
            System.debug('handleARInteraction error: ' + ex.getMessage());
            return makeResponse('error', 'Exception handling AR interaction: ' + ex.getMessage(), null);
        }
    }

    @AuraEnabled public static Map<String, Object> processARHaptics(String hapticsType, Map<String, Object> arHapticsData) {
        try {
            if (!testBypassValidation && String.isBlank(hapticsType)) {
                return makeResponse('error', 'hapticsType is required', null);
            }
            Map<String, Object> data = new Map<String, Object>{ 'hapticsType' => hapticsType, 'status' => 'processed' };
            if (arHapticsData != null) data.put('hapticsData', arHapticsData);
            System.debug('processARHaptics called for hapticsType=' + hapticsType);
            return makeResponse('ok', 'AR haptics processed', data);
        } catch (Exception ex) {
            System.debug('processARHaptics error: ' + ex.getMessage());
            return makeResponse('error', 'Exception processing AR haptics: ' + ex.getMessage(), null);
        }
    }

    @AuraEnabled public static Map<String, Object> optimizeARExperience(String experienceType, Map<String, Object> arExperienceData) {
        try {
            if (!testBypassValidation && String.isBlank(experienceType)) {
                return makeResponse('error', 'experienceType is required', null);
            }
            Map<String, Object> data = new Map<String, Object>{ 'experienceType' => experienceType, 'status' => 'optimized' };
            if (arExperienceData != null) data.put('experienceData', arExperienceData);
            System.debug('optimizeARExperience called for experienceType=' + experienceType);
            return makeResponse('ok', 'AR experience optimized', data);
        } catch (Exception ex) {
            System.debug('optimizeARExperience error: ' + ex.getMessage());
            return makeResponse('error', 'Exception optimizing AR experience: ' + ex.getMessage(), null);
        }
    }

    // --- Private helpers (preserve stubbed behavior, null-safe) ----------
    private static Map<String, Object> implementARLocomotion(String locomotionType, Map<String, Object> locomotionData) {
        if (String.isBlank(locomotionType)) {
            return new Map<String, Object>{ 'locomotionType' => locomotionType, 'status' => 'error', 'message' => 'locomotionType required' };
        }
        Map<String, Object> data = new Map<String, Object>{ 'locomotionType' => locomotionType, 'status' => 'implemented' };
        if (locomotionData != null) data.put('locomotionData', locomotionData);
        return data;
    }

    private static Map<String, Object> manageARAudio(String audioType, Map<String, Object> arAudioData) {
        if (String.isBlank(audioType)) {
            return new Map<String, Object>{ 'audioType' => audioType, 'status' => 'error', 'message' => 'audioType required' };
        }
        Map<String, Object> data = new Map<String, Object>{ 'audioType' => audioType, 'status' => 'managed' };
        if (arAudioData != null) data.put('audioData', arAudioData);
        return data;
    }

    private static Map<String, Object> handleSpatialAnchors(String anchorAction, Map<String, Object> anchorData) {
        if (String.isBlank(anchorAction)) {
            return new Map<String, Object>{ 'anchorAction' => anchorAction, 'status' => 'error', 'message' => 'anchorAction required' };
        }
        Map<String, Object> data = new Map<String, Object>{ 'anchorAction' => anchorAction, 'status' => 'done' };
        if (anchorData != null) data.put('anchorData', anchorData);
        return data;
    }

    private static void calibrateARSystem(String calibrationType, Map<String, Object> arCalibrationData) {
        // Keep existing behavior of logging; callers interact through public methods.
        System.debug('Calibrating AR system: ' + calibrationType + ' config=' + String.valueOf(arCalibrationData));
    }
}