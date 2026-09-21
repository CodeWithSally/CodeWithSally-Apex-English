trigger Opportunities on Opportunity (before insert, before update, after insert) {
	if (Trigger.isBefore && Trigger.isInsert) {
		for (Opportunity opportunity : Trigger.new) {
			opportunity.DiscountType__c = OpportunitySettings__c.getInstance().DiscountType__c;
		}
		for (Opportunity opp : Trigger.new) {
			if (opp.Type != null && opp.Type.startsWith('Existing') && opp.AccountId == null) {
				opp.AccountId.addError(
					'You must provide an Account for OpportunityTriggerHandler for existing Customers.'
				);
			}
		}
	} else if (Trigger.isBefore && Trigger.isUpdate) {
		for (Opportunity opp : Trigger.new) {
			Opportunity existingOpp = Trigger.oldMap.get(opp.Id);
			if (opp.Type != existingOpp.Type) {
				opp.Type.addError('You cannot change the Opportunity type once it has been created.');
			}
		}
	} else if (Trigger.isAfter && Trigger.isInsert) {
		Set<Id> accountIds = new Set<Id>();
		for (Opportunity record : Trigger.new) {
			if (record.AccountId != null) {
				accountIds.add(record.AccountId);
			}
		}
		if (!accountIds.isEmpty()) {
			List<Account> accounts = [
				SELECT Id, Description
				FROM Account
				WHERE Id IN :accountIds
			];
			for (Account account : accounts) {
				account.Description = 'Last Opportunity Raised ' + System.today();
			}
			Database.update(accounts);
		}
	}
}
