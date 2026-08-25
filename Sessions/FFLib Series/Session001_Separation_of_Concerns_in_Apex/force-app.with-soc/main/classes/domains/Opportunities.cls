/**
 * Domain for Opportunity records that supports discounting and invoice generation.
 * Implements {@link InvoicingService.ISupportInvoicing} for polymorphic invoicing.
 */
public virtual inherited sharing class Opportunities implements InvoicingService.ISupportInvoicing {
	@TestVisible
	private static Opportunities mock;

	/**
	 * Factory that wraps the given Opportunity records, or {@link #mock} when tests have set one.
	 * @param recordList Opportunities to manage. Null is treated as an empty list.
	 * @return {@link Opportunities} instance.
	 */
	public static Opportunities newInstance(List<Opportunity> recordList) {
		return mock != null ? mock : new Opportunities(recordList);
	}

	private List<Opportunity> records;

	/**
	 * Creates a domain wrapping the given Opportunity records.
	 * @param sObjectList Opportunities to manage. Null is treated as an empty list.
	 */
	public Opportunities(List<Opportunity> sObjectList) {
		this.records = sObjectList == null ? new List<Opportunity>() : sObjectList;
	}

	/**
	 * Returns the Opportunity records held by this domain.
	 * @return The in-memory Opportunity list; never null.
	 */
	public List<Opportunity> getRecords() {
		return records;
	}

	/**
	 * Builds invoice DTOs from each Opportunity and its line items into the factory.
	 * Invoice date is CloseDate plus 14 days; product comes from the pricebook entry.
	 * @param invoiceFactory Factory that collects invoice headers and lines. Cannot be null.
	 */
	public virtual void generate(InvoicingService.InvoiceFactory invoiceFactory) {
		for (Opportunity opportunity : records) {
			InvoicingService.Invoice invoice = new InvoicingService.Invoice();
			invoice.Account = opportunity.AccountId;
			invoice.Description = opportunity.Description;
			invoice.InvoiceDate = opportunity.CloseDate.addDays(14);
			invoice.Lines = new List<InvoicingService.InvoiceLine>();
			for (OpportunityLineItem lineItem : opportunity.OpportunityLineItems) {
				InvoicingService.InvoiceLine invoiceLineItem = new InvoicingService.InvoiceLine();
				invoiceLineItem.Description = lineItem.Description;
				invoiceLineItem.Product = lineItem.PricebookEntry.Product2Id;
				invoiceLineItem.UnitPrice = lineItem.UnitPrice;
				invoiceLineItem.Quantity = lineItem.Quantity;
				invoice.Lines.add(invoiceLineItem);
			}
			invoiceFactory.add(invoice);
		}
	}

	/**
	 * Applies a percentage discount to Opportunities without lines, or to their line items.
	 * Mutates Amount on in-memory Opportunity records when there are no lines.
	 * Line items are discounted in place via {@link OpportunityLineItems}. Does not perform DML.
	 * Callers that need to persist use {@link #getRecords()} (and nested line items).
	 * @param discountPercentage Discount percent to apply (for example 10 for 10%). Null is treated as zero.
	 */
	public virtual void applyDiscount(Decimal discountPercentage) {
		Decimal factor = calculateDiscountFactor(discountPercentage);
		List<OpportunityLineItem> linesToApplyDiscount = new List<OpportunityLineItem>();

		for (Opportunity opportunity : records) {
			if (opportunity.OpportunityLineItems == null || opportunity.OpportunityLineItems.isEmpty()) {
				opportunity.Amount = opportunity.Amount * factor;
			} else {
				linesToApplyDiscount.addAll(opportunity.OpportunityLineItems);
			}
		}

		OpportunityLineItems.newInstance(linesToApplyDiscount).applyDiscount(this, discountPercentage);
	}

	/**
	 * Converts a discount percentage into a multiplicative factor.
	 * @param discountPercentage Discount percent (for example 10 for 10%). Null is treated as zero.
	 * @return Factor to multiply prices by (for example 0.9 for a 10% discount).
	 */
	public static Decimal calculateDiscountFactor(Decimal discountPercentage) {
		Decimal discountProportion = discountPercentage == null ? 0 : discountPercentage / 100;
		return 1 - discountProportion;
	}

	/**
	 * Collects distinct Account Ids from the Opportunities in this domain.
	 * @return Account Ids present on the records; empty when none have an AccountId.
	 */
	public Set<Id> getAccountIds() {
		Set<Id> result = new Set<Id>();
		for (Opportunity record : records) {
			if (record.AccountId != null) {
				result.add(record.AccountId);
			}
		}
		return result;
	}
}
