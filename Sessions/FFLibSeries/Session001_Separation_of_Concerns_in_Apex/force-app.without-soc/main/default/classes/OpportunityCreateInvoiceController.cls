/**
 * Lightning controller for the Create Invoice record action.
 * Creates invoices directly without a service layer.
 */
public inherited sharing class OpportunityCreateInvoiceController {
	/**
	 * Creates an invoice for a single Opportunity from the Lightning or list action.
	 * @param opportunityId Opportunity Id to invoice. Cannot be null.
	 * @param discountPercentage Optional discount applied before invoicing when greater than zero.
	 * @return Id of the created Invoice__c.
	 */
	@AuraEnabled(cacheable=false)
	public static Id createInvoice(Id opportunityId, Decimal discountPercentage) {
		try {
			Opportunity opportunity = [
				SELECT Id, AccountId, Amount, CloseDate, Description, DiscountType__c, Name,
					(SELECT Id, OpportunityId, Description, Quantity, UnitPrice, ListPrice, PricebookEntryId, SortOrder,
						PricebookEntry.Name, PricebookEntry.Product2Id,
						PricebookEntry.Product2.DiscountingApproved__c,
						PricebookEntry.Pricebook2.Name
					FROM OpportunityLineItems ORDER BY SortOrder, PricebookEntry.Name)
				FROM Opportunity WHERE Id = :opportunityId
			];

			if (discountPercentage != null && discountPercentage > 0) {
				Decimal factor = 1 - (discountPercentage / 100);
				List<SObject> updates = new List<SObject>();
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
				if (!updates.isEmpty()) {
					Database.update(updates);
				}
			}

			Invoice__c invoice = new Invoice__c();
			invoice.Account__c = opportunity.AccountId;
			invoice.Description__c = opportunity.Description;
			invoice.InvoiceDate__c = opportunity.CloseDate;
			invoice.Opportunity__c = opportunity.Id;
			Database.insert(invoice);

			List<InvoiceLine__c> allLines = new List<InvoiceLine__c>();
			for (OpportunityLineItem lineItem : opportunity.OpportunityLineItems) {
				InvoiceLine__c invoiceLineItem = new InvoiceLine__c();
				invoiceLineItem.Invoice__c = invoice.Id;
				invoiceLineItem.Description__c = lineItem.Description;
				invoiceLineItem.Product__c = lineItem.PricebookEntry.Product2Id;
				invoiceLineItem.UnitPrice__c = lineItem.UnitPrice;
				invoiceLineItem.Quantity__c = lineItem.Quantity;
				allLines.add(invoiceLineItem);
			}
			if (!allLines.isEmpty()) {
				Database.insert(allLines);
			}

			return invoice.Id;
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
