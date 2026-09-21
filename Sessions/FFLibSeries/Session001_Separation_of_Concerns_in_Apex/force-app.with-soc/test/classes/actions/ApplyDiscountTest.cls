/**
 * Unit tests for {@link ApplyDiscount} using Stub API.
 */
@IsTest
private class ApplyDiscountTest {
	@TestSetup
	static void setup() {
		// Given a run-as user with sample app permissions
		TestDataFactory.createUserWithSampleAppPermissions();
	}

	@IsTest
	private static void executeCallsServiceAndReturnsOpportunityId() {
		System.runAs(TestDataFactory.getRunAsUser()) {
			// Given a stubbed opportunities service
			Id opportunityId = TestIdGenerator.generate(Opportunity.SObjectType);
			ServiceStub provider = new ServiceStub();
			OpportunitiesService.mock = (OpportunitiesService) Test.createStub(
				OpportunitiesService.class,
				provider
			);
			ApplyDiscount.Request request = new ApplyDiscount.Request();
			request.opportunityId = opportunityId;
			request.discountPercentage = 10;

			// When the invocable action is executed
			Test.startTest();
			List<ApplyDiscount.Result> results = ApplyDiscount.execute(
				new List<ApplyDiscount.Request>{ request }
			);
			Test.stopTest();

			// Then the service is called and the opportunity id is returned
			System.assertEquals(1, provider.applyDiscountsCount, 'Service applyDiscounts should be called once');
			System.assertEquals(
				opportunityId,
				provider.lastOpportunityIds.iterator().next(),
				'Opportunity Id should match'
			);
			System.assertEquals(10, provider.lastDiscountPercentage, 'Discount percentage should be 10');
			System.assertEquals(1, results.size(), 'One result should be returned');
			System.assertEquals(opportunityId, results[0].opportunityId, 'Opportunity Id should be returned');
			System.assertEquals(10, results[0].discountPercentage, 'Applied discount should be returned');
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
