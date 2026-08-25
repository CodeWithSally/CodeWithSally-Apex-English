/**
 * Unit tests for OpportunityApplyDiscountController using Stub API.
 */
@IsTest
private class OpportunityApplyDiscountControllerTest {
	@TestSetup
	static void setup() {
		// Given a run-as user with sample app permissions
		TestDataFactory.createUserWithSampleAppPermissions();
	}

	@IsTest
	private static void applyDiscountCallsService() {
		System.runAs(TestDataFactory.getRunAsUser()) {
			// Given a stubbed opportunities service
			Id opportunityId = TestIdGenerator.generate(Opportunity.SObjectType);
			ServiceStub provider = new ServiceStub();
			OpportunitiesService.mock = (OpportunitiesService) Test.createStub(
				OpportunitiesService.class,
				provider
			);

			// When apply discount is invoked from the Lightning action
			Test.startTest();
			OpportunityApplyDiscountController.applyDiscount(opportunityId, 10);
			Test.stopTest();

			// Then the service is called with the opportunity id and discount percentage
			System.assertEquals(1, provider.applyDiscountsCount, 'Service applyDiscounts should be called once');
			System.assertEquals(
				opportunityId,
				provider.lastOpportunityIds.iterator().next(),
				'Opportunity Id should match'
			);
			System.assertEquals(10, provider.lastDiscountPercentage, 'Discount percentage should be 10');
		}
	}

	private class ServiceStub implements System.StubProvider {
		public Integer applyDiscountsCount = 0;
		public Set<Id> lastOpportunityIds;
		public Decimal lastDiscountPercentage;

		public Object handleMethodCall(
			Object stubbedObject,
			String stubbedMethodName,
			Type returnType,
			List<Type> paramTypes,
			List<String> paramNames,
			List<Object> args
		) {
			if (stubbedMethodName == 'applyDiscounts') {
				applyDiscountsCount++;
				lastOpportunityIds = (Set<Id>) args[0];
				lastDiscountPercentage = (Decimal) args[1];
				return null;
			}
			return null;
		}
	}
}
