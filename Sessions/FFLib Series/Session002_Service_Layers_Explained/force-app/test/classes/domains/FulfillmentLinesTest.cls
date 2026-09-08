/**
 * Domain tests for FulfillmentLines.
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs') // unit test: in-memory records; no DML
private class FulfillmentLinesTest {
	@IsTest
	private static void assignAndComplete() {
		// Given a pending line and a robot id
		FulfillmentLine__c line = new FulfillmentLine__c(
			Id = TestIdGenerator.generate(FulfillmentLine__c.SObjectType),
			Status__c = FulfillmentLines.STATUS_PENDING,
			Quantity__c = 10,
			WeightKg__c = 10
		);
		Id robotId = TestIdGenerator.generate(Robot__c.SObjectType);
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		fflib_SObjectUnitOfWork uowMock = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);
		FulfillmentLines lines = FulfillmentLines.newInstance(new List<FulfillmentLine__c>{ line });

		// When the line is assigned
		lines.assign(new Map<Id, Id>{ line.Id => robotId }, uowMock);
		// Then the line is Assigned to that robot
		System.assertEquals(FulfillmentLines.STATUS_ASSIGNED, line.Status__c, 'Should be assigned');
		System.assertEquals(robotId, line.AssignedRobot__c, 'Robot should be set');

		// When the line is completed
		lines.complete(uowMock);
		// Then the line is Complete
		System.assertEquals(FulfillmentLines.STATUS_COMPLETE, line.Status__c, 'Should be complete');
	}

	@IsTest
	private static void estimatedHoursMinimumIsOne() {
		// Given a line whose quantity times weight is under 100
		FulfillmentLine__c line = new FulfillmentLine__c(Quantity__c = 1, WeightKg__c = 1);
		// When estimated hours are calculated
		Decimal hours = FulfillmentLines.estimatedHours(line);
		// Then the result is the one-hour minimum
		System.assertEquals(1, hours, 'Minimum hours is 1');
	}
}
