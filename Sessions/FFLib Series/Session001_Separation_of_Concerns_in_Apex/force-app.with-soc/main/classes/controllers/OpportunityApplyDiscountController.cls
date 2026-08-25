/**
 * Controller for the Apply Discount Lightning action.
 * Delegates discounting to {@link OpportunitiesService}.
 */
public inherited sharing class OpportunityApplyDiscountController {
	/**
	 * Applies a discount to a single Opportunity from the Lightning action.
	 * @param opportunityId Opportunity Id to discount. Cannot be null.
	 * @param discountPercentage Discount percent to apply (for example 10 for 10%).
	 */
	@AuraEnabled(cacheable=false)
	public static void applyDiscount(Id opportunityId, Decimal discountPercentage) {
		try {
			OpportunitiesService.newInstance()
				.applyDiscounts(new Set<Id>{ opportunityId }, discountPercentage);
		} catch (Exception e) {
			throw toAura(e);
		}
	}

	private static AuraHandledException toAura(Exception e) {
		AuraHandledException auraException = new AuraHandledException(e.getMessage());
		auraException.setMessage(e.getMessage());
		return auraException;
	}
}
