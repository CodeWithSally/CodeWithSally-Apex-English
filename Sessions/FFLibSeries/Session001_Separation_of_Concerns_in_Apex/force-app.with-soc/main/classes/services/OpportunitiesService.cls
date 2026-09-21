/**
 * Service for Opportunity discounting, invoice creation, and invoicing job submission.
 */
public inherited sharing class OpportunitiesService {
	@TestVisible
	private static OpportunitiesService mock;

	/**
	 * Factory that returns this service, or {@link #mock} when tests have set one.
	 * @return {@link OpportunitiesService} instance.
	 */
	public static OpportunitiesService newInstance() {
		return mock != null ? mock : new OpportunitiesService();
	}

	private OpportunitiesSelector selector;

	/**
	 * Creates a service using {@link OpportunitiesSelector#newInstance}.
	 */
	public OpportunitiesService() {
		this.selector = OpportunitiesSelector.newInstance();
	}

	/**
	 * Loads Opportunities with products and applies a percentage discount and commits the updates.
	 * @param opportunityIds Opportunity Ids to discount. Empty set performs no DML.
	 * @param discountPercentage Discount percent to apply (for example 10 for 10%).
	 * @throws OpportunitiesServiceException When update fails or another unexpected error occurs; transaction is rolled back.
	 */
	public void applyDiscounts(Set<Id> opportunityIds, Decimal discountPercentage) {
		applyDiscounts(selector.selectByIdWithProducts(opportunityIds), discountPercentage);
	}

	/**
	 * Applies a percentage discount to the given Opportunities (with products) and commits the updates.
	 * @param opportunitiesWithProducts Opportunities including line items and product discount flags as needed.
	 * @param discountPercentage Discount percent to apply (for example 10 for 10%).
	 * @throws OpportunitiesServiceException When update fails or another unexpected error occurs; transaction is rolled back.
	 */
	public void applyDiscounts(List<Opportunity> opportunitiesWithProducts, Decimal discountPercentage) {
		Savepoint sp = Database.setSavepoint();
		try {
			Opportunities opportunities = Opportunities.newInstance(opportunitiesWithProducts);
			opportunities.applyDiscount(discountPercentage);
			List<SObject> toUpdate = new List<SObject>();
			for (Opportunity opportunity : opportunities.getRecords()) {
				if (opportunity.OpportunityLineItems == null || opportunity.OpportunityLineItems.isEmpty()) {
					toUpdate.add(opportunity);
				} else {
					for (OpportunityLineItem line : opportunity.OpportunityLineItems) {
						toUpdate.add(new OpportunityLineItem(Id = line.Id, UnitPrice = line.UnitPrice));
					}
				}
			}
			if (!toUpdate.isEmpty()) {
				Database.update(toUpdate);
			}
		} catch (DmlException e) {
			Database.rollback(sp);
			throw new OpportunitiesServiceException('Error applying discounts: ' + e.getDmlMessage(0), e);
		} catch (Exception e) {
			Database.rollback(sp);
			throw new OpportunitiesServiceException(e.getMessage(), e);
		}
	}

	/**
	 * Optionally discounts Opportunities, then creates Invoice__c and InvoiceLine__c records.
	 * @param opportunityIds Opportunity Ids to invoice. Empty set returns an empty set.
	 * @param discountPercentage Optional discount applied before invoicing when greater than zero; null or zero skips discounting.
	 * @return Ids of inserted Invoice__c records; empty set when no invoices were created.
	 * @throws OpportunitiesServiceException When DML fails or another unexpected error occurs; transaction is rolled back.
	 */
	public Set<Id> createInvoices(Set<Id> opportunityIds, Decimal discountPercentage) {
		Savepoint sp = Database.setSavepoint();
		try {
			Opportunities opps = Opportunities.newInstance(selector.selectByIdWithProducts(opportunityIds));
			if (discountPercentage != null && discountPercentage > 0) {
				opps.applyDiscount(discountPercentage);
				List<SObject> toUpdate = new List<SObject>();
				for (Opportunity opportunity : opps.getRecords()) {
					if (opportunity.OpportunityLineItems == null || opportunity.OpportunityLineItems.isEmpty()) {
						toUpdate.add(opportunity);
					} else {
						for (OpportunityLineItem line : opportunity.OpportunityLineItems) {
							toUpdate.add(new OpportunityLineItem(Id = line.Id, UnitPrice = line.UnitPrice));
						}
					}
				}
				if (!toUpdate.isEmpty()) {
					Database.update(toUpdate);
				}
			}

			List<Invoice__c> invoices = new List<Invoice__c>();
			List<List<InvoiceLine__c>> linesByInvoice = new List<List<InvoiceLine__c>>();

			for (Opportunity opportunityRecord : opps.getRecords()) {
				Invoice__c invoice = new Invoice__c();
				invoice.Account__c = opportunityRecord.AccountId;
				invoice.Description__c = opportunityRecord.Description;
				invoice.InvoiceDate__c = opportunityRecord.CloseDate;
				invoice.Opportunity__c = opportunityRecord.Id;
				invoices.add(invoice);

				List<InvoiceLine__c> lines = new List<InvoiceLine__c>();
				for (OpportunityLineItem lineItem : opportunityRecord.OpportunityLineItems) {
					InvoiceLine__c invoiceLineItem = new InvoiceLine__c();
					invoiceLineItem.Description__c = lineItem.Description;
					invoiceLineItem.Product__c = lineItem.PricebookEntry.Product2Id;
					invoiceLineItem.UnitPrice__c = lineItem.UnitPrice;
					invoiceLineItem.Quantity__c = lineItem.Quantity;
					lines.add(invoiceLineItem);
				}
				linesByInvoice.add(lines);
			}

			if (!invoices.isEmpty()) {
				Database.insert(invoices);
			}

			List<InvoiceLine__c> allLines = new List<InvoiceLine__c>();
			for (Integer i = 0; i < invoices.size(); i++) {
				for (InvoiceLine__c line : linesByInvoice[i]) {
					line.Invoice__c = invoices[i].Id;
					allLines.add(line);
				}
			}
			if (!allLines.isEmpty()) {
				Database.insert(allLines);
			}

			Set<Id> invoiceIds = new Set<Id>();
			for (Invoice__c invoice : invoices) {
				invoiceIds.add(invoice.Id);
			}
			return invoiceIds;
		} catch (DmlException e) {
			Database.rollback(sp);
			throw new OpportunitiesServiceException('Error creating invoices: ' + e.getDmlMessage(0), e);
		} catch (Exception e) {
			Database.rollback(sp);
			throw new OpportunitiesServiceException(e.getMessage(), e);
		}
	}

	/**
	 * Submits {@link CreateInvoicesJob} as a Batch Apex job.
	 * @return Async Apex job Id returned by {@code Database.executeBatch}.
	 */
	public Id submitInvoicingJob() {
		return Database.executeBatch(new CreateInvoicesJob());
	}

	/**
	 * Represents an exception thrown by {@link OpportunitiesService} operations.
	 */
	public class OpportunitiesServiceException extends Exception {
	}
}
