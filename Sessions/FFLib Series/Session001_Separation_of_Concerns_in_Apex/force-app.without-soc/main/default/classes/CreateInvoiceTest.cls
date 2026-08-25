/**
 * Integration test for {@link CreateInvoice} without Separation of Concerns.
 */
@IsTest
private class CreateInvoiceTest {
	@IsTest
	private static void executeCreatesInvoiceRecord() {
		// Given an opportunity with products and line items
		Opportunity opp = new Opportunity(
			Name = 'Opportunity',
			StageName = 'Open',
			CloseDate = System.today(),
			Pricebook2Id = Test.getStandardPricebookId()
		);
		insert opp;

		Product2 product = new Product2(Name = 'Product', IsActive = true);
		insert product;

		PricebookEntry pbe = new PricebookEntry(
			Product2Id = product.Id,
			UnitPrice = 10,
			IsActive = true,
			UseStandardPrice = false,
			Pricebook2Id = Test.getStandardPricebookId()
		);
		insert pbe;

		insert new OpportunityLineItem(
			OpportunityId = opp.Id,
			PricebookEntryId = pbe.Id,
			Quantity = 1,
			TotalPrice = 10
		);

		CreateInvoice.Request request = new CreateInvoice.Request();
		request.opportunityId = opp.Id;
		request.discountPercentage = 10;

		// When the invocable action is executed
		Test.startTest();
		List<CreateInvoice.Result> results = CreateInvoice.execute(
			new List<CreateInvoice.Request>{ request }
		);
		Test.stopTest();

		// Then an invoice is created with a discounted invoice line
		System.assertEquals(1, results.size(), 'One result should be returned');
		Invoice__c invoice = [SELECT Id, Opportunity__c FROM Invoice__c WHERE Id = :results[0].invoiceId];
		System.assertEquals(opp.Id, invoice.Opportunity__c, 'Invoice should belong to the opportunity');
		System.assertEquals(
			9,
			[SELECT UnitPrice__c FROM InvoiceLine__c WHERE Invoice__c = :invoice.Id].UnitPrice__c,
			'Invoice line unit price should be discounted by 10 percent'
		);
	}
}
