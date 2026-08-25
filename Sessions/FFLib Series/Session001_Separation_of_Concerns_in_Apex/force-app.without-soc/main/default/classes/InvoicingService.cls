/**
 * Thin invoicing API that generates a single Invoice__c from a supported source record Id.
 * No production call sites; kept for polymorphic invoicing demonstration without a domain layer.
 */
public inherited sharing class InvoicingService {
	/**
	 * Generates and inserts an Invoice__c (and lines) for the given source record.
	 * @param sourceRecordId Id of Opportunity, DeveloperWorkItem__c, or TrainingWorkItem__c.
	 * @return Id of the inserted Invoice__c.
	 * @throws InvoicingException When the source type is unsupported or required account data is missing.
	 */
	public Id generate(Id sourceRecordId) {
		Schema.SObjectType sourceType = sourceRecordId.getSObjectType();

		if (sourceType == Opportunity.SObjectType) {
			return generateFromOpportunity(sourceRecordId);
		}
		if (sourceType == DeveloperWorkItem__c.SObjectType) {
			return generateFromDeveloperWorkItem(sourceRecordId);
		}
		if (sourceType == TrainingWorkItem__c.SObjectType) {
			return generateFromTrainingWorkItem(sourceRecordId);
		}
		throw new InvoicingException('Invalid source object for generating invoices.');
	}

	private Id generateFromOpportunity(Id opportunityId) {
		Set<Id> idSet = new Set<Id>{ opportunityId };
		List<Opportunity> opportunities = [
			SELECT Id, AccountId, Amount, CloseDate, Description, DiscountType__c, Name,
				(SELECT Id, OpportunityId, Description, Quantity, UnitPrice, ListPrice, PricebookEntryId, SortOrder,
					PricebookEntry.Name, PricebookEntry.Product2Id,
					PricebookEntry.Product2.DiscountingApproved__c,
					PricebookEntry.Pricebook2.Name
				FROM OpportunityLineItems ORDER BY SortOrder, PricebookEntry.Name)
			FROM Opportunity WHERE Id IN :idSet
		];
		Opportunity opportunity = opportunities[0];

		Invoice__c invoice = new Invoice__c();
		invoice.Account__c = opportunity.AccountId;
		invoice.Description__c = opportunity.Description;
		invoice.InvoiceDate__c = opportunity.CloseDate.addDays(14);

		List<InvoiceLine__c> lines = new List<InvoiceLine__c>();
		for (OpportunityLineItem lineItem : opportunity.OpportunityLineItems) {
			InvoiceLine__c invoiceLineItem = new InvoiceLine__c();
			invoiceLineItem.Description__c = lineItem.Description;
			invoiceLineItem.Product__c = lineItem.PricebookEntry.Product2Id;
			invoiceLineItem.UnitPrice__c = lineItem.UnitPrice;
			invoiceLineItem.Quantity__c = lineItem.Quantity;
			lines.add(invoiceLineItem);
		}

		Database.insert(invoice);
		for (InvoiceLine__c line : lines) {
			line.Invoice__c = invoice.Id;
		}
		if (!lines.isEmpty()) {
			Database.insert(lines);
		}
		return invoice.Id;
	}

	private Id generateFromDeveloperWorkItem(Id workItemId) {
		DeveloperWorkItem__c wi = [
			SELECT Id, Name, DeveloperCost__c, WorkOrder__r.Account__c
			FROM DeveloperWorkItem__c
			WHERE Id = :workItemId
		];
		Id accountId = wi.WorkOrder__r != null ? wi.WorkOrder__r.Account__c : null;
		if (accountId == null) {
			throw new InvoicingException('Developer work item has no related Work Order account.');
		}

		Invoice__c invoice = new Invoice__c();
		invoice.Account__c = accountId;
		invoice.Description__c = 'Developer work: ' + (wi.Name != null ? wi.Name : 'Work Item');
		invoice.InvoiceDate__c = Date.today();
		Database.insert(invoice);

		InvoiceLine__c line = new InvoiceLine__c();
		line.Invoice__c = invoice.Id;
		line.Description__c = 'Developer consultancy';
		line.UnitPrice__c = wi.DeveloperCost__c != null ? wi.DeveloperCost__c : 0;
		line.Quantity__c = 1;
		Database.insert(line);
		return invoice.Id;
	}

	private Id generateFromTrainingWorkItem(Id workItemId) {
		TrainingWorkItem__c wi = [
			SELECT Id, Name, TrainingCost__c, WorkOrder__r.Account__c
			FROM TrainingWorkItem__c
			WHERE Id = :workItemId
		];
		Id accountId = wi.WorkOrder__r != null ? wi.WorkOrder__r.Account__c : null;
		if (accountId == null) {
			throw new InvoicingException('Training work item has no related Work Order account.');
		}

		Invoice__c invoice = new Invoice__c();
		invoice.Account__c = accountId;
		invoice.Description__c = 'Training: ' + (wi.Name != null ? wi.Name : 'Work Item');
		invoice.InvoiceDate__c = Date.today();
		Database.insert(invoice);

		InvoiceLine__c line = new InvoiceLine__c();
		line.Invoice__c = invoice.Id;
		line.Description__c = 'Training delivery';
		line.UnitPrice__c = wi.TrainingCost__c != null ? wi.TrainingCost__c : 0;
		line.Quantity__c = 1;
		Database.insert(line);
		return invoice.Id;
	}

	/**
	 * Represents an exception thrown by {@link InvoicingService} operations.
	 */
	public class InvoicingException extends Exception {
	}
}
