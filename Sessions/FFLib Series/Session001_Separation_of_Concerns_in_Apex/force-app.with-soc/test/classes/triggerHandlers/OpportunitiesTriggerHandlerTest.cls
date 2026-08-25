/**
 * Tests for OpportunitiesTriggerHandler without fflib test harness.
 */
@IsTest
private class OpportunitiesTriggerHandlerTest {
	@TestSetup
	static void setup() {
		// Given a run-as user with sample app permissions
		TestDataFactory.createUserWithSampleAppPermissions();
	}

	@IsTest
	private static void insertExistingAccountNoAccountIdFails() {
		System.runAs(TestDataFactory.getRunAsUser()) {
			// Given an existing-customer opportunity without an account
			Opportunity opp = new Opportunity(
				Name = 'Test',
				Type = 'Existing Account',
				StageName = 'Open',
				CloseDate = System.today()
			);

			// When the opportunity is inserted
			Test.startTest();
			Boolean denied = false;
			try {
				insert opp;
			} catch (DmlException e) {
				denied = true;
				// Then insert fails with the account validation message
				System.assert(
					e.getMessage().contains(
						'You must provide an Account for OpportunityTriggerHandler for existing Customers.'
					),
					'DML error should include validation message'
				);
			}
			Test.stopTest();
			System.assert(denied, 'Expected DmlException for missing AccountId');
		}
	}

	@IsTest
	private static void updateTypeChangeFails() {
		System.runAs(TestDataFactory.getRunAsUser()) {
			// Given a persisted opportunity whose type must not change
			Opportunity opp = new Opportunity(
				Name = 'Test',
				Type = 'New Account',
				StageName = 'Open',
				CloseDate = System.today()
			);
			insert opp;
			opp.Type = 'Existing Account';

			// When the opportunity type is updated
			Test.startTest();
			Boolean denied = false;
			try {
				update opp;
			} catch (DmlException e) {
				denied = true;
				// Then the update fails with the type-change validation message
				System.assert(
					e.getMessage().contains('You cannot change the Opportunity type once it has been created.'),
					'DML error should include type-change validation message'
				);
			}
			Test.stopTest();
			System.assert(denied, 'Expected DmlException when changing Type');
		}
	}

	@IsTest
	private static void insertValidOpportunityPasses() {
		System.runAs(TestDataFactory.getRunAsUser()) {
			// Given a valid new opportunity
			Opportunity opp = new Opportunity(
				Name = 'Test',
				StageName = 'Open',
				CloseDate = System.today()
			);

			// When the opportunity is inserted
			Test.startTest();
			insert opp;
			Test.stopTest();

			// Then insert succeeds
			System.assertNotEquals(null, opp.Id, 'Valid opportunity should insert');
		}
	}
}
