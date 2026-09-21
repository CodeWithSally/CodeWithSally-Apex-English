/**
 * Selector for Opportunity queries used by discounting, invoicing, and summary views.
 */
public virtual inherited sharing class OpportunitiesSelector {
	@TestVisible
	private static OpportunitiesSelector mock;

	/**
	 * Factory that returns this selector, or {@link #mock} when tests have set one.
	 * @return {@link OpportunitiesSelector} instance.
	 */
	public static OpportunitiesSelector newInstance() {
		return mock != null ? mock : new OpportunitiesSelector();
	}

	/**
	 * Selects Opportunities by Id as a generic SObject list.
	 * @param ids Opportunity Ids to query. Empty set returns an empty list.
	 * @return Matching Opportunities cast as SObject.
	 */
	public List<SObject> selectSObjectsById(Set<Id> ids) {
		return selectById(ids);
	}

	/**
	 * Selects Opportunities by Id using the Opportunity field list (no related Account fields).
	 * @param idSet Opportunity Ids to query. Empty set returns an empty list.
	 * @return Matching Opportunities; empty list when none match.
	 */
	public List<Opportunity> selectById(Set<Id> idSet) {
		return [
			SELECT
				Id,
				AccountId,
				Amount,
				CloseDate,
				Description,
				DiscountType__c,
				Name,
				StageName,
				InvoicedStatus__c
			FROM Opportunity
			WHERE Id IN :idSet
			ORDER BY Name
		];
	}

	/**
	 * Selects Opportunities by Id including line items needed for discount and invoice flows.
	 * Parent Opportunity fields match {@link #selectById} plus related Account fields; line items match {@link OpportunityLineItemsSelector}.
	 * @param idSet Opportunity Ids to query. Empty set returns an empty list.
	 * @return Matching Opportunities with nested OpportunityLineItems; empty list when none match.
	 */
	public List<Opportunity> selectByIdWithProducts(Set<Id> idSet) {
		return [
			SELECT
				Id,
				AccountId,
				Amount,
				CloseDate,
				Description,
				DiscountType__c,
				Name,
				StageName,
				InvoicedStatus__c,
				Account.Name,
				Account.AccountNumber,
				Account.Owner.Name,
				(
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
					FROM OpportunityLineItems
					ORDER BY SortOrder, PricebookEntry.Name
				)
			FROM Opportunity
			WHERE Id IN :idSet
			ORDER BY Name
		];
	}

	/**
	 * Selects read-only opportunity summary DTOs including related Account and owner names.
	 * @param idSet Opportunity Ids to query. Empty set returns an empty list.
	 * @return {@link OpportunitySummary} wrappers; empty list when none match.
	 */
	public List<OpportunitySummary> selectOpportunitySummary(Set<Id> idSet) {
		List<OpportunitySummary> opportunitySummaries = new List<OpportunitySummary>();
		for (Opportunity opportunity : [
			SELECT
				Id,
				AccountId,
				Amount,
				CloseDate,
				Description,
				DiscountType__c,
				Name,
				StageName,
				InvoicedStatus__c,
				Account.Name,
				Account.AccountNumber,
				Account.Owner.Name
			FROM Opportunity
			WHERE Id IN :idSet
			ORDER BY Name
		]) {
			opportunitySummaries.add(new OpportunitySummary(opportunity));
		}
		return opportunitySummaries;
	}

	/**
	 * Returns a QueryLocator for Opportunities whose InvoicedStatus__c is Ready.
	 * @return QueryLocator suitable for Batch Apex start methods. Fields match {@link #selectById}.
	 */
	public Database.QueryLocator readyToInvoiceAsQueryLocator() {
		return Database.getQueryLocator([
			SELECT
				Id,
				AccountId,
				Amount,
				CloseDate,
				Description,
				DiscountType__c,
				Name,
				StageName,
				InvoicedStatus__c
			FROM Opportunity
			WHERE InvoicedStatus__c = 'Ready'
			ORDER BY Name
		]);
	}
}
