/**
 * Unit tests for {@link DispatchWarehouse} using fflib-apex-mocks.
 */
@IsTest
private class DispatchWarehouseTest {
	@IsTest
	private static void executeCallsServiceAndReturnsWarehouseId() {
		// Given a stubbed dispatch service and a warehouse id
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		DispatchService mockService = (DispatchService) mocks.mock(DispatchService.class);
		Id warehouseId = TestIdGenerator.generate(Warehouse__c.SObjectType);
		DispatchService.mock = mockService;
		DispatchWarehouse.Request request = new DispatchWarehouse.Request();
		request.warehouseId = warehouseId;

		// When the invocable action is executed
		List<DispatchWarehouse.Result> results = DispatchWarehouse.execute(
			new List<DispatchWarehouse.Request>{ request }
		);

		// Then the service is called and the warehouse id is returned
		((DispatchService) mocks.verify(mockService)).dispatchWarehouses(new Set<Id>{ warehouseId });
		System.assertEquals(1, results.size(), 'One result should be returned');
		System.assertEquals(warehouseId, results[0].warehouseId, 'Warehouse Id should be returned');
	}

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

		WarehousesSelector.mock = warehouseSelectorMock;
		DispatchService.mock = mockService;
		DispatchWarehouse.Request request = new DispatchWarehouse.Request();
		request.warehouseName = 'North Hub';

		// When the invocable is called with the warehouse name
		List<DispatchWarehouse.Result> results = DispatchWarehouse.execute(
			new List<DispatchWarehouse.Request>{ request }
		);

		// Then the service receives the resolved Id
		((DispatchService) mocks.verify(mockService)).dispatchWarehouses(new Set<Id>{ warehouseId });
		System.assertEquals('North Hub', results[0].warehouseName, 'Warehouse name should be returned');
		System.assertEquals(warehouseId, results[0].warehouseId, 'Resolved warehouse Id should be returned');
	}
}
