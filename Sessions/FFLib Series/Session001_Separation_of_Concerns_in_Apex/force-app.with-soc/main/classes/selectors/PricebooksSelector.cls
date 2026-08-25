/**
 * Selector for Pricebook2 queries.
 */
public virtual inherited sharing class PricebooksSelector {
	@TestVisible
	private static PricebooksSelector mock;

	/**
	 * Factory that returns this selector, or {@link #mock} when tests have set one.
	 * @return {@link PricebooksSelector} instance.
	 */
	public static PricebooksSelector newInstance() {
		return mock != null ? mock : new PricebooksSelector();
	}

	/**
	 * Selects Pricebooks by Id as a generic SObject list.
	 * @param ids Pricebook2 Ids to query. Empty set returns an empty list.
	 * @return Matching pricebooks cast as SObject.
	 */
	public List<SObject> selectSObjectsById(Set<Id> ids) {
		return selectById(ids);
	}

	/**
	 * Selects Pricebooks by Id with Description, active, and standard flags.
	 * @param idSet Pricebook2 Ids to query. Empty set returns an empty list.
	 * @return Matching Pricebook2 records; empty list when none match.
	 */
	public List<Pricebook2> selectById(Set<Id> idSet) {
		return [
			SELECT Description, Id, IsActive, IsStandard, Name
			FROM Pricebook2
			WHERE Id IN :idSet
			ORDER BY Name
		];
	}
}
