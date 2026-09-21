/**
 * Minimal batch test for CreateInvoicesJob.
 */
@IsTest
private class CreateInvoicesJobTest {
	@IsTest
	private static void executeBatchCreatesInvoiceForReadyOpportunity() {
		// Given an opportunity marked Ready with a line item
		Opportunity opp = new Opportunity(
			Name = 'Ready Opp',
			StageName = 'Open',
			CloseDate = System.today(),
			Pricebook2Id = Test.getStandardPricebookId(),
			InvoicedStatus__c = 'Ready'
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

		// When the create invoices batch job runs
		Test.startTest();
		Database.executeBatch(new CreateInvoicesJob());
		Test.stopTest();

		// Then an invoice is created for the ready opportunity
		System.assertEquals(
			1,
			[SELECT COUNT() FROM Invoice__c WHERE Opportunity__c = :opp.Id],
			'Should create one invoice for the Ready opportunity'
		);
	}
}
