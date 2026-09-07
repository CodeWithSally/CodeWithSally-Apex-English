/**
 * Unit tests for MaintenanceService using fflib-apex-mocks. No DML.
 */
@IsTest
private class MaintenanceServiceTest {
	@IsTest
	private static void scheduleServiceTakesRobotsOfflineAndRegistersJob() {
		// Given an idle robot with no open job and a stubbed selector
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		fflib_SObjectUnitOfWork uowMock = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);
		MaintenanceJobsSelector jobSelectorMock = (MaintenanceJobsSelector) mocks.mock(MaintenanceJobsSelector.class);
		Robots robotsMock = (Robots) mocks.mock(Robots.class);

		Id robotId = TestIdGenerator.generate(Robot__c.SObjectType);
		Robot__c robot = new Robot__c(
			Id = robotId,
			Name = 'Atlas',
			Status__c = Robots.STATUS_IDLE,
			Health__c = Robots.HEALTH_WARNING
		);
		Set<Id> robotIds = new Set<Id>{ robotId };

		mocks.startStubbing();
		mocks.when(jobSelectorMock.selectOpenByRobot(robotIds)).thenReturn(new List<MaintenanceJob__c>());
		mocks.stopStubbing();

		MaintenanceJobsSelector.mock = jobSelectorMock;
		Robots.mock = robotsMock;

		// When service is scheduled on the outer Unit of Work
		MaintenanceService.newInstance().scheduleService(new List<Robot__c>{ robot }, uowMock);

		// Then the robot is taken offline and a job is registered
		((Robots) mocks.verify(robotsMock)).takeOfflineForService(uowMock);
		((fflib_SObjectUnitOfWork) mocks.verify(uowMock)).registerNew(
			(MaintenanceJob__c) fflib_Match.anySObject()
		);
	}

	@IsTest
	private static void startJobsStampsHealthAndCommits() {
		// Given a scheduled job whose related robot is at Warning
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		fflib_SObjectUnitOfWork uowMock = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);
		MaintenanceJobsSelector jobSelectorMock = (MaintenanceJobsSelector) mocks.mock(
			MaintenanceJobsSelector.class
		);

		Id jobId = TestIdGenerator.generate(MaintenanceJob__c.SObjectType);
		Id robotId = TestIdGenerator.generate(Robot__c.SObjectType);
		MaintenanceJob__c job = (MaintenanceJob__c) JSON.deserialize(
			'{"attributes":{"type":"MaintenanceJob__c"},"Id":"'
				+ jobId
				+ '","Name":"MJ-1","Status__c":"Scheduled","Robot__c":"'
				+ robotId
				+ '","Robot__r":{"attributes":{"type":"Robot__c"},"Id":"'
				+ robotId
				+ '","Health__c":"Warning"}}',
			MaintenanceJob__c.class
		);
		Set<Id> jobIds = new Set<Id>{ jobId };

		mocks.startStubbing();
		mocks.when(jobSelectorMock.selectByIdWithRobot(jobIds))
			.thenReturn(new List<MaintenanceJob__c>{ job });
		mocks.stopStubbing();

		UnitOfWork.mock = uowMock;
		MaintenanceJobsSelector.mock = jobSelectorMock;

		// When the job is started
		MaintenanceService.newInstance().startJobs(jobIds);

		// Then health is stamped, the job is In Progress, and the UoW commits
		System.assertEquals(MaintenanceJobs.STATUS_IN_PROGRESS, job.Status__c, 'Job should start');
		System.assertEquals(Robots.HEALTH_WARNING, job.HealthAtStart__c, 'Health at start from the robot');
		((fflib_SObjectUnitOfWork) mocks.verify(uowMock, 1)).commitWork();
	}
}
