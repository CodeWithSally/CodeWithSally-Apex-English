/**
 * Unit tests for the Session 004 {@link RobotsSelector} methods.
 * Queries get empty conditions only: these test our logic, not Salesforce's SOQL execution.
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs') // unit test: empty conditions, no DML
private class RobotsSelectorTest {
	@IsTest
	private static void newMethodsReturnNothingForEmptyIds() {
		// Given an empty Id set
		Set<Id> noIds = new Set<Id>();
		RobotsSelector selector = RobotsSelector.newInstance();

		// When each new method is called with it
		Test.startTest();
		Integer byIdWithAccess = selector.selectById(noIds, fflib_SObjectSelector.DataAccess.SYSTEM_MODE).size();
		Integer byIdWithFields = selector
			.selectById(noIds, new Set<Schema.SObjectField>{ Robot__c.OwnerId })
			.size();
		Integer byIdWithOwner = selector.selectByIdWithOwner(noIds).size();
		Integer pagedRobots = selector.selectByWarehouseAsPaginationCursor(noIds).getNumRecords();
		Test.stopTest();

		// Then each returns nothing
		Assert.areEqual(0, byIdWithAccess, 'selectById with data access');
		Assert.areEqual(0, byIdWithFields, 'selectById with additional fields');
		Assert.areEqual(0, byIdWithOwner, 'selectByIdWithOwner');
		Assert.areEqual(0, pagedRobots, 'selectByWarehouseAsPaginationCursor');
	}

	@IsTest
	private static void constructorTakesTheNamedDataAccess() {
		// When selectors are composed with and without a named data access
		Test.startTest();
		fflib_SObjectSelector.DataAccess namedAccess = new RobotsSelector(fflib_SObjectSelector.DataAccess.SYSTEM_MODE)
			.getDataAccess();
		fflib_SObjectSelector.DataAccess byDefault = RobotsSelector.newInstance().getDataAccess();
		Test.stopTest();

		// Then elevation is named, and the default stays user mode
		Assert.areEqual(fflib_SObjectSelector.DataAccess.SYSTEM_MODE, namedAccess, 'Named data access');
		Assert.areEqual(fflib_SObjectSelector.DataAccess.USER_MODE, byDefault, 'Default data access');
	}
}
