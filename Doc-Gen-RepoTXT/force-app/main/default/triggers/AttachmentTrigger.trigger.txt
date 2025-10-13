trigger AttachmentTrigger on Attachment (after insert, after delete) {
	
	final String SOBJ_PREFIX_CAPEX = Schema.SObjectType.Capex__c.getKeyPrefix();
	
	Capex_updateFlag();
	
	/**
     * Update the flag of parent Capex record
     * Dependent Methods: N/A
     * Action to Fire: after insert, after delete
     **/
	private void Capex_updateFlag() {
		if (trigger.isAfter && (trigger.isInsert || trigger.isDelete)) {
			Set<ID> capexIdSet = null;
			Integer capexPrefixLength = SOBJ_PREFIX_CAPEX.length();
			List<Attachment> attachList = trigger.isDelete ? trigger.old : trigger.new;
			for (Attachment attach : attachList) {
				if (attach.ParentId != null && String.valueOf(attach.ParentId).substring(0, capexPrefixLength) == SOBJ_PREFIX_CAPEX) {
					if (capexIdSet == null) capexIdSet = new Set<ID>();
					capexIdSet.add(attach.ParentId);
				}
			}
			if (capexIdSet != null) {
				List<Capex__c> updateCapexList = new List<Capex__c>();
				if (trigger.isInsert) {
					List<Capex__c> capexList = [SELECT Id, Document_Attached__c FROM Capex__c WHERE Id IN :capexIdSet];
					for (Capex__c capex : capexList) {
						if (capex.Document_Attached__c != true) {
							capex.Document_Attached__c = true;
							updateCapexList.add(capex);
						}
					}
				} else if (trigger.isDelete) {
					List<Capex__c> capexList = [SELECT Id, Document_Attached__c, (SELECT Id FROM Attachments) FROM Capex__c WHERE Id IN :capexIdSet];
					for (Capex__c capex : capexList) {
						if (capex.Attachments == null || capex.Attachments.size() == 0) {
							capex.Document_Attached__c = false;
							updateCapexList.add(capex);
						}
					}
				}
				if (updateCapexList.size() > 0) {
					update updateCapexList;
				}
			}
		}
	}
}