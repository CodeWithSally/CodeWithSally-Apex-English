/**
 * Unit tests for OpportunitiesService using Stub API.
 */
@IsTest
private class OpportunitiesServiceTest {
	@TestSetup
	static void setup() {
		// Given a run-as user with sample app permissions
		TestDataFactory.createUserWithSampleAppPermissions();
	}

	@IsTest
	private static void serviceApplyDiscountsUpdatesAmount() {
		System.runAs(TestDataFactory.getRunAsUser()) {
			// Given an opportunity with amount and no lines, returned by a stubbed selector
			Opportunity opp = new Opportunity(
				Name = 'Test Opportunity',
				StageName = 'Open',
				Amount = 1000,
				CloseDate = System.today(),
				Type = 'New Account'
			);
			insert opp;
			List<Opportunity> testOppsList = new List<Opportunity>{
				new Opportunity(
					Id = opp.Id,
					Name = opp.Name,
					StageName = opp.StageName,
					Amount = 1000,
					CloseDate = opp.CloseDate
				)
			};
			Set<Id> testOppsSet = new Set<Id>{ opp.Id };

			SelectorStub selectorProvider = new SelectorStub(testOppsList);
			OpportunitiesSelector.mock = (OpportunitiesSelector) Test.createStub(
				OpportunitiesSelector.class,
				selectorProvider
			);

			// When discounts are applied through the service
			Test.startTest();
			OpportunitiesService.newInstance().applyDiscounts(testOppsSet, 10);
			Test.stopTest();

			// Then the selector is used and the opportunity amount is discounted
			System.assertEquals(1, selectorProvider.selectByIdWithProductsCount, 'Selector should be called');
			Opportunity updated = [SELECT Amount FROM Opportunity WHERE Id = :opp.Id];
			System.assertEquals(900, updated.Amount, 'Amount should be discounted by 10 percent');
		}
	}

	private class SelectorStub implements System.StubProvider {
		private List<Opportunity> results;
		public Integer selectByIdWithProductsCount = 0;

		SelectorStub(List<Opportunity> results) {
			this.results = results;
		}

		public Object handleMethodCall(
			Object stubbedObject,
			String stubbedMethodName,
			Type returnType,
			List<Type> paramTypes,
			List<String> paramNames,
			List<Object> args
		) {
			if (stubbedMethodName == 'selectByIdWithProducts') {
				selectByIdWithProductsCount++;
				return results;
			}
			return null;
		}
	}
}
