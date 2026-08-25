/**
 * Domain tests for Accounts.
 */
@IsTest
private class AccountsTest {
	@IsTest
	static void updateOpportunityActivitySetsDescription() {
		// Given accounts without an opportunity activity description
		List<Account> accountRecords = new List<Account>{
			new Account(Name = 'A'),
			new Account(Name = 'B'),
			new Account(Name = 'C')
		};
		Accounts domain = Accounts.newInstance(accountRecords);

		// When opportunity activity is updated on the domain
		domain.updateOpportunityActivity();

		// Then each account description records today's opportunity activity
		String expectedDescription = Accounts.OPPORTUNITY_RAISED_DESCRIPTION + ' ' + System.today();
		for (Account account : accountRecords) {
			System.assertEquals(
				expectedDescription,
				account.Description,
				'Description should include opportunity raised text'
			);
		}
	}
}
