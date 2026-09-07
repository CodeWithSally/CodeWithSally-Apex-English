/**
 * Integration tests for {@link RobotsTriggerHandler} against real Robot rows.
 */
@IsTest
private class RobotsTriggerHandlerIntegrationTest {
	@IsTest
	private static void insertAppliesDefaultsAndHealthFromWear() {
		// Given a warehouse and model, and a robot with only name and wear
		TestDataFactory data = TestDataFactory.createDraftOrder();
		Robot__c robot = new Robot__c(
			Name = 'Bolt',
			Warehouse__c = data.warehouse.Id,
			Model__c = data.model.Id,
			WearPercent__c = 55
		);

		// When the robot is inserted
		insert robot;

		// Then the trigger fills blanks and stamps health from wear
		robot = [
			SELECT Status__c, HoursSinceService__c, BatteryLevel__c, WearPercent__c, Health__c
			FROM Robot__c
			WHERE Id = :robot.Id
		];
		System.assertEquals(Robots.STATUS_IDLE, robot.Status__c, 'Blank status should default to Idle');
		System.assertEquals(0, robot.HoursSinceService__c, 'Blank hours should default to 0');
		System.assertEquals(100, robot.BatteryLevel__c, 'Blank battery should default to 100');
		System.assertEquals(55, robot.WearPercent__c, 'Given wear should be kept');
		System.assertEquals(Robots.HEALTH_WARNING, robot.Health__c, '55 wear should be Warning');
	}

	@IsTest
	private static void updateRecalculatesHealthAndRejectsIllegalStatus() {
		// Given an idle robot inserted through the factory
		TestDataFactory data = TestDataFactory.createDraftOrder();

		// When wear is raised on update
		update new Robot__c(Id = data.robot.Id, WearPercent__c = 81);
		Robot__c robot = [SELECT Health__c, Status__c FROM Robot__c WHERE Id = :data.robot.Id];
		System.assertEquals(Robots.HEALTH_CRITICAL, robot.Health__c, '81 wear should be Critical');

		// When a legal status edit is made
		update new Robot__c(Id = data.robot.Id, Status__c = Robots.STATUS_OFFLINE);
		robot = [SELECT Status__c FROM Robot__c WHERE Id = :data.robot.Id];
		System.assertEquals(Robots.STATUS_OFFLINE, robot.Status__c, 'Idle to Offline should succeed');

		// When an illegal status edit is made
		Boolean thrown = false;
		try {
			update new Robot__c(Id = data.robot.Id, Status__c = Robots.STATUS_WORKING);
		} catch (DmlException e) {
			thrown = e.getDmlMessage(0).contains('Illegal status change');
		}
		System.assertEquals(true, thrown, 'Offline to Working should fail');
	}
}
