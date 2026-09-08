/**
 * Unit tests for {@link DispatchWarehouse} using fflib-apex-mocks.
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs') // unit test: no DML
private class DispatchWarehouseTest {
	@IsTest
	private static void executeResolvesWarehouseName() {
		// Given a stubbed name lookup and dispatch service
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		DispatchService mockService = (DispatchService) mocks.mock(DispatchService.class);
		WarehousesSelector warehouseSelectorMock = (WarehousesSelector) mocks.mock(WarehousesSelector.class);
		Id warehouseId = TestIdGenerator.generate(Warehouse__c.SObjectType);
		Warehouse__c warehouse = new Warehouse__c(Id = warehouseId, Name = 'North Hub');

		mocks.startStubbing();
		mocks.when(warehouseSelectorMock.selectByName(new Set<String>{ 'North Hub' }))
			.thenReturn(new Map<String, Warehouse__c>{ 'North Hub' => warehouse });
		mocks.stopStubbing();

		DispatchWarehouse.Request request = new DispatchWarehouse.Request();
		request.warehouseName = 'North Hub';

		// When the invocable is called with the warehouse name
		List<DispatchWarehouse.Result> results = new DispatchWarehouse(mockService, warehouseSelectorMock)
			.handleExecute(new List<DispatchWarehouse.Request>{ request });

		// Then the service receives the resolved Id and the name is echoed
		((DispatchService) mocks.verify(mockService)).dispatchWarehouses(new Set<Id>{ warehouseId });
		System.assertEquals(1, results.size(), 'One result should be returned');
		System.assertEquals('North Hub', results[0].warehouseName, 'Warehouse name should be returned');
		System.assertEquals(warehouseId, results[0].warehouseId, 'Resolved warehouse Id should be returned');
	}
}
