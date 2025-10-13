trigger CapexTrigger on Capex__c (after insert, after update) {

    shareWithApprovers();
    rollupToBudgetedCapex();
    rollupToNYB();

    /**
     * Create sharing rules for approvers which are specified in record
     * Dependent Methods: N/A
     * Action to Fire: after insert, after update
     **/
     private void shareWithApprovers() {
        if (trigger.isAfter && (trigger.isInsert || trigger.isUpdate)) {
            final String ACCESS_LEVEL_ALL = 'All';
            final String ACCESS_LEVEL_EDIT = 'Edit';
            final String ACCESS_LEVEL_READ = 'Read';
            final Map<String, String> APPROVER_FIELD_AND_ACCESS = new Map<String, String>{
                'Country_Head_Sales_Director__c' => ACCESS_LEVEL_READ
                , 'Global_Account_Manager__c' => ACCESS_LEVEL_READ
                , 'Regional_Director_Deputy__c' => ACCESS_LEVEL_READ
                , 'Vertical_Head_Deputy__c' => ACCESS_LEVEL_READ
                , 'COO_Office__c' => ACCESS_LEVEL_EDIT
            };
            final List<String> ACCESS_LEVEL_COMPARE_LIST = new List<String>{ACCESS_LEVEL_ALL, ACCESS_LEVEL_EDIT, ACCESS_LEVEL_READ};
            final String sharingReason = Schema.Capex__Share.RowCause.Capex_Approver__c;
            List<Capex__Share> existingCapexShareList = null;
            List<Capex__Share> insertCapexShareList = new List<Capex__Share>();
            List<Capex__Share> deleteCapexShareList = new List<Capex__Share>();
            Set<String> approverFields = APPROVER_FIELD_AND_ACCESS.keySet();
            for (Capex__c capex : trigger.new) {
                Boolean hasChange = false;
                Set<ID> oldApproverIdSet = new Set<ID>(); // Used to avoid deleting the sharing rules created by manually
                
                if (trigger.isInsert) {
                    hasChange = true;
                } else if (trigger.isUpdate) {
                    for (String approverField : approverFields) {
                        // Delete all existing sharing rules if any change on approver fields
                        ID newApproverId = (ID)capex.get(approverField);
                        ID oldApproverId = (ID)trigger.oldMap.get(capex.Id).get(approverField);
                        if (oldApproverId != null)
                            oldApproverIdSet.add(oldApproverId);
                        if (oldApproverId != newApproverId) // approver changed
                            hasChange = true;
                    }
                }
                
                if (hasChange) {
                    if (trigger.isUpdate) {
                        // Delete sharing rule of old approvers
                        if (existingCapexShareList == null)
                            existingCapexShareList = [SELECT Id, ParentId, UserOrGroupId, RowCause FROM Capex__Share WHERE ParentId IN :trigger.new];
                        for (Capex__Share tempCapexShare : existingCapexShareList) {
                            if (tempCapexShare.ParentId == capex.Id && tempCapexShare.UserOrGroupId != capex.OwnerId
                                && oldApproverIdSet.contains(tempCapexShare.UserOrGroupId) && tempCapexShare.RowCause == sharingReason) {
                                deleteCapexShareList.add(tempCapexShare);
                            }
                        }
                    }
                    // Start creating sharing rules
                    Set<ID> addedApproverIdSet = new Set<ID>(); // Used to avoid sharing rules having duplicate target user
                    for (String approverField : approverFields) {
                        ID newApproverId = (ID)capex.get(approverField);
                        
                        if (newApproverId != null && newApproverId != capex.OwnerId) { // Do not need sharing rule for record owner
                            String accessLevel = APPROVER_FIELD_AND_ACCESS.get(approverField);
                            if (addedApproverIdSet.contains(newApproverId)) { // if already have a sharing rule
                                // Remove old sharing rule if the new access level is greater
                                Integer countCS = 0;
                                for (Capex__Share tempInsertCapexShare : insertCapexShareList) {
                                    if (tempInsertCapexShare.ParentId == newApproverId) {
                                        for (String compareAccessLevel : ACCESS_LEVEL_COMPARE_LIST) {
                                            if (accessLevel == compareAccessLevel) {
                                                if (tempInsertCapexShare.AccessLevel != compareAccessLevel) {
                                                    insertCapexShareList.remove(countCS);
                                                    addedApproverIdSet.remove(newApproverId);
                                                }
                                                break;
                                            }
                                        }
                                        break;
                                    }
                                    countCS++;
                                }
                            }
                            
                            if (!addedApproverIdSet.contains(newApproverId)) {
                                Capex__Share insertCapexShare = new Capex__Share(
                                    ParentId = capex.Id
                                    , UserOrGroupId = newApproverId
                                    , AccessLevel = accessLevel
                                    , RowCause = sharingReason
                                );
                                insertCapexShareList.add(insertCapexShare);
                                addedApproverIdSet.add(newApproverId);
                            }
                        }
                    }
                }
            }
            // Start writing the changes to database
            if (insertCapexShareList.size() > 0 || deleteCapexShareList.size() > 0) {
                System.Savepoint sp = database.setSavepoint();
                List<Capex__Share> dmlExRecordList = null;
                DmlException dmlEx = null;
                if (deleteCapexShareList.size() > 0 && dmlEx == null) {
                    try {
                        delete deleteCapexShareList;
                    } catch (DmlException dmle) {
                        database.rollback(sp);
                        dmlEx = dmle;
                        dmlExRecordList = deleteCapexShareList;
                    }
                }
                if (insertCapexShareList.size() > 0 && dmlEx == null) {
                    try {
                        insert insertCapexShareList;
                    } catch (DmlException dmle) {
                        database.rollback(sp);
                        dmlEx = dmle;
                        dmlExRecordList = insertCapexShareList;
                    }
                }
                // Handle error messages
                if (dmlEx != null) {
                    Integer dmlSize = dmlEx.getNumDml();
                    for (Integer i = 0; i < dmlSize; i++) {
                        Capex__Share failedCapexShare = dmlExRecordList.get(dmlEx.getDmlIndex(i));
                        Capex__c failedCapex = trigger.newMap.get(failedCapexShare.ParentId);
                        if (failedCapex != null) {
                            failedCapex.addError(dmlEx.getMessage());
                            failedCapex.addError(dmlEx.getDmlMessage(i));
                        }
                    }
                }
            }
        }
     }
    
    /**
     * Roll up Requested_Amount_LOCAL__c and update budgeted capax RemainingAmount Remaining_Amount_Local__c after insert and update 
     * Dependent Methods: N/A
     * Action to Fire: after insert, after update
     **/
    private void rollupToBudgetedCapex() {
        if (trigger.isAfter && (trigger.isInsert || trigger.isUpdate)) {
            
            //System.enqueueJob(new rollupToBudgetedCapexNNYBQueueable(trigger.new));
            List<Recordtype> Record_Type_ID = [select id from Recordtype where Name = 'Budgeted Capex'];
            Set<Id> clondIDs = new Set<Id>();
            //system.debug('01290000000SVCFAA4>>>'+Record_Type_ID[0].id);
            for (Capex__c capex : trigger.new){
                if(capex.RecordTypeId != Record_Type_ID[0].Id && (capex.Cloned_from__c!=null )){ 
                    clondIDs.add(capex.Cloned_from__c);  
                } 
            }
            if(clondIDs.size() > 0 ){
                
                List<Capex__c> budgetedCapexs = [select Id, Budget_Invested__c, Budgeted_Amount_LOCAL__c,Requested_Amount_LOCAL__c,Remaining_Amount_Local__c ,
                                                 (select Id, Requested_Amount_LOCAL__c,Budgeted_AMT_EUR__c,Budgeted_Amount_LOCAL__c ,Cloned_from__c ,Status__c 
                                                  from Capexs__r where Status__c != 'Void')
                                                 from Capex__c 
                                                 where Id IN :clondIDs];
                
                if(budgetedCapexs.size() > 0 ){
                    system.debug('budgetedCapexs.size()>>'+budgetedCapexs.size());
                    for(Capex__c budgetedCapex : budgetedCapexs){
                        Boolean Invested = False;
                        Decimal rollup_RequestedAmountLOCAL = 0.00 ;
                        if (budgetedCapex.Capexs__r!=null){
                            for(Capex__c ChildCapex : budgetedCapex.Capexs__r){
                                if(budgetedCapex.Id == ChildCapex.Cloned_from__c){
                                    rollup_RequestedAmountLOCAL += ChildCapex.Requested_Amount_LOCAL__c;
                                    Invested = true;
                                }  
                            }
                        }
                        budgetedCapex.Remaining_Amount_Local__c = budgetedCapex.Budgeted_Amount_LOCAL__c-rollup_RequestedAmountLOCAL;
                        budgetedCapex.Budget_Invested__c = Invested;
                        system.debug('budgetedCapex.Remaining_Amount_Local__c:'+budgetedCapex.Remaining_Amount_Local__c);
                    }
                    update budgetedCapexs;
                }
                
            }    
            
            
            
        }
    }
    
    private void rollupToNYB() {
        if (trigger.isAfter && (trigger.isInsert || trigger.isUpdate)) {
            
            //System.enqueueJob(new rollupToNYBQueueable(trigger.new));
			
            //List<Recordtype> Record_Type_ID = [select id from Recordtype where Name = 'Budgeted Capex'];
            Set<Id> NYBID = new Set<Id>();
            for (Capex__c capex : trigger.new){
                if(capex.Next_Year_Budget__c!=null){
                	NYBID.add(capex.Next_Year_Budget__c);
            	}    
            }
            
            List<Next_Year_Budget__c> NYB_Parents = [SELECT Id, Total_Budgeted_Amount_EUR__c,Total_Budgeted_Amount_LOCAL__c,
                                                    Approved_Next_Year_Budget__c,Pending_Approving_Next_Year_Budget__c,
                                                    New_Rejected_Next_Year_Budget__c,Void_Next_Year_Budget__c,
                                                    (SELECT Id, Name , Requested_Amount_LOCAL__c,Budgeted_AMT_EUR__c,Budgeted_Amount_LOCAL__c,Capex_Approval_Status__c,Next_Year_Budget__c 
                                                     FROM Next_Year_Budget_Items__r)
                                                    FROM Next_Year_Budget__c 
                                                    WHERE Id IN :NYBID ];
                
			if(NYB_Parents.size() > 0 ){
                system.debug('NYB_Parents.size():'+NYB_Parents.size());
                for(Next_Year_Budget__c NYB_Parent : NYB_Parents){
                    
                    Decimal rollup_Budgeted_AMT_EUR = 0.00 ;
                    Decimal rollup_Budgeted_Amount_LOCAL = 0.00 ;
                    Integer count_Approved_NYB = 0 ;
                    Integer count_Approving_NYB = 0 ;
                    Integer count_New_Reject_NYB = 0 ;
                    Integer count_Void_NYB = 0 ;
                    
                    for(Capex__c NYBCapex : NYB_Parent.Next_Year_Budget_Items__r){
                        if(NYB_Parent.Id == NYBCapex.Next_Year_Budget__c){
                            if(NYBCapex.Capex_Approval_Status__c=='Budgeted Capex'){
                                rollup_Budgeted_AMT_EUR += NYBCapex.Budgeted_AMT_EUR__c ;
                            	rollup_Budgeted_Amount_LOCAL += NYBCapex.Budgeted_Amount_LOCAL__c ;
                                count_Approved_NYB += 1;
                            }else if(NYBCapex.Capex_Approval_Status__c=='Pending Approval by GOO'){
                                rollup_Budgeted_AMT_EUR += NYBCapex.Budgeted_AMT_EUR__c ;
                            	rollup_Budgeted_Amount_LOCAL += NYBCapex.Budgeted_Amount_LOCAL__c ;
                                count_Approving_NYB += 1;
                            }else if(NYBCapex.Capex_Approval_Status__c=='New Registration'||NYBCapex.Capex_Approval_Status__c=='Rejected by GOO'){
                                rollup_Budgeted_AMT_EUR += NYBCapex.Budgeted_AMT_EUR__c ;
                            	rollup_Budgeted_Amount_LOCAL += NYBCapex.Budgeted_Amount_LOCAL__c ;
                                count_New_Reject_NYB += 1;
                            }else if(NYBCapex.Capex_Approval_Status__c=='Void'){
                                count_Void_NYB += 1;                                
                            }
                        }
                    }
                    NYB_Parent.Total_Budgeted_Amount_EUR__c = rollup_Budgeted_AMT_EUR;
                    NYB_Parent.Total_Budgeted_Amount_LOCAL__c = rollup_Budgeted_Amount_LOCAL;
                    NYB_Parent.Approved_Next_Year_Budget__c = count_Approved_NYB;
                    NYB_Parent.Pending_Approving_Next_Year_Budget__c = count_Approving_NYB;
                    NYB_Parent.New_Rejected_Next_Year_Budget__c = count_New_Reject_NYB;
                    NYB_Parent.Void_Next_Year_Budget__c = count_Void_NYB;
					system.debug('NYB_Parent>>'+NYB_Parent);
                }
                update NYB_Parents;
            }
 
            
           
        }
    }
}