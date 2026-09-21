/**
 * Selector for OpportunityLineItem queries used by discount and wizard flows.
 */
public virtual inherited sharing class OpportunityLineItemsSelector {
	@TestVisible
	private static OpportunityLineItemsSelector mock;

	/**
	 * Factory that returns this selector, or {@link #mock} when tests have set one.
	 * @return {@link OpportunityLineItemsSelector} instance.
	 */
	public static OpportunityLineItemsSelector newInstance() {
		return mock != null ? mock : new OpportunityLineItemsSelector();
	}

	/**
	 * Selects OpportunityLineItems by Id as a generic SObject list.
	 * @param ids OpportunityLineItem Ids to query. Empty set returns an empty list.
	 * @return Matching line items cast as SObject.
	 */
	public List<SObject> selectSObjectsById(Set<Id> ids) {
		return selectById(ids);
	}

	/**
	 * Selects OpportunityLineItems by Id with fields used by discounting, invoicing, and the wizard.
	 * @param idSet OpportunityLineItem Ids to query. Empty set returns an empty list.
	 * @return Matching line items ordered by SortOrder and pricebook entry name; empty list when none match.
	 */
	public List<OpportunityLineItem> selectById(Set<Id> idSet) {
		return [
			SELECT
				Id,
				OpportunityId,
				Description,
				Quantity,
				UnitPrice,
				ListPrice,
				PricebookEntryId,
				SortOrder,
				PricebookEntry.Name,
				PricebookEntry.Product2Id,
				PricebookEntry.Product2.DiscountingApproved__c,
				PricebookEntry.Pricebook2.Name
			FROM OpportunityLineItem
			WHERE Id IN :idSet
			ORDER BY SortOrder, PricebookEntry.Name
		];
	}

	/**
	 * Selects recently modified line items for Opportunities belonging to the given Accounts.
	 * @param accountIds Account Ids whose related opportunity line items are included. Empty set returns an empty list.
	 * @param recordLimit Maximum number of rows to return.
	 * @return Matching line items ordered by SystemModstamp descending; empty list when none match.
	 */
	public List<OpportunityLineItem> selectRecentlyUsed(Set<Id> accountIds, Integer recordLimit) {
		return [
			SELECT
				Id,
				OpportunityId,
				Description,
				Quantity,
				UnitPrice,
				ListPrice,
				PricebookEntryId,
				SortOrder,
				PricebookEntry.Name,
				PricebookEntry.Product2Id,
				PricebookEntry.Product2.DiscountingApproved__c,
				PricebookEntry.Pricebook2.Name
			FROM OpportunityLineItem
			WHERE Opportunity.AccountId IN :accountIds
			ORDER BY SystemModstamp DESC
			LIMIT :recordLimit
		];
	}
}
