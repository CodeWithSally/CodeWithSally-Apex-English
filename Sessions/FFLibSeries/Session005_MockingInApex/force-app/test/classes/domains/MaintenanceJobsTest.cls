/**
 * Domain tests for MaintenanceJobs.
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs') // unit test: in-memory records; no DML
private class MaintenanceJobsTest {
	@IsTest
	private static void completeSetsCostFromHealth() {
		// Given an in-progress job that started at critical health
		MaintenanceJob__c job = new MaintenanceJob__c(
			Id = TestIdGenerator.generate(MaintenanceJob__c.SObjectType),
			Status__c = MaintenanceJobs.STATUS_IN_PROGRESS,
			HealthAtStart__c = Robots.HEALTH_CRITICAL
		);
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		fflib_SObjectUnitOfWork uowMock = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);

		// When the job is completed
		MaintenanceJobs.newInstance(new List<MaintenanceJob__c>{ job }).complete(uowMock);

		// Then the job is Completed and cost is the critical band
		System.assertEquals(MaintenanceJobs.STATUS_COMPLETED, job.Status__c, 'Should complete');
		System.assertEquals(MaintenanceJobs.COST_CRITICAL, job.Cost__c, 'Critical health costs 500');
	}

	@IsTest
	private static void costFromHealthBands() {
		// Given health picklist values
		// When cost is calculated from each health
		// Then each band matches the published cost
		System.assertEquals(MaintenanceJobs.COST_HEALTHY, MaintenanceJobs.costFromHealth(Robots.HEALTH_HEALTHY), 'Healthy');
		System.assertEquals(MaintenanceJobs.COST_WARNING, MaintenanceJobs.costFromHealth(Robots.HEALTH_WARNING), 'Warning');
		System.assertEquals(MaintenanceJobs.COST_CRITICAL, MaintenanceJobs.costFromHealth(Robots.HEALTH_CRITICAL), 'Critical');
	}
}
