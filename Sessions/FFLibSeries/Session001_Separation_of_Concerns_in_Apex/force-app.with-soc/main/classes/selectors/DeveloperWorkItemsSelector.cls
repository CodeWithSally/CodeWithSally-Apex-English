/**
 * Selector for DeveloperWorkItem__c including related Work Order account for invoicing.
 */
public virtual inherited sharing class DeveloperWorkItemsSelector {
	@TestVisible
	private static DeveloperWorkItemsSelector mock;

	/**
	 * Factory that returns this selector, or {@link #mock} when tests have set one.
	 * @return {@link DeveloperWorkItemsSelector} instance.
	 */
	public static DeveloperWorkItemsSelector newInstance() {
		return mock != null ? mock : new DeveloperWorkItemsSelector();
	}

	/**
	 * Selects developer work items by Id as a generic SObject list, including WorkOrder account.
	 * @param ids DeveloperWorkItem__c Ids to query. Empty set returns an empty list.
	 * @return Matching work items with fields needed for cost and invoicing.
	 */
	public List<SObject> selectSObjectsById(Set<Id> ids) {
		return [
			SELECT
				Id,
				Name,
				WorkOrder__c,
				DeveloperCost__c,
				CodingHours__c,
				CodeReviewingHours__c,
				TechnicalDesignHours__c,
				WorkOrder__r.Account__c
			FROM DeveloperWorkItem__c
			WHERE Id IN :ids
			ORDER BY Name
		];
	}

	/**
	 * Selects developer work items by Id with fields needed for cost and invoicing.
	 * @param idSet DeveloperWorkItem__c Ids to query. Empty set returns an empty list.
	 * @return Matching DeveloperWorkItem__c records; empty list when none match.
	 */
	public List<DeveloperWorkItem__c> selectById(Set<Id> idSet) {
		return (List<DeveloperWorkItem__c>) selectSObjectsById(idSet);
	}
}
