/**
 * Selector for PricebookEntry queries.
 */
public virtual inherited sharing class PricebookEntriesSelector {
	@TestVisible
	private static PricebookEntriesSelector mock;

	/**
	 * Factory that returns this selector, or {@link #mock} when tests have set one.
	 * @return {@link PricebookEntriesSelector} instance.
	 */
	public static PricebookEntriesSelector newInstance() {
		return mock != null ? mock : new PricebookEntriesSelector();
	}

	/**
	 * Selects PricebookEntries by Id as a generic SObject list.
	 * @param ids PricebookEntry Ids to query. Empty set returns an empty list.
	 * @return Matching pricebook entries cast as SObject.
	 */
	public List<SObject> selectSObjectsById(Set<Id> ids) {
		return selectById(ids);
	}

	/**
	 * Selects PricebookEntries by Id with standard pricing fields.
	 * @param idSet PricebookEntry Ids to query. Empty set returns an empty list.
	 * @return Matching PricebookEntry records; empty list when none match.
	 */
	public List<PricebookEntry> selectById(Set<Id> idSet) {
		return [
			SELECT
				Id,
				IsActive,
				Name,
				Pricebook2Id,
				Product2Id,
				ProductCode,
				UnitPrice,
				UseStandardPrice
			FROM PricebookEntry
			WHERE Id IN :idSet
			ORDER BY Name
		];
	}
}
