/**
 * Invocable action that creates an Invoice from an Opportunity.
 * Creates invoices directly without a service layer.
 */
public inherited sharing class CreateInvoice {
	/**
	 * Creates an Invoice for each request using direct Opportunity and Invoice DML.
	 * @param requests Opportunity Id and optional discount percent per request. Cannot be null.
	 * @return Invoice Ids in the same order as {@code requests}.
	 */
	@InvocableMethod(
		label='Create Invoice'
		description='Creates an Invoice from an Opportunity, optionally applying a discount first.'
		category='Opportunities'
	)
	public static List<Result> execute(List<Request> requests) {
		Set<Id> opportunityIds = new Set<Id>();
		for (Request request : requests) {
			opportunityIds.add(request.opportunityId);
		}

		Map<Id, Opportunity> opportunities = new Map<Id, Opportunity>([
			SELECT Id, AccountId, CloseDate, Description, DiscountType__c, Name,
				(SELECT Id, Description, Quantity, UnitPrice,
					PricebookEntry.Product2Id,
					PricebookEntry.Product2.DiscountingApproved__c
				FROM OpportunityLineItems ORDER BY SortOrder, PricebookEntry.Name)
			FROM Opportunity WHERE Id IN :opportunityIds
		]);

		Map<Id, Invoice__c> invoicesByOpportunityId = new Map<Id, Invoice__c>();
		Map<Id, List<InvoiceLine__c>> linesByOpportunityId = new Map<Id, List<InvoiceLine__c>>();
		for (Request request : requests) {
			Opportunity opportunity = opportunities.get(request.opportunityId);
			Decimal discountFactor = request.discountPercentage != null && request.discountPercentage > 0
				? 1 - (request.discountPercentage / 100)
				: null;

			Invoice__c invoice = new Invoice__c();
			invoice.Account__c = opportunity.AccountId;
			invoice.Description__c = opportunity.Description;
			invoice.InvoiceDate__c = opportunity.CloseDate;
			invoice.Opportunity__c = opportunity.Id;
			invoicesByOpportunityId.put(request.opportunityId, invoice);

			List<InvoiceLine__c> lines = new List<InvoiceLine__c>();
			for (OpportunityLineItem lineItem : opportunity.OpportunityLineItems) {
				InvoiceLine__c invoiceLine = new InvoiceLine__c();
				invoiceLine.Description__c = lineItem.Description;
				invoiceLine.Product__c = lineItem.PricebookEntry.Product2Id;
				invoiceLine.Quantity__c = lineItem.Quantity;
				invoiceLine.UnitPrice__c = discountFactor != null
					&& (opportunity.DiscountType__c != 'Approved Products'
						|| lineItem.PricebookEntry.Product2.DiscountingApproved__c)
					? lineItem.UnitPrice * discountFactor
					: lineItem.UnitPrice;
				lines.add(invoiceLine);
			}
			linesByOpportunityId.put(request.opportunityId, lines);
		}

		if (!invoicesByOpportunityId.isEmpty()) {
			insert invoicesByOpportunityId.values();
		}

		List<InvoiceLine__c> allLines = new List<InvoiceLine__c>();
		for (Id opportunityId : linesByOpportunityId.keySet()) {
			Invoice__c invoice = invoicesByOpportunityId.get(opportunityId);
			for (InvoiceLine__c line : linesByOpportunityId.get(opportunityId)) {
				line.Invoice__c = invoice.Id;
				allLines.add(line);
			}
		}
		if (!allLines.isEmpty()) {
			insert allLines;
		}

		List<Result> results = new List<Result>();
		for (Request request : requests) {
			Result result = new Result();
			result.invoiceId = invoicesByOpportunityId.get(request.opportunityId).Id;
			results.add(result);
		}
		return results;
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
	}
}
