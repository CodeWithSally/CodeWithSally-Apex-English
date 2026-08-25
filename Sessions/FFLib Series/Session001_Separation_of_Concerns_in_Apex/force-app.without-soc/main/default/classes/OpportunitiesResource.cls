/**
 * REST resource that applies a discount to a single Opportunity identified in the URL path.
 * Path pattern: {@code /opportunities/{id}/applydiscount} with optional {@code discount} query parameter.
 */
@RestResource(UrlMapping='/opportunities/*/applydiscount')
global inherited sharing class OpportunitiesResource {
	/**
	 * Applies a discount to the Opportunity Id in the request URI.
	 * Reads the {@code discount} query parameter; defaults to zero when absent.
	 */
	@HttpPost
	global static void applyDiscount() {
		RestRequest req = RestContext.request;
		String[] uriParts = req.requestURI.split('/');
		Id opportunityId = uriParts[2];
		String discountParam = req.params.get('discount');
		Decimal discountPercentage = discountParam != null ? Decimal.valueOf(discountParam) : 0;

		Set<Id> idSet = new Set<Id>{ opportunityId };
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
				opportunity.Amount = opportunity.Amount * factor;
				updates.add(opportunity);
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
}
