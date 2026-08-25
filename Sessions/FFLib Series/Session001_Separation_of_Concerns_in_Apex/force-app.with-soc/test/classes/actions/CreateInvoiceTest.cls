/**
 * Unit tests for {@link CreateInvoice} using Stub API.
 */
@IsTest
private class CreateInvoiceTest {
	@TestSetup
	static void setup() {
		// Given a run-as user with sample app permissions
		TestDataFactory.createUserWithSampleAppPermissions();
	}

	@IsTest
	private static void executeCallsServiceAndReturnsInvoiceId() {
		System.runAs(TestDataFactory.getRunAsUser()) {
			// Given a stubbed opportunities service that returns an invoice id
			Id opportunityId = TestIdGenerator.generate(Opportunity.SObjectType);
			Id invoiceId = TestIdGenerator.generate(Invoice__c.SObjectType);
			ServiceStub provider = new ServiceStub();
			provider.invoiceIds = new Set<Id>{ invoiceId };
			OpportunitiesService.mock = (OpportunitiesService) Test.createStub(
				OpportunitiesService.class,
				provider
			);
			CreateInvoice.testInvoiceName = 'INV-00000001';
			CreateInvoice.Request request = new CreateInvoice.Request();
			request.opportunityId = opportunityId;
			request.discountPercentage = 10;

			// When the invocable action is executed
			Test.startTest();
			List<CreateInvoice.Result> results = CreateInvoice.execute(
				new List<CreateInvoice.Request>{ request }
			);
			Test.stopTest();

			// Then the service is called and the invoice id is returned
			System.assertEquals(1, provider.createInvoicesCount, 'Service createInvoices should be called once');
			System.assertEquals(
				opportunityId,
				provider.lastOpportunityIds.iterator().next(),
				'Opportunity Id should match'
			);
			System.assertEquals(10, provider.lastDiscountPercentage, 'Discount percentage should be 10');
			System.assertEquals(1, results.size(), 'One result should be returned');
			System.assertEquals(invoiceId, results[0].invoiceId, 'Created invoice Id should be returned');
			System.assertEquals(
				'INV-00000001',
				results[0].invoiceName,
				'Created invoice Name should be returned'
			);
		}
	}

	private class ServiceStub implements System.StubProvider {
		public Integer createInvoicesCount = 0;
		public Set<Id> lastOpportunityIds;
		public Decimal lastDiscountPercentage;
		public Set<Id> invoiceIds;

		public Object handleMethodCall(
			Object stubbedObject,
			String stubbedMethodName,
			Type returnType,
			List<Type> paramTypes,
			List<String> paramNames,
			List<Object> args
		) {
			if (stubbedMethodName == 'createInvoices') {
				createInvoicesCount++;
				lastOpportunityIds = (Set<Id>) args[0];
				lastDiscountPercentage = (Decimal) args[1];
				return invoiceIds;
			}
			return null;
		}
	}
}
