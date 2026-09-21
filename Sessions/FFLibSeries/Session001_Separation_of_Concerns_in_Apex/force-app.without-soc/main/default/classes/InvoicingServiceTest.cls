/**
 * Integration tests for InvoicingService.generate without Separation of Concerns.
 */
@IsTest
private class InvoicingServiceTest {
	@IsTest
	private static void generateFromOpportunityReturnsInvoiceId() {
		// Given an opportunity with products and line items
		Opportunity opp = new Opportunity(
			Name = 'Opportunity',
			StageName = 'Open',
			CloseDate = System.today(),
			Pricebook2Id = Test.getStandardPricebookId()
		);
		insert opp;

		List<Product2> products = new List<Product2>();
		for (Integer i = 0; i < 5; i++) {
			products.add(new Product2(Name = opp.Name + ' : Product : ' + i, IsActive = true));
		}
		insert products;

		List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
		for (Product2 product : products) {
			pricebookEntries.add(
				new PricebookEntry(
					Product2Id = product.Id,
					UnitPrice = 10,
					IsActive = true,
					UseStandardPrice = false,
					Pricebook2Id = Test.getStandardPricebookId()
				)
			);
		}
		insert pricebookEntries;

		List<OpportunityLineItem> lineItems = new List<OpportunityLineItem>();
		for (PricebookEntry pbe : pricebookEntries) {
			lineItems.add(
				new OpportunityLineItem(
					OpportunityId = opp.Id,
					PricebookEntryId = pbe.Id,
					Quantity = 1,
					TotalPrice = 10
				)
			);
		}
		insert lineItems;

		// When invoices are generated for the opportunity
		Test.startTest();
		Id invoiceId = new InvoicingService().generate(opp.Id);
		Test.stopTest();

		// Then one invoice id is returned
		System.assertNotEquals(null, invoiceId, 'Should generate one invoice');
		Invoice__c inv = [SELECT Description__c, InvoiceDate__c FROM Invoice__c WHERE Id = :invoiceId];
		System.assertEquals(System.today().addDays(14), inv.InvoiceDate__c, 'Invoice date should be CloseDate plus 14 days');
	}

	@IsTest
	private static void generateFromDeveloperWorkItemReturnsInvoiceId() {
		// Given a developer work item under a work order and account
		Account acc = new Account(Name = 'Client');
		insert acc;
		WorkOrder__c wo = new WorkOrder__c(Account__c = acc.Id);
		insert wo;
		DeveloperWorkItem__c wi = new DeveloperWorkItem__c(
			WorkOrder__c = wo.Id,
			CodingHours__c = 10,
			CodeReviewingHours__c = 2,
			TechnicalDesignHours__c = 3
		);
		insert wi;

		// When invoices are generated from the work item
		Test.startTest();
		Id invoiceId = new InvoicingService().generate(wi.Id);
		Test.stopTest();

		// Then one invoice is created for the work order account
		Invoice__c inv = [SELECT Account__c, Description__c FROM Invoice__c WHERE Id = :invoiceId];
		System.assertEquals(acc.Id, inv.Account__c, 'Invoice should be for work order account');
		System.assert(
			inv.Description__c != null && inv.Description__c.contains('Developer'),
			'Description should mention developer work'
		);
	}

	@IsTest
	private static void generateFromTrainingWorkItemReturnsInvoiceId() {
		// Given a training work item under a work order and account
		Account acc = new Account(Name = 'Client');
		insert acc;
		WorkOrder__c wo = new WorkOrder__c(Account__c = acc.Id);
		insert wo;
		TrainingWorkItem__c wi = new TrainingWorkItem__c(
			WorkOrder__c = wo.Id,
			DeliveryHours__c = 8,
			PreparationHours__c = 2
		);
		insert wi;

		// When invoices are generated from the work item
		Test.startTest();
		Id invoiceId = new InvoicingService().generate(wi.Id);
		Test.stopTest();

		// Then one invoice is created for the work order account
		Invoice__c inv = [SELECT Account__c, Description__c FROM Invoice__c WHERE Id = :invoiceId];
		System.assertEquals(acc.Id, inv.Account__c, 'Invoice should be for work order account');
		System.assert(
			inv.Description__c != null && inv.Description__c.contains('Training'),
			'Description should mention training'
		);
	}

	@IsTest
	private static void generateWithUnsupportedSourceTypeThrows() {
		// Given an account id that is not a supported invoicing source
		Account acc = new Account(Name = 'Test');
		insert acc;

		// When invoice generation is attempted for that account
		Test.startTest();
		Boolean threw = false;
		try {
			new InvoicingService().generate(acc.Id);
		} catch (InvoicingService.InvoicingException e) {
			threw = true;
			// Then an exception is raised for the unsupported source type
			System.assert(
				e.getMessage().contains('Invalid source object'),
				'Exception should mention invalid source object'
			);
		}
		Test.stopTest();
		System.assert(threw, 'Expected exception for unsupported source type');
	}
}
