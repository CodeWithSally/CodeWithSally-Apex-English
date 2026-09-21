/**
 * Controller for the Create Invoice Lightning action.
 * Delegates invoice creation to {@link OpportunitiesService}.
 */
public inherited sharing class OpportunityCreateInvoiceController {
	/**
	 * Creates an invoice for a single Opportunity from the Lightning action.
	 * @param opportunityId Opportunity Id to invoice. Cannot be null.
	 * @param discountPercentage Optional discount applied before invoicing when greater than zero.
	 * @return Id of the first created Invoice__c.
	 */
	@AuraEnabled(cacheable=false)
	public static Id createInvoice(Id opportunityId, Decimal discountPercentage) {
		try {
			Set<Id> invoiceIds = OpportunitiesService.newInstance()
				.createInvoices(new Set<Id>{ opportunityId }, discountPercentage);
			return new List<Id>(invoiceIds)[0];
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
