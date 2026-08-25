/**
 * Integration test for OpportunitiesService.applyDiscounts.
 */
@IsTest
private class OpportunitiesServiceIntegrationTest {
	@TestSetup
	static void setup() {
		// Given a run-as user with sample app permissions
		TestDataFactory.createUserWithSampleAppPermissions();
	}

	@IsTest
	private static void applyDiscountsAsRunAsUserReducesAmount() {
		// Given an opportunity with priced line items
		Opportunity opp = new Opportunity(
			Name = 'Test',
			StageName = 'Open',
			CloseDate = System.today(),
			Pricebook2Id = Test.getStandardPricebookId()
		);
		insert opp;

		List<Product2> products = new List<Product2>();
		for (Integer i = 0; i < 10; i++) {
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

		List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
		for (PricebookEntry pbe : pricebookEntries) {
			oppLineItems.add(
				new OpportunityLineItem(
					OpportunityId = opp.Id,
					PricebookEntryId = pbe.Id,
					Quantity = 1,
					TotalPrice = 10
				)
			);
		}
		insert oppLineItems;

		System.runAs(TestDataFactory.getRunAsUser()) {
			// When discounts are applied for the opportunity
			Test.startTest();
			OpportunitiesService.newInstance().applyDiscounts(new Set<Id>{ opp.Id }, 10);
			Test.stopTest();
		}

		// Then the opportunity amount reflects the discount
		System.assertEquals(90, [SELECT Amount FROM Opportunity WHERE Id = :opp.Id].Amount);
	}
}
