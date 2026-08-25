/**
 * Integration test for OpportunityApplyDiscountController without Separation of Concerns.
 */
@IsTest
private class OpportunityDiscountTest {
	@IsTest
	private static void applyDiscountReducesAmountWithNoLines() {
		// Given an opportunity with an amount and no line items
		Opportunity opp = new Opportunity(
			Name = 'Test',
			StageName = 'Open',
			CloseDate = System.today(),
			Amount = 100
		);
		insert opp;

		// When apply discount is invoked from Apex (record action uses LWC + LDS instead)
		Test.startTest();
		OpportunityApplyDiscountController.applyDiscount(opp.Id, 10);
		Test.stopTest();

		// Then the opportunity amount reflects the discount
		System.assertEquals(
			90,
			[SELECT Amount FROM Opportunity WHERE Id = :opp.Id].Amount,
			'Amount should be discounted by 10 percent'
		);
	}
}
