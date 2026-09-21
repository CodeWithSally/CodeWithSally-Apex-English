/**
 * Integration test for OpportunityCreateInvoiceController without Separation of Concerns.
 */
@IsTest
private class OpportunityCreateInvoiceTest {
	@IsTest
	private static void createInvoiceLightningActionCreatesInvoiceRecord() {
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

		// When create invoice is invoked from the Lightning record action
		Test.startTest();
		Id invoiceId = OpportunityCreateInvoiceController.createInvoice(opp.Id, null);
		Test.stopTest();

		// Then an invoice is created for the opportunity
		Invoice__c invoice = [SELECT Id, Opportunity__c FROM Invoice__c WHERE Id = :invoiceId];
		System.assertEquals(opp.Id, invoice.Opportunity__c, 'Invoice should belong to the opportunity');
	}
}
