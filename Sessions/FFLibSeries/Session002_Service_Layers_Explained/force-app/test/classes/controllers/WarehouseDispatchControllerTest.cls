/**
 * Unit tests for {@link WarehouseDispatchController} using fflib-apex-mocks.
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts, PMD.ApexUnitTestClassShouldHaveRunAs') // unit test: ApexMocks verify is the assertion; no DML
private class WarehouseDispatchControllerTest {
	@IsTest
	private static void dispatchWarehouseCallsService() {
		// Given a stubbed dispatch service and a warehouse id
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		DispatchService mockService = (DispatchService) mocks.mock(DispatchService.class);
		Id warehouseId = TestIdGenerator.generate(Warehouse__c.SObjectType);
		// When dispatch is invoked from the Lightning action
		new WarehouseDispatchController(mockService).handleDispatchWarehouse(warehouseId);

		// Then the service is called with the warehouse id
		((DispatchService) mocks.verify(mockService)).dispatchWarehouses(new Set<Id>{ warehouseId });
	}
}
