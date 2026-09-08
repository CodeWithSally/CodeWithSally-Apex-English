/**
 * Unit tests for {@link RobotsTriggerHandler}. No DML.
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs') // unit test: no DML
private class RobotsTriggerHandlerTest {
	@IsTest
	private static void onApplyDefaultsFillsBlanksAndHealth() {
		// Given a robot with wear set and status, hours, and battery blank
		Robot__c robot = new Robot__c(Name = 'Atlas', WearPercent__c = 55);

		// When insert defaults are applied
		new RobotsTriggerHandler(new List<Robot__c>{ robot }).onApplyDefaults();

		// Then blanks are filled and health comes from wear
		System.assertEquals(Robots.STATUS_IDLE, robot.Status__c, 'Blank status should default to Idle');
		System.assertEquals(0, robot.HoursSinceService__c, 'Blank hours should default to 0');
		System.assertEquals(100, robot.BatteryLevel__c, 'Blank battery should default to 100');
		System.assertEquals(55, robot.WearPercent__c, 'Given wear should be kept');
		System.assertEquals(Robots.HEALTH_WARNING, robot.Health__c, '55 wear should be Warning');
	}

	@IsTest
	private static void onBeforeUpdateRecalculatesHealth() {
		// Given an existing healthy robot whose wear has just risen
		Id robotId = TestIdGenerator.generate(Robot__c.SObjectType);
		Robot__c existing = new Robot__c(
			Id = robotId,
			WearPercent__c = 0,
			Health__c = Robots.HEALTH_HEALTHY
		);
		Robot__c updated = new Robot__c(
			Id = robotId,
			WearPercent__c = 81,
			Health__c = Robots.HEALTH_HEALTHY
		);

		// When wear has changed on update
		new RobotsTriggerHandler(new List<Robot__c>{ updated })
			.onBeforeUpdate(new Map<Id, SObject>{ robotId => existing });

		// Then health is recalculated from the new wear
		System.assertEquals(Robots.HEALTH_CRITICAL, updated.Health__c, '81 wear should be Critical');
	}

	@IsTest
	private static void onValidateBlocksIllegalStatus() {
		// Given an offline robot being edited to Working
		Id robotId = TestIdGenerator.generate(Robot__c.SObjectType);
		Robot__c existing = new Robot__c(Id = robotId, Status__c = Robots.STATUS_OFFLINE);
		Robot__c updated = new Robot__c(Id = robotId, Status__c = Robots.STATUS_WORKING);

		// When the status change is validated
		new RobotsTriggerHandler(new List<Robot__c>{ updated })
			.onValidate(new Map<Id, SObject>{ robotId => existing });

		// Then the edit is rejected
		System.assertEquals(true, updated.hasErrors(), 'Offline to Working should be illegal');
	}
}
