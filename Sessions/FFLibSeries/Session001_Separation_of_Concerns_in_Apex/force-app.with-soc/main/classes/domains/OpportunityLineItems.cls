/**
 * Domain for OpportunityLineItem discounting based on parent Opportunity discount rules.
 */
public virtual inherited sharing class OpportunityLineItems {
	@TestVisible
	private static OpportunityLineItems mock;

	/**
	 * Factory that wraps the given line items, or {@link #mock} when tests have set one.
	 * @param recordList Opportunity line items to manage. Null is treated as an empty list.
	 * @return {@link OpportunityLineItems} instance.
	 */
	public static OpportunityLineItems newInstance(List<OpportunityLineItem> recordList) {
		return mock != null ? mock : new OpportunityLineItems(recordList);
	}

	private List<OpportunityLineItem> records;

	/**
	 * Creates a domain wrapping the given OpportunityLineItem records.
	 * @param sObjectList Opportunity line items to manage. Null is treated as an empty list.
	 */
	public OpportunityLineItems(List<OpportunityLineItem> sObjectList) {
		this.records = sObjectList == null ? new List<OpportunityLineItem>() : sObjectList;
	}

	/**
	 * Returns the OpportunityLineItem records held by this domain.
	 * @return The in-memory OpportunityLineItem list; never null.
	 */
	public List<OpportunityLineItem> getRecords() {
		return records;
	}

	/**
	 * Applies a percentage discount to UnitPrice on the wrapped line items in memory.
	 * When the parent Opportunity DiscountType__c is Approved Products, only lines whose
	 * product has DiscountingApproved__c true are changed. Does not perform DML.
	 * Callers that need to persist use {@link #getRecords()}.
	 * @param opps Parent opportunities providing DiscountType__c context. Cannot be null.
	 * @param discountPercentage Discount percent to apply. Null is treated as zero by {@link Opportunities#calculateDiscountFactor}.
	 */
	public virtual void applyDiscount(Opportunities opps, Decimal discountPercentage) {
		Map<Id, Opportunity> opportunitiesById = new Map<Id, Opportunity>(opps.getRecords());
		Decimal factor = Opportunities.calculateDiscountFactor(discountPercentage);

		for (OpportunityLineItem line : records) {
			Opportunity opportunity = opportunitiesById.get(line.OpportunityId);
			if (opportunity.DiscountType__c == 'Approved Products') {
				if (line.PricebookEntry.Product2.DiscountingApproved__c == false) {
					continue;
				}
			}
			line.UnitPrice = line.UnitPrice * factor;
		}
	}
}
