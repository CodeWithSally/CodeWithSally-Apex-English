/**
 * Selector for TrainingWorkItem__c including related Work Order account for invoicing.
 */
public virtual inherited sharing class TrainingWorkItemsSelector {
	@TestVisible
	private static TrainingWorkItemsSelector mock;

	/**
	 * Factory that returns this selector, or {@link #mock} when tests have set one.
	 * @return {@link TrainingWorkItemsSelector} instance.
	 */
	public static TrainingWorkItemsSelector newInstance() {
		return mock != null ? mock : new TrainingWorkItemsSelector();
	}

	/**
	 * Selects training work items by Id as a generic SObject list, including WorkOrder account.
	 * @param ids TrainingWorkItem__c Ids to query. Empty set returns an empty list.
	 * @return Matching work items with fields needed for cost and invoicing.
	 */
	public List<SObject> selectSObjectsById(Set<Id> ids) {
		return [
			SELECT
				Id,
				Name,
				WorkOrder__c,
				TrainingCost__c,
				DeliveryHours__c,
				PreparationHours__c,
				WorkOrder__r.Account__c
			FROM TrainingWorkItem__c
			WHERE Id IN :ids
			ORDER BY Name
		];
	}

	/**
	 * Selects training work items by Id with fields needed for cost and invoicing.
	 * @param idSet TrainingWorkItem__c Ids to query. Empty set returns an empty list.
	 * @return Matching TrainingWorkItem__c records; empty list when none match.
	 */
	public List<TrainingWorkItem__c> selectById(Set<Id> idSet) {
		return (List<TrainingWorkItem__c>) selectSObjectsById(idSet);
	}
}
