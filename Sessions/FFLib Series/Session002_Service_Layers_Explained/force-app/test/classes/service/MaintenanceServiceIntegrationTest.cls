/**
 * Integration tests for {@link MaintenanceService} against real rows.
 */
@IsTest
private class MaintenanceServiceIntegrationTest {
	@TestSetup
	static void setup() {
		TestDataFactory.createUserWithWarehousePermissions();
	}

	@IsTest
	private static void completeJobsRestoresRobot() {
		// Given a run-as user with warehouse permissions
		User runAsUser = TestDataFactory.getRunAsUser();
		TestDataFactory data;
		System.runAs(runAsUser) {
			data = TestDataFactory.createDraftOrder();
		}

		// When the robot is taken offline and the job is then completed
		Id jobId;
		Test.startTest();
		System.runAs(runAsUser) {
			MaintenanceService.newInstance().scheduleService(new Set<Id>{ data.robot.Id });
			jobId = [SELECT Id FROM MaintenanceJob__c WHERE Robot__c = :data.robot.Id].Id;
			MaintenanceService.newInstance().completeJobs(new Set<Id>{ jobId });
		}
		Test.stopTest();

		// Then the job is Completed and the robot is idle with wear cleared
		MaintenanceJob__c job;
		Robot__c robot;
		System.runAs(runAsUser) {
			job = [
				SELECT Status__c, Cost__c
				FROM MaintenanceJob__c
				WHERE Id = :jobId
			];
			robot = [
				SELECT Status__c, WearPercent__c, HoursSinceService__c, Health__c
				FROM Robot__c
				WHERE Id = :data.robot.Id
			];
		}
		System.assertEquals(MaintenanceJobs.STATUS_COMPLETED, job.Status__c, 'Job should complete');
		System.assertEquals(MaintenanceJobs.COST_HEALTHY, job.Cost__c, 'Healthy start costs 100');
		System.assertEquals(Robots.STATUS_IDLE, robot.Status__c, 'Robot should return to idle');
		System.assertEquals(0, robot.WearPercent__c, 'Wear should be cleared');
		System.assertEquals(0, robot.HoursSinceService__c, 'Hours should be cleared');
		System.assertEquals(Robots.HEALTH_HEALTHY, robot.Health__c, 'Health should be Healthy');
	}
}
