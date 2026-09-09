/**
 * Domain tests for Warehouses.
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs') // unit test: in-memory records; no DML
private class WarehousesTest {
	@IsTest
	private static void assertCanAcceptWorkRejectsClosed() {
		// Given a closed warehouse
		Warehouse__c warehouse = new Warehouse__c(
			Id = TestIdGenerator.generate(Warehouse__c.SObjectType),
			Name = 'North Hub',
			Status__c = Warehouses.STATUS_CLOSED
		);
		Boolean thrown = false;
		try {
			// When the warehouse is asked to accept work
			Warehouses.newInstance(new List<Warehouse__c>{ warehouse })
				.assertCanAcceptWork(new Set<Id>{ warehouse.Id });
		} catch (Warehouses.WarehousesException e) {
			thrown = true;
		}
		// Then an exception is raised
		System.assertEquals(true, thrown, 'Closed warehouse should reject work');
	}
}
