/**
 * Opportunity trigger handler that applies defaults, validates records, and updates related Account activity.
 */
public inherited sharing class OpportunitiesTriggerHandler {
	private List<Opportunity> records;

	/**
	 * Creates a handler for the current trigger context.
	 * Reads Trigger.new directly; it is not passed in.
	 */
	public OpportunitiesTriggerHandler() {
		this.records = Trigger.new == null ? new List<Opportunity>() : (List<Opportunity>) Trigger.new;
	}

	/**
	 * Before-insert entry point: applies defaults then validates new Opportunities.
	 */
	public void onBeforeInsert() {
		onApplyDefaults();
		onValidate();
	}

	/**
	 * Before-update entry point: validates Opportunities against their prior values.
	 * @param existingRecords Trigger.oldMap keyed by Opportunity Id. Cannot be null.
	 */
	public void onBeforeUpdate(Map<Id, SObject> existingRecords) {
		onValidate(existingRecords);
	}

	/**
	 * Sets DiscountType__c from {@link OpportunitySettings__c} on each Opportunity.
	 */
	public void onApplyDefaults() {
		for (Opportunity opportunity : records) {
			opportunity.DiscountType__c = OpportunitySettings__c.getInstance().DiscountType__c;
		}
	}

	/**
	 * Validates new Opportunities: Existing* types require an AccountId.
	 */
	public void onValidate() {
		for (Opportunity opp : records) {
			if (opp.Type != null && opp.Type.startsWith('Existing') && opp.AccountId == null) {
				opp.AccountId.addError(
					'You must provide an Account for OpportunityTriggerHandler for existing Customers.'
				);
			}
		}
	}

	/**
	 * Validates updates: Opportunity Type cannot change after create.
	 * @param existingRecords Prior Opportunity versions keyed by Id. Cannot be null.
	 */
	public void onValidate(Map<Id, SObject> existingRecords) {
		for (Opportunity opp : records) {
			Opportunity existingOpp = (Opportunity) existingRecords.get(opp.Id);
			if (opp.Type != existingOpp.Type) {
				opp.Type.addError('You cannot change the Opportunity type once it has been created.');
			}
		}
	}

	/**
	 * Updates Description on related Accounts to record opportunity activity via {@link Accounts}.
	 */
	public void onAfterInsert() {
		Accounts accounts = Accounts.newInstance(AccountsSelector.newInstance().selectByOpportunity(records));
		if (accounts.getRecords().isEmpty()) {
			return;
		}
		accounts.updateOpportunityActivity();
		Database.update(accounts.getRecords());
	}
}
