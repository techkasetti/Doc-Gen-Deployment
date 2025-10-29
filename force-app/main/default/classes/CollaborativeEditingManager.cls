public class CollaborativeEditingManager {
    
    // Real-time conflict detection and resolution
    public static void initializeCollaborativeSession(String documentId) {
        // Create collaborative session
        CollaborativeSession__c session = new CollaborativeSession__c(
            Document__c = documentId,
            Session_Status__c = 'ACTIVE',
            Session_Started__c = DateTime.now(),
            Maximum_Concurrent_Editors__c = 10,
            Conflict_Resolution_Mode__c = 'AI_ASSISTED', // AI_ASSISTED, MANUAL, AUTOMATIC
            Version_Control_Strategy__c = 'OPERATIONAL_TRANSFORM',
            Real_Time_Sync_Enabled__c = true,
            Auto_Save_Interval_Seconds__c = 30,
            Session_Owner__c = UserInfo.getUserId()
        );
        insert session;
        
        // Initialize operational transform state
        initializeOperationalTransform(session.Id);
    }
    
    private static void initializeOperationalTransform(String sessionId) {
        OperationalTransformState__c otState = new OperationalTransformState__c(
            Collaborative_Session__c = sessionId,
            Current_Revision__c = 1,
            Document_State_Hash__c = generateDocumentHash(sessionId),
            Operation_Queue_JSON__c = '[]',
            Transform_Algorithm__c = 'GOOGLE_WAVE_OT',
            State_Vector_JSON__c = '{"users":{},"operations":[]}',
            Conflict_Detection_Enabled__c = true,
            Auto_Merge_Simple_Conflicts__c = true,
            Lock_Granularity__c = 'PARAGRAPH_LEVEL', // CHARACTER, WORD, SENTENCE, PARAGRAPH, SECTION
            Max_Concurrent_Operations__c = 100,
            State_Synchronization_Interval__c = 5000 // milliseconds
        );
        insert otState;
    }

    // Real-time conflict detection as operations are applied
    public static void processEditingOperation(String sessionId, String userId, Map<String, Object> operation) {
        // Retrieve current operational transform state
        OperationalTransformState__c otState = [
            SELECT Id, Current_Revision__c, Document_State_Hash__c, Operation_Queue_JSON__c, 
                   State_Vector_JSON__c, Auto_Merge_Simple_Conflicts__c, Lock_Granularity__c
            FROM OperationalTransformState__c 
            WHERE Collaborative_Session__c = :sessionId 
            LIMIT 1
        ];

        // Create operation record
        EditingOperation__c editOp = new EditingOperation__c( );
            editOp.Collaborative_Session__c = sessionId;
            editOp.Operation_Type__c = (String)operation.get('type'); // INSERT, DELETE, RETAIN, FORMAT
            editOp.Operation_Position__c = (Integer)operation.get('position');
            editOp.Operation_Length__c = (Integer)operation.get('length');
            editOp.Operation_Content__c = (String)operation.get('content');
            editOp.User__c = userId;
            editOp.Client_Revision__c = (Integer)operation.get('clientRevision');
            editOp.Server_Revision__c = otState.Current_Revision__c;
            editOp.Operation_Timestamp__c = DateTime.now();
            editOp.Operation_Status__c = 'PENDING_TRANSFORM';
            editOp.Operation_JSON__c = JSON.serialize(operation);
            editOp.Conflict_Detected__c = false;
      

        // Detect potential conflicts
        List<EditingOperation__c> conflictingOps = detectConflicts(editOp, otState);
        
        if (!conflictingOps.isEmpty()) {
            editOp.Conflict_Detected__c = true;
            editOp.Operation_Status__c = 'CONFLICT_DETECTED';
            
            // Create conflict resolution records
            createConflictResolutionRecords(editOp, conflictingOps, otState);
        } else {
            // No conflicts, apply operation directly
            applyOperationDirectly(editOp, otState);
        }

        insert editOp;
    }

    // private static List<EditingOperation__c> detectConflicts(EditingOperation__c newOp, OperationalTransformState__c otState) {
    //     // Find overlapping operations from other users
    //     return [
    //         SELECT Id, Operation_Type__c, Operation_Position__c, Operation_Length__c, 
    //                User__c, Operation_Content__c, Operation_JSON__c
    //         FROM EditingOperation__c 
    //         WHERE Collaborative_Session__c = :newOp.Collaborative_Session__c
    //         AND User__c != :newOp.User__c
    //         AND Operation_Status__c IN ('PENDING_TRANSFORM', 'APPLIED')
    //         AND Server_Revision__c > (:newOp.Client_Revision__c - 10) // Check recent operations
    //         AND (
    //             (Operation_Position__c <= :newOp.Operation_Position__c 
    //              AND (Operation_Position__c + Operation_Length__c) > :newOp.Operation_Position__c)
    //             OR 
    //             (Operation_Position__c < (:newOp.Operation_Position__c + newOp.Operation_Length__c)
    //              AND Operation_Position__c >= :newOp.Operation_Position__c)
    //         )
    //         ORDER BY Operation_Timestamp__c DESC
    //     ];
    // }
    private static List<EditingOperation__c> detectConflicts(EditingOperation__c newOp, OperationalTransformState__c otState) {
        Integer minRevision = Integer.Valueof(newOp.Client_Revision__c - 10);
        Integer opStart = Integer.Valueof(newOp.Operation_Position__c);
        Integer opEnd = Integer.Valueof(newOp.Operation_Position__c + newOp.Operation_Length__c);

        // Get recent operations first
        List<EditingOperation__c> candidates = [
            SELECT Id, Operation_Type__c, Operation_Position__c, Operation_Length__c, 
                User__c, Operation_Content__c, Operation_JSON__c
            FROM EditingOperation__c 
            WHERE Collaborative_Session__c = :newOp.Collaborative_Session__c
            AND User__c != :newOp.User__c
            AND Operation_Status__c IN ('PENDING_TRANSFORM', 'APPLIED')
            AND Server_Revision__c > :minRevision
            ORDER BY Operation_Timestamp__c DESC
        ];

        // Apply overlap detection in Apex (since SOQL can’t do arithmetic between fields)
        List<EditingOperation__c> conflicts = new List<EditingOperation__c>();
        for (EditingOperation__c op : candidates) {
            Integer existingStart = Integer.Valueof(op.Operation_Position__c);
            Integer existingEnd = Integer.Valueof(op.Operation_Position__c + op.Operation_Length__c);

            Boolean overlaps = 
                (existingStart <= opStart && existingEnd > opStart) ||
                (existingStart < opEnd && existingStart >= opStart);

            if (overlaps) {
                conflicts.add(op);
            }
        }

        return conflicts;
    }

    private static void createConflictResolutionRecords(EditingOperation__c newOp, List<EditingOperation__c> conflicts, OperationalTransformState__c otState) {
        List<EditingConflict__c> conflictRecords = new List<EditingConflict__c>();
        
        for (EditingOperation__c conflictingOp : conflicts) {
            EditingConflict__c conflict = new EditingConflict__c();
                conflict.Collaborative_Session__c = newOp.Collaborative_Session__c;
                conflict.Primary_Operation__c = newOp.Id;
                conflict.Conflicting_Operation__c = conflictingOp.Id;
                conflict.Conflict_Type__c = determineConflictType(newOp, conflictingOp);
                conflict.Conflict_Severity__c = calculateConflictSeverity(newOp, conflictingOp);
                conflict.Conflict_Position__c = Math.min(newOp.Operation_Position__c, conflictingOp.Operation_Position__c);
                conflict.Conflict_Length__c = calculateConflictLength(newOp, conflictingOp);
                conflict.Resolution_Strategy__c = selectResolutionStrategy(newOp, conflictingOp, otState);
                conflict.Resolution_Status__c = 'PENDING_RESOLUTION';
                conflict.AI_Suggested_Resolution__c = generateAIResolution(newOp, conflictingOp);
                conflict.User_Priority_Primary__c = getUserPriority(newOp.User__c);
                conflict.User_Priority_Conflicting__c = getUserPriority(conflictingOp.User__c);
                conflict.Automatic_Resolution_Possible__c = canAutoResolve(newOp, conflictingOp);
                conflict.Created_Date__c = DateTime.now();
            
            conflictRecords.add(conflict);
        }
        
        insert conflictRecords;
        
        // Process resolutions
        for (EditingConflict__c conflict : conflictRecords) {
            processConflictResolution(conflict);
        }
    }

    private static String determineConflictType(EditingOperation__c op1, EditingOperation__c op2) {
        if (op1.Operation_Type__c == 'DELETE' && op2.Operation_Type__c == 'DELETE') {
            return 'CONCURRENT_DELETE';
        } else if (op1.Operation_Type__c == 'INSERT' && op2.Operation_Type__c == 'INSERT') {
            return 'CONCURRENT_INSERT';
        } else if ((op1.Operation_Type__c == 'DELETE' && op2.Operation_Type__c == 'INSERT') ||
                   (op1.Operation_Type__c == 'INSERT' && op2.Operation_Type__c == 'DELETE')) {
            return 'INSERT_DELETE_CONFLICT';
        } else if (op1.Operation_Type__c == 'FORMAT' || op2.Operation_Type__c == 'FORMAT') {
            return 'FORMATTING_CONFLICT';
        } else {
            return 'CONTENT_OVERLAP';
        }
    }

    private static String calculateConflictSeverity(EditingOperation__c op1, EditingOperation__c op2) {
        Integer overlapLength = calculateOverlapLength(op1, op2);
        String contentSimilarity = calculateContentSimilarity(op1.Operation_Content__c, op2.Operation_Content__c);
        
        if (overlapLength > 100 || contentSimilarity == 'HIGH') {
            return 'HIGH';
        } else if (overlapLength > 20 || contentSimilarity == 'MEDIUM') {
            return 'MEDIUM';
        } else {
            return 'LOW';
        }
    }

    private static Integer calculateConflictLength(EditingOperation__c op1, EditingOperation__c op2) {
        Decimal start1 = op1.Operation_Position__c;
        Decimal end1 = start1 + op1.Operation_Length__c;
        Decimal start2 = op2.Operation_Position__c;
        Decimal end2 = start2 + op2.Operation_Length__c;
        
        Decimal overlapStart = Math.max(start1, start2);
        Decimal overlapEnd = Math.min(end1, end2);
        Integer intToDecimal = Integer.ValueOf(Math.max(0, overlapEnd - overlapStart));
        return intToDecimal;
    }

    private static String selectResolutionStrategy(EditingOperation__c op1, EditingOperation__c op2, OperationalTransformState__c otState) {
        if (otState.Auto_Merge_Simple_Conflicts__c) {
            if (op1.Operation_Type__c == 'FORMAT' || op2.Operation_Type__c == 'FORMAT') {
                return 'AUTO_MERGE_FORMATTING';
            } else if (calculateOverlapLength(op1, op2) == 0) {
                return 'AUTO_MERGE_NON_OVERLAPPING';
            }
        }
        
        return 'MANUAL_RESOLUTION_REQUIRED';
    }

    private static String generateAIResolution(EditingOperation__c op1, EditingOperation__c op2) {
        // AI-powered conflict resolution suggestion
        Map<String, Object> aiRequest = new Map<String, Object>{
            'operation1' => new Map<String, Object>{
                'type' => op1.Operation_Type__c,
                'content' => op1.Operation_Content__c,
                'position' => op1.Operation_Position__c,
                'user' => op1.User__c
            },
            'operation2' => new Map<String, Object>{
                'type' => op2.Operation_Type__c,
                'content' => op2.Operation_Content__c,
                'position' => op2.Operation_Position__c,
                'user' => op2.User__c
            },
            'context' => 'collaborative_editing_conflict'
        };
        
        // Call AI service for resolution suggestion
        String aiSuggestion = AIResolutionService.generateResolutionSuggestion(JSON.serialize(aiRequest));
        return aiSuggestion;
    }

    private static Integer getUserPriority(String userId) {
        User user = [SELECT Profile.Name FROM User WHERE Id = :userId LIMIT 1];
        if (user.Profile.Name.contains('Admin')) return 1;
        if (user.Profile.Name.contains('Manager')) return 2;
        if (user.Profile.Name.contains('Senior')) return 3;
        return 4;
    }

    private static Boolean canAutoResolve(EditingOperation__c op1, EditingOperation__c op2) {
        // Simple conflicts that can be automatically resolved
        if (op1.Operation_Type__c == 'FORMAT' && op2.Operation_Type__c == 'FORMAT') {
            return true; // Merge formatting changes
        }
        if (calculateOverlapLength(op1, op2) == 0) {
            return true; // Non-overlapping operations
        }
        if (op1.Operation_Type__c == 'INSERT' && op2.Operation_Type__c == 'INSERT' && 
            op1.Operation_Position__c != op2.Operation_Position__c) {
            return true; // Different insertion points
        }
        return false;
    }

    private static void processConflictResolution(EditingConflict__c conflict) {
        if (conflict.Automatic_Resolution_Possible__c && conflict.Resolution_Strategy__c.startsWith('AUTO_')) {
            executeAutomaticResolution(conflict);
        } else {
            // Create manual resolution task
            createManualResolutionTask(conflict);
        }
    }

    private static void executeAutomaticResolution(EditingConflict__c conflict) {
        EditingOperation__c primaryOp = [SELECT Id, Operation_JSON__c FROM EditingOperation__c WHERE Id = :conflict.Primary_Operation__c];
        EditingOperation__c conflictingOp = [SELECT Id, Operation_JSON__c FROM EditingOperation__c WHERE Id = :conflict.Conflicting_Operation__c];
        
        Map<String, Object> resolution = new Map<String, Object>();
        
        if (conflict.Resolution_Strategy__c == 'AUTO_MERGE_NON_OVERLAPPING') {
            // Apply both operations in order
            resolution = mergeNonOverlappingOperations(primaryOp, conflictingOp);
        } else if (conflict.Resolution_Strategy__c == 'AUTO_MERGE_FORMATTING') {
            // Merge formatting attributes
            resolution = mergeFormattingOperations(primaryOp, conflictingOp);
        }
        
        // Create resolved operation
        EditingOperation__c resolvedOp = new EditingOperation__c(
            Collaborative_Session__c = conflict.Collaborative_Session__c,
            Operation_Type__c = 'MERGED_OPERATION',
            Operation_JSON__c = JSON.serialize(resolution),
            Operation_Status__c = 'RESOLVED_AUTOMATICALLY',
            Resolution_Method__c = conflict.Resolution_Strategy__c,
            Parent_Conflict__c = conflict.Id,
            User__c = primaryOp.User__c, // Primary user gets credit
            Operation_Timestamp__c = DateTime.now()
        );
        insert resolvedOp;
        
        // Update conflict status
        conflict.Resolution_Status__c = 'RESOLVED_AUTOMATICALLY';
        conflict.Resolved_Operation__c = resolvedOp.Id;
        conflict.Resolution_Timestamp__c = DateTime.now();
        update conflict;
        
        // Apply the resolved operation
        applyResolvedOperation(resolvedOp);
    }

    private static void createManualResolutionTask(EditingConflict__c conflict) {
        // Create task for manual conflict resolution
        Task resolutionTask = new Task(
            Subject = 'Resolve Editing Conflict: ' + conflict.Conflict_Type__c,
            Description = 'Manual resolution required for collaborative editing conflict.\n' +
                         'Conflict Type: ' + conflict.Conflict_Type__c + '\n' +
                         'Severity: ' + conflict.Conflict_Severity__c + '\n' +
                         'AI Suggestion: ' + conflict.AI_Suggested_Resolution__c,
            Priority = conflict.Conflict_Severity__c == 'HIGH' ? 'High' : 'Normal',
            Status = 'Not Started',
            ActivityDate = Date.today().addDays(1),
            OwnerId = getConflictResolver(conflict)
        );
        insert resolutionTask;
        
        // Create conflict resolution UI record
        ConflictResolutionUI__c resolutionUI = new ConflictResolutionUI__c(
            Editing_Conflict__c = conflict.Id,
            Resolution_Task__c = resolutionTask.Id,
            UI_Component__c = 'ConflictResolutionModal',
            Display_Primary_Operation__c = true,
            Display_Conflicting_Operation__c = true,
            Display_AI_Suggestion__c = true,
            Allow_Manual_Edit__c = true,
            Resolution_Options_JSON__c = generateResolutionOptions(conflict),
            Status__c = 'PENDING_USER_ACTION'
        );
        insert resolutionUI;
    }

    private static String getConflictResolver(EditingConflict__c conflict) {
        // Return user with higher priority or session owner
        if (conflict.User_Priority_Primary__c <= conflict.User_Priority_Conflicting__c) {
            return [SELECT User__c FROM EditingOperation__c WHERE Id = :conflict.Primary_Operation__c].User__c;
        } else {
            return [SELECT User__c FROM EditingOperation__c WHERE Id = :conflict.Conflicting_Operation__c].User__c;
        }
    }

    private static String generateResolutionOptions(EditingConflict__c conflict) {
        Map<String, Object> options = new Map<String, Object>{
    'acceptPrimary' => new Map<String, Object>{
        'label' => 'Accept Primary User\'s Changes',
        'description' => 'Keep the changes made by the primary user and discard conflicting changes',
        'action' => 'ACCEPT_PRIMARY_OPERATION'
    },
    'acceptConflicting' => new Map<String, Object>{
        'label' => 'Accept Conflicting User\'s Changes',
        'description' => 'Keep the changes made by the conflicting user and discard primary changes',
        'action' => 'ACCEPT_CONFLICTING_OPERATION'
    },
    'mergeChanges' => new Map<String, Object>{
        'label' => 'Merge Both Changes',
        'description' => 'Attempt to intelligently merge both sets of changes',
        'action' => 'MERGE_OPERATIONS',
        'available' => conflict.Conflict_Type__c != 'CONCURRENT_DELETE'
    },
    'manualEdit' => new Map<String, Object>{
        'label' => 'Manual Edit',
        'description' => 'Manually edit the conflicted section',
        'action' => 'MANUAL_RESOLUTION'
    },
    'revertToVersion' => new Map<String, Object>{
        'label' => 'Revert to Previous Version',
        'description' => 'Revert this section to a previous stable version',
        'action' => 'REVERT_TO_STABLE'
    }
};

return JSON.serialize(options);
}

private static Map<String, Object> mergeNonOverlappingOperations(EditingOperation__c op1, EditingOperation__c op2) {
    Map<String, Object> op1Data = (Map<String, Object>)JSON.deserializeUntyped(op1.Operation_JSON__c);
    Map<String, Object> op2Data = (Map<String, Object>)JSON.deserializeUntyped(op2.Operation_JSON__c);
    
    // Adjust positions based on operation order
    Integer pos1 = (Integer)op1Data.get('position');
    Integer pos2 = (Integer)op2Data.get('position');
    
    List<Map<String, Object>> mergedOps = new List<Map<String, Object>>();
    
    if (pos1 < pos2) {
        mergedOps.add(op1Data);
        // Adjust second operation position if first was an insert
        if ((String)op1Data.get('type') == 'INSERT') {
            op2Data.put('position', pos2 + ((String)op1Data.get('content')).length());
        }
        mergedOps.add(op2Data);
    } else {
        mergedOps.add(op2Data);
        // Adjust first operation position if second was an insert
        if ((String)op2Data.get('type') == 'INSERT') {
            op1Data.put('position', pos1 + ((String)op2Data.get('content')).length());
        }
        mergedOps.add(op1Data);
    }
    
    return new Map<String, Object>{
        'type' => 'COMPOSITE_OPERATION',
        'operations' => mergedOps,
        'resolutionMethod' => 'AUTO_MERGE_NON_OVERLAPPING'
    };
}

private static Map<String, Object> mergeFormattingOperations(EditingOperation__c op1, EditingOperation__c op2) {
    Map<String, Object> op1Data = (Map<String, Object>)JSON.deserializeUntyped(op1.Operation_JSON__c);
    Map<String, Object> op2Data = (Map<String, Object>)JSON.deserializeUntyped(op2.Operation_JSON__c);
    
    Map<String, Object> mergedFormat = new Map<String, Object>();
    
    // Merge formatting attributes
    Map<String, Object> format1 = (Map<String, Object>)op1Data.get('attributes');
    Map<String, Object> format2 = (Map<String, Object>)op2Data.get('attributes');
    
    if (format1 != null) mergedFormat.putAll(format1);
    if (format2 != null) mergedFormat.putAll(format2);
    
    return new Map<String, Object>{
        'type' => 'FORMAT',
        'position' => Math.min((Integer)op1Data.get('position'), (Integer)op2Data.get('position')),
        'length' => Math.max((Integer)op1Data.get('length'), (Integer)op2Data.get('length')),
        'attributes' => mergedFormat,
        'resolutionMethod' => 'AUTO_MERGE_FORMATTING'
    };
}

private static void applyResolvedOperation(EditingOperation__c resolvedOp) {
    Map<String, Object> opData = (Map<String, Object>)JSON.deserializeUntyped(resolvedOp.Operation_JSON__c);
    
    // Update document state
    DocumentCollaborativeState__c docState = [
        SELECT Id, Current_Content__c, Content_Hash__c, Last_Modified__c
        FROM DocumentCollaborativeState__c 
        WHERE Collaborative_Session__c = :resolvedOp.Collaborative_Session__c 
        LIMIT 1
    ];
    
    // Apply operation to document content
    String newContent = applyOperationToContent(docState.Current_Content__c, opData);
    
    docState.Current_Content__c = newContent;
    docState.Content_Hash__c = generateContentHash(newContent);
    docState.Last_Modified__c = DateTime.now();
    
    update docState;
    
    // Broadcast change to all active collaborators
    broadcastOperationToCollaborators(resolvedOp);
}

private static String applyOperationToContent(String content, Map<String, Object> operation) {
    String opType = (String)operation.get('type');
    Integer position = (Integer)operation.get('position');
    
    if (opType == 'INSERT') {
        String insertContent = (String)operation.get('content');
        return content.substring(0, position) + insertContent + content.substring(position);
    } else if (opType == 'DELETE') {
        Integer length = (Integer)operation.get('length');
        return content.substring(0, position) + content.substring(position + length);
    } else if (opType == 'COMPOSITE_OPERATION') {
        List<Object> operations = (List<Object>)operation.get('operations');
        String workingContent = content;
        for (Object op : operations) {
            workingContent = applyOperationToContent(workingContent, (Map<String, Object>)op);
        }
        return workingContent;
    }
    
    return content; // No change for other operation types
}

private static void broadcastOperationToCollaborators(EditingOperation__c operation) {
    // Get all active collaborators
    List<CollaborativeSessionParticipant__c> participants = [
        SELECT Id, User__c, Connection_Id__c, Last_Activity__c
        FROM CollaborativeSessionParticipant__c
        WHERE Collaborative_Session__c = :operation.Collaborative_Session__c
        AND Status__c = 'ACTIVE'
        AND Last_Activity__c > :DateTime.now().addMinutes(-30)
    ];
    
    // Create broadcast messages
    List<OperationBroadcast__c> broadcasts = new List<OperationBroadcast__c>();
    for (CollaborativeSessionParticipant__c participant : participants) {
        broadcasts.add(new OperationBroadcast__c(
            Participant__c = participant.Id,
            Operation__c = operation.Id,
            Message_Type__c = 'OPERATION_APPLIED',
            Broadcast_Status__c = 'PENDING',
            Message_JSON__c = operation.Operation_JSON__c,
            Created_Date__c = DateTime.now(),
            Priority__c = 'HIGH'
        ));
    }
    insert broadcasts;
    
    // Send real-time notifications (integrate with WebSocket/Server-Sent Events)
    RealTimeNotificationService.broadcastToConnections(broadcasts);
}

// Advanced conflict prevention through smart locking
public static void implementSmartLocking(String sessionId, String userId, String sectionId) {
    // Create or update section lock
    DocumentSectionLock__c sectionLock = new DocumentSectionLock__c();
    
    try {
        sectionLock = [
            SELECT Id, Lock_Status__c, Locked_By__c, Lock_Expiry__c
            FROM DocumentSectionLock__c
            WHERE Collaborative_Session__c = :sessionId
            AND Section_Identifier__c = :sectionId
            LIMIT 1
        ];
        
        if (sectionLock.Lock_Status__c == 'LOCKED' && sectionLock.Locked_By__c != userId) {
            // Section already locked by another user
            throw new ConflictException('Section is currently being edited by another user');
        }
        
    } catch (QueryException e) {
        // Lock doesn't exist, create new one
        sectionLock = new DocumentSectionLock__c(
            Collaborative_Session__c = sessionId,
            Section_Identifier__c = sectionId
        );
    }
    
    // Update lock details
    sectionLock.Lock_Status__c = 'LOCKED';
    sectionLock.Locked_By__c = userId;
    sectionLock.Lock_Type__c = 'OPTIMISTIC'; // OPTIMISTIC, PESSIMISTIC
    sectionLock.Lock_Acquired__c = DateTime.now();
    sectionLock.Lock_Expiry__c = DateTime.now().addMinutes(15); // Auto-expire in 15 minutes
    sectionLock.Auto_Release__c = true;
    sectionLock.Lock_Reason__c = 'USER_EDITING';
    
    upsert sectionLock;
    
    // Schedule automatic lock release
    scheduleAutomaticLockRelease(sectionLock.Id);
}

@future
public static void scheduleAutomaticLockRelease(String lockId) {
    DocumentSectionLock__c lock = [
        SELECT Id, Lock_Expiry__c, Auto_Release__c
        FROM DocumentSectionLock__c
        WHERE Id = :lockId
        LIMIT 1
    ];
    
    if (lock.Auto_Release__c && DateTime.now() > lock.Lock_Expiry__c) {
        lock.Lock_Status__c = 'RELEASED';
        lock.Released_Date__c = DateTime.now();
        lock.Release_Reason__c = 'AUTO_EXPIRED';
        update lock;
    }
}

// Utility methods
private static String generateDocumentHash(String sessionId) {
    // Generate hash of current document state
    return EncodingUtil.convertToHex(Crypto.generateDigest('SHA256', Blob.valueOf(sessionId + String.valueOf(DateTime.now()))));
}

private static String generateContentHash(String content) {
    return EncodingUtil.convertToHex(Crypto.generateDigest('SHA256', Blob.valueOf(content)));
}

private static Integer calculateOverlapLength(EditingOperation__c op1, EditingOperation__c op2) {
    Decimal start1 = op1.Operation_Position__c;
    Decimal end1 = start1 + (op1.Operation_Length__c != null ? op1.Operation_Length__c : 0);
    Decimal start2 = op2.Operation_Position__c;
    Decimal end2 = start2 + (op2.Operation_Length__c != null ? op2.Operation_Length__c : 0);
    
    Decimal overlapStart = Math.max(start1, start2);
    Decimal overlapEnd = Math.min(end1, end2);
    Integer convertDecToInt = Integer.valueof(Math.max(0, overlapEnd - overlapStart));
    return convertDecToInt;
}

private static String calculateContentSimilarity(String content1, String content2) {
    if (String.isEmpty(content1) || String.isEmpty(content2)) return 'LOW';
    
    // Simple similarity calculation - in production, use more sophisticated algorithms
    Integer minLength = Math.min(content1.length(), content2.length());
    Integer maxLength = Math.max(content1.length(), content2.length());
    
    if (minLength == 0) return 'LOW';
    
    Double similarity = (Double)minLength / maxLength;
    
    if (similarity > 0.8) return 'HIGH';
    if (similarity > 0.5) return 'MEDIUM';
    return 'LOW';
}

private static void applyOperationDirectly(EditingOperation__c operation, OperationalTransformState__c otState) {
    operation.Operation_Status__c = 'APPLIED';
    
    // Update operational transform state
    otState.Current_Revision__c += 1;
    
    // Update operation queue
    List<Object> operationQueue = (List<Object>)JSON.deserializeUntyped(otState.Operation_Queue_JSON__c);
    operationQueue.add(JSON.deserializeUntyped(operation.Operation_JSON__c));
    
    // Keep only last 100 operations in queue
    if (operationQueue.size() > 100) {
        // Apex List<Object> doesn't support subList(Integer, Integer) for this runtime context
        // so create a new list and copy the last 100 items manually
        List<Object> truncated = new List<Object>();
        Integer startIndex = operationQueue.size() - 100;
        for (Integer i = startIndex; i < operationQueue.size(); i++) {
            truncated.add(operationQueue.get(i));
        }
        operationQueue = truncated;
    }
    
    otState.Operation_Queue_JSON__c = JSON.serialize(operationQueue);
    update otState;
}

// Exception classes
public class ConflictException extends Exception {}

}