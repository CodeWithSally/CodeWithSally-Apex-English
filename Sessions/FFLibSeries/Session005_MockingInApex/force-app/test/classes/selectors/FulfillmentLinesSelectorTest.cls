/**
 * Unit tests for the Session 004 {@link FulfillmentLinesSelector} methods.
 * Queries get empty conditions only: these test our logic, not Salesforce's SOQL execution.
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs') // unit test: empty conditions, no DML
private class FulfillmentLinesSelectorTest {
	@IsTest
	private static void selectPendingByWarehouseAsCursorIsEmptyForEmptyIds() {
		// When the pending-lines cursor is opened for no warehouses
		Test.startTest();
		Integer pendingLines = FulfillmentLinesSelector.newInstance()
			.selectPendingByWarehouseAsCursor(new Set<Id>())
			.getNumRecords();
		Test.stopTest();

		// Then it holds no lines
		Assert.areEqual(0, pendingLines, 'No pending lines');
	}
}
