/**
 * Selector for Account queries used by account and opportunity activity flows.
 */
public virtual inherited sharing class AccountsSelector {
	@TestVisible
	private static AccountsSelector mock;

	/**
	 * Factory that returns this selector, or {@link #mock} when tests have set one.
	 * @return {@link AccountsSelector} instance.
	 */
	public static AccountsSelector newInstance() {
		return mock != null ? mock : new AccountsSelector();
	}

	/**
	 * Selects Accounts by Id as a generic SObject list.
	 * @param ids Account Ids to query. Empty set returns an empty list.
	 * @return Matching Accounts cast as SObject.
	 */
	public List<SObject> selectSObjectsById(Set<Id> ids) {
		return selectById(ids);
	}

	/**
	 * Selects Accounts by Id with Id, Name, and Description.
	 * @param idSet Account Ids to query. Empty set returns an empty list.
	 * @return Matching Accounts; empty list when none match.
	 */
	public List<Account> selectById(Set<Id> idSet) {
		return [
			SELECT Id, Name, Description
			FROM Account
			WHERE Id IN :idSet
			ORDER BY Name
		];
	}

	/**
	 * Selects Accounts related to the given Opportunities via AccountId.
	 * @param opportunities Opportunities whose AccountId values are collected. Cannot be null.
	 * @return Matching Accounts; empty list when no AccountIds are present.
	 */
	public List<Account> selectByOpportunity(List<Opportunity> opportunities) {
		Set<Id> accountIds = new Set<Id>();
		for (Opportunity opp : opportunities) {
			if (opp.AccountId != null) {
				accountIds.add(opp.AccountId);
			}
		}
		return selectById(accountIds);
	}
}
