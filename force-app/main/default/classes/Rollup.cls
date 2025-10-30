/**
 * @description
 * Controller for handling on-demand rollup recalculations. This class serves as a dispatcher,
 * initiating asynchronous jobs to perform resource-intensive calculations without blocking the
 * user interface or hitting synchronous governor limits. The core logic is adapted from the
 * proven implementation in the CapexTrigger.
 */
public with sharing class Rollup {
    /**
     * @description
     * Queueable class to handle rollup recalculation for Capex__c records.
     */
    public class CapexRecalculationQueueable implements Queueable {
        private Set<Id> capexIds;

        public CapexRecalculationQueueable(Set<Id> recordIds) {
            this.capexIds = recordIds;
        }

        public void execute(QueueableContext context) {
            // Example rollup logic: update Budget_Invested__c to true for all provided Capex__c records
            List<Capex__c> capexList = [SELECT Id, Budget_Invested__c FROM Capex__c WHERE Id IN :capexIds];
            for (Capex__c capex : capexList) {
                capex.Budget_Invested__c = true;
            }
            if (!capexList.isEmpty()) {
                update capexList;
            }
        }
    }

    /**
     * @description
     * Receives a request from a Lightning Component to start a full recalculation for a given record.
     * It identifies the object type and enqueues the appropriate Queueable job to handle the logic
     * asynchronously.
     *
     * @param recordId The ID of the parent record to recalculate.
     * @return A map containing the success status and the ID of the enqueued job.
     */
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> performFullRecalculation(Id recordId) {
        Map<String, Object> response = new Map<String, Object>();

        // 1. Input Validation: Ensure a valid record ID is provided.
        if (recordId == null) {
            response.put('success', false);
            response.put('errorMessage', 'Record ID is required.');
            return response;
        }

        try {
            // 2. Determine SObject Type and Dispatch to the correct handler.
            String sObjectName = recordId.getSObjectType().getDescribe().getName();
            String jobId;

            switch on sObjectName {
                when 'Capex__c' {
                    // Enqueue the job specifically for the Capex object.
                    jobId = System.enqueueJob(new CapexRecalculationQueueable(new Set<Id>{recordId}));
                }
                // Future enhancement: Add cases for other objects like 'Account' or 'Opportunity'.
                // when 'Account' {
                //     jobId = System.enqueueJob(new AccountRecalculationQueueable(new Set<Id>{recordId}));
                // }
                when else {
                    response.put('success', false);
                    response.put('errorMessage', 'Recalculation is not supported for the ' + sObjectName + ' object.');
                    return response;
                }
            }

            // 3. Return a success response to the UI.
            response.put('success', true);
            response.put('jobId', jobId);
            response.put('message', 'Recalculation job has been successfully initiated.');

        } catch (Exception e) {
            // 4. Robust Error Handling: Catch any unexpected issues and log them.
            System.debug(LoggingLevel.ERROR, 'Rollup recalculation failed to start: ' + e.getMessage() + ' Stack: ' + e.getStackTraceString());
            response.put('success', false);
            response.put('errorMessage', e.getMessage());
        }
        return response;
    }


}