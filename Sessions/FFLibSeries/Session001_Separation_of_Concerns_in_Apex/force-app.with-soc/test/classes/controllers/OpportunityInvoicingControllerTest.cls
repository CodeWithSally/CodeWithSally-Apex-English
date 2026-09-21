/**
 * Unit tests for OpportunityInvoicingController using Stub API.
 */
@IsTest
private class OpportunityInvoicingControllerTest {
	@TestSetup
	static void setup() {
		// Given a run-as user with sample app permissions
		TestDataFactory.createUserWithSampleAppPermissions();
	}

	@IsTest
	private static void startJobCallsServiceAndReturnsJobId() {
		System.runAs(TestDataFactory.getRunAsUser()) {
			// Given a stubbed opportunities service that returns a job id
			Id jobId = TestIdGenerator.generate(AsyncApexJob.SObjectType);
			ServiceStub provider = new ServiceStub();
			provider.jobId = jobId;
			OpportunitiesService.mock = (OpportunitiesService) Test.createStub(
				OpportunitiesService.class,
				provider
			);

			// When start job is invoked from the Lightning action
			Test.startTest();
			Id resultId = OpportunityInvoicingController.startJob();
			Test.stopTest();

			// Then the service is called and the job id is returned
			System.assertEquals(1, provider.submitInvoicingJobCount, 'Service submitInvoicingJob should be called once');
			System.assertEquals(jobId, resultId, 'Job Id should be returned');
		}
	}

	private class ServiceStub implements System.StubProvider {
		public Integer submitInvoicingJobCount = 0;
		public Id jobId;

		public Object handleMethodCall(
			Object stubbedObject,
			String stubbedMethodName,
			Type returnType,
			List<Type> paramTypes,
			List<String> paramNames,
			List<Object> args
		) {
			if (stubbedMethodName == 'submitInvoicingJob') {
				submitInvoicingJobCount++;
				return jobId;
			}
			return null;
		}
	}
}
