/**
 * Tests for QuickOpportunityWizardController Lightning action methods.
 */
@IsTest
private class QuickOpportunityWizardControllerTest {
	@IsTest
	private static void getWizardDataReturnsAccountNameAndNoLines() {
		// Given an account with no opportunity products
		Account account = new Account(Name = 'Wizard Account');
		insert account;

		// When wizard data is loaded
		Test.startTest();
		QuickOpportunityWizardController.WizardState viewState = QuickOpportunityWizardController.getWizardData(
			account.Id
		);
		Test.stopTest();

		// Then the opportunity name defaults to the account name
		System.assertEquals('Wizard Account', viewState.opportunityName, 'Opportunity name should default to Account name');
		System.assertEquals(0, viewState.selectLineItemList.size(), 'No recent line items should be returned');
	}

	@IsTest
	private static void createOpportunityInsertsOpportunityWithoutLines() {
		// Given an account and wizard field values with no selected lines
		Account account = new Account(Name = 'Wizard Account');
		insert account;

		// When the wizard creates an opportunity
		Test.startTest();
		Id opportunityId = QuickOpportunityWizardController.createOpportunity(
			account.Id,
			'New Opportunity',
			'Open',
			System.today(),
			new List<QuickOpportunityWizardController.WizardLineItem>()
		);
		Test.stopTest();

		// Then the opportunity is inserted against the account
		Opportunity created = [SELECT Name, AccountId, StageName FROM Opportunity WHERE Id = :opportunityId];
		System.assertEquals('New Opportunity', created.Name, 'Opportunity name should match');
		System.assertEquals(account.Id, created.AccountId, 'Opportunity should belong to the account');
		System.assertEquals('Open', created.StageName, 'Stage should match');
	}
}
