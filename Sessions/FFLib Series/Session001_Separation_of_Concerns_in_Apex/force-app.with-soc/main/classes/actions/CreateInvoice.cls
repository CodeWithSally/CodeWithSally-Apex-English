/**
 * Invocable action that creates an Invoice from an Opportunity.
 * Delegates to {@link OpportunitiesService}.
 */
public inherited sharing class CreateInvoice {
	/**
	 * Creates an Invoice for each request via {@link OpportunitiesService#createInvoices}.
	 * @param requests Opportunity Id and optional discount percent per request. Cannot be null.
	 * @return Invoice Id and Name in the same order as {@code requests}.
	 */
	@InvocableMethod(
		label='Create Invoice'
		description='Creates an Invoice from an Opportunity, optionally applying a discount first.'
		category='Opportunities'
	)
	public static List<Result> execute(List<Request> requests) {
		List<Result> results = new List<Result>();
		for (Request request : requests) {
			Set<Id> invoiceIds = OpportunitiesService.newInstance().createInvoices(
				new Set<Id>{ request.opportunityId },
				request.discountPercentage
			);
			Id invoiceId = new List<Id>(invoiceIds)[0];
			Result result = new Result();
			result.invoiceId = invoiceId;
			result.invoiceName = invoiceName(invoiceId);
			results.add(result);
		}
		return results;
	}

	@TestVisible
	private static String testInvoiceName;

	private static String invoiceName(Id invoiceId) {
		if (testInvoiceName != null) {
			return testInvoiceName;
		}
		return [SELECT Name FROM Invoice__c WHERE Id = :invoiceId].Name;
	}

	/**
	 * Input for {@link #execute}.
	 */
	public class Request {
		/**
		 * Opportunity Id to invoice.
		 */
		@InvocableVariable(label='Opportunity Id' required=true)
		public Id opportunityId;
		/**
		 * Optional discount percent applied before invoicing (for example 10 for 10%).
		 */
		@InvocableVariable(label='Discount Percentage')
		public Decimal discountPercentage;
	}

	/**
	 * Output for {@link #execute}.
	 */
	public class Result {
		/**
		 * Id of the created Invoice__c.
		 */
		@InvocableVariable(label='Invoice Id')
		public Id invoiceId;
		/**
		 * Auto-number Name of the created Invoice__c (for example INV-00000001).
		 */
		@InvocableVariable(label='Invoice Number')
		public String invoiceName;
	}
}
