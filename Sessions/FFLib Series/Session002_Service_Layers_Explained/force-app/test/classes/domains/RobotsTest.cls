/**
 * Domain tests for Robots.
 */
@IsTest
private class RobotsTest {
	@IsTest
	private static void healthFromWearUsesThresholds() {
		// Given wear percents at the published thresholds
		// When health is derived from wear
		// Then 0 is Healthy, 50 is Warning, and 81 is Critical
		System.assertEquals(Robots.HEALTH_HEALTHY, Robots.healthFromWear(0), '0 should be healthy');
		System.assertEquals(Robots.HEALTH_WARNING, Robots.healthFromWear(50), '50 should be warning');
		System.assertEquals(Robots.HEALTH_CRITICAL, Robots.healthFromWear(81), '81 should be critical');
	}

	@IsTest
	private static void canAcceptWorkRejectsCriticalAndWorking() {
		// Given a healthy idle robot
		Robot__c idle = newRobot(Robots.STATUS_IDLE, Robots.HEALTH_HEALTHY, 10, 80);
		// When availability is checked
		// Then the robot can accept work
		System.assertEquals(true, Robots.canAcceptWork(idle), 'Healthy idle robot should work');

		// Given the same robot is Critical
		idle.Health__c = Robots.HEALTH_CRITICAL;
		// Then it cannot accept work
		System.assertEquals(false, Robots.canAcceptWork(idle), 'Critical robot should not work');

		// Given the robot is Healthy but already Working
		idle.Health__c = Robots.HEALTH_HEALTHY;
		idle.Status__c = Robots.STATUS_WORKING;
		// Then it cannot accept more work
		System.assertEquals(false, Robots.canAcceptWork(idle), 'Working robot should not accept more work');
	}

	@IsTest
	private static void applyWearIncrementsHoursAndHealth() {
		// Given a healthy robot on a 10-hour service interval
		Robot__c robot = newRobot(Robots.STATUS_IDLE, Robots.HEALTH_HEALTHY, 0, 100);
		robot.HoursSinceService__c = 0;
		robot.Model__r = new RobotModel__c(ServiceIntervalHours__c = 10);
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		fflib_SObjectUnitOfWork uowMock = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);

		// When eight hours of wear are applied
		Robots.newInstance(new List<Robot__c>{ robot }).applyWear(new Map<Id, Decimal>{ robot.Id => 8 }, uowMock);

		// Then hours, wear, and health are updated
		System.assertEquals(8, robot.HoursSinceService__c, 'Hours should increase');
		System.assertEquals(80, robot.WearPercent__c, 'Wear should be 80% of a 10 hour interval');
		System.assertEquals(Robots.HEALTH_WARNING, robot.Health__c, '80 wear is warning');
	}

	@IsTest
	private static void startWorkRequiresCanAccept() {
		// Given a healthy idle robot
		Robot__c robot = newRobot(Robots.STATUS_IDLE, Robots.HEALTH_HEALTHY, 10, 80);
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		fflib_SObjectUnitOfWork uowMock = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);

		// When the robot starts work
		Robots.newInstance(new List<Robot__c>{ robot }).startWork(uowMock);

		// Then the status is Working
		System.assertEquals(Robots.STATUS_WORKING, robot.Status__c, 'Should be working');
	}

	@IsTest
	private static void takeOfflineRequiresIdle() {
		// Given a working robot
		Robot__c robot = newRobot(Robots.STATUS_WORKING, Robots.HEALTH_HEALTHY, 10, 80);
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		fflib_SObjectUnitOfWork uowMock = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);
		Boolean thrown = false;
		try {
			// When it is taken offline for service
			Robots.newInstance(new List<Robot__c>{ robot }).takeOfflineForService(uowMock);
		} catch (Robots.RobotsException e) {
			thrown = true;
		}
		// Then an exception is raised
		System.assertEquals(true, thrown, 'Working robot cannot go into service');
	}

	private static Robot__c newRobot(String status, String health, Decimal wear, Decimal battery) {
		return new Robot__c(
			Id = TestIdGenerator.generate(Robot__c.SObjectType),
			Name = 'Atlas',
			Status__c = status,
			Health__c = health,
			WearPercent__c = wear,
			HoursSinceService__c = 0,
			BatteryLevel__c = battery
		);
	}
}
