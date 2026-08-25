/**
 * Domain tests for Opportunities.
 */
@IsTest
private class OpportunitiesTest {
	@IsTest
	private static void applyDiscountWithoutLinesMutatesAmount() {
		// Given an opportunity with an amount and no line items
		Opportunity opp = new Opportunity(
			Id = TestIdGenerator.generate(Opportunity.SObjectType),
			Name = 'Test Opportunity',
			StageName = 'Open',
			Amount = 1000,
			CloseDate = System.today()
		);
		Opportunities opps = Opportunities.newInstance(new List<Opportunity>{ opp });

		// When a discount is applied in the domain
		opps.applyDiscount(10);

		// Then the amount is reduced on the wrapped records
		System.assertEquals(1, opps.getRecords().size(), 'Domain should still wrap one opportunity');
		System.assertEquals(900, opp.Amount, 'Amount should be discounted to 900');
		System.assertEquals(900, opps.getRecords()[0].Amount, 'getRecords amount should be 900');
	}

	@IsTest
	private static void applyDiscountNoLinesReducesAmount() {
		// Given a persisted opportunity with an amount and no lines
		Opportunity opp = new Opportunity(
			Name = 'Test',
			Type = 'New Account',
			StageName = 'Open',
			CloseDate = System.today().addMonths(1),
			Amount = 100
		);
		insert opp;

		// When discounts are applied and updates are committed by the caller
		Opportunities opps = Opportunities.newInstance(new List<Opportunity>{ opp });
		opps.applyDiscount(10);
		Database.update(opps.getRecords());

		// Then the stored amount reflects the discount
		Opportunity assertOpp = [SELECT Amount FROM Opportunity WHERE Id = :opp.Id];
		System.assertEquals(90, assertOpp.Amount, 'Discount should reduce amount to 90');
	}

	@IsTest
	private static void insertOppUpdatesAccountDesc() {
		// Given an account and a related opportunity insert
		Account account = new Account(Name = 'Test', Description = null);
		insert account;
		Opportunity opp = new Opportunity(
			Name = 'Test',
			Type = 'Existing Account',
			StageName = 'Open',
			CloseDate = System.today().addMonths(1),
			AccountId = account.Id
		);

		// When the opportunity is inserted
		insert opp;

		// Then the account description records opportunity activity
		Account assertAccount = [SELECT Description FROM Account WHERE Id = :account.Id];
		System.assertEquals(
			'Last Opportunity Raised ' + System.today(),
			assertAccount.Description,
			'Account description should be updated'
		);
	}
}
