/**
 * Apex for Apply Discount reuse from tests and the Visualforce list action.
 * Record quick action uses LWC with LDS; discount logic is duplicated there too.
 */
public inherited sharing class OpportunityApplyDiscountController {
	/**
	 * Applies a discount to a single Opportunity (for example from an Apex entry point).
	 * @param opportunityId Opportunity Id to update. Cannot be null.
	 * @param discountPercentage Discount percent (for example 10 for 10%).
	 */
	@AuraEnabled(cacheable=false)
	public static void applyDiscount(Id opportunityId, Decimal discountPercentage) {
		try {
			applyDiscountForIds(new Set<Id>{ opportunityId }, discountPercentage);
		} catch (Exception e) {
			throw toAura(e);
		}
	}

	/**
	 * Applies a discount to the given Opportunities.
	 * @param idSet Opportunity Ids to update. Cannot be null.
	 * @param discountPercentage Discount percent (for example 10 for 10%).
	 */
	public static void applyDiscountForIds(Set<Id> idSet, Decimal discountPercentage) {
		Decimal factor = 1 - (discountPercentage == null ? 0 : discountPercentage / 100);
		List<Opportunity> opportunities = [
			SELECT Id, AccountId, Amount, CloseDate, Description, DiscountType__c, Name,
				(SELECT Id, OpportunityId, Description, Quantity, UnitPrice, ListPrice, PricebookEntryId, SortOrder,
					PricebookEntry.Name, PricebookEntry.Product2Id,
					PricebookEntry.Product2.DiscountingApproved__c,
					PricebookEntry.Pricebook2.Name
				FROM OpportunityLineItems ORDER BY SortOrder, PricebookEntry.Name)
			FROM Opportunity WHERE Id IN :idSet
		];
		List<SObject> updates = new List<SObject>();
		for (Opportunity opportunity : opportunities) {
			if (opportunity.OpportunityLineItems == null || opportunity.OpportunityLineItems.isEmpty()) {
				updates.add(
					new Opportunity(Id = opportunity.Id, Amount = opportunity.Amount * factor)
				);
			} else {
				for (OpportunityLineItem line : opportunity.OpportunityLineItems) {
					if (
						opportunity.DiscountType__c == 'Approved Products' &&
						!line.PricebookEntry.Product2.DiscountingApproved__c
					) {
						continue;
					}
					updates.add(
						new OpportunityLineItem(Id = line.Id, UnitPrice = line.UnitPrice * factor)
					);
				}
			}
		}
		if (!updates.isEmpty()) {
			Database.update(updates);
		}
	}

	private static AuraHandledException toAura(Exception e) {
		AuraHandledException auraException = new AuraHandledException(e.getMessage());
		auraException.setMessage(e.getMessage());
		return auraException;
	}
}
