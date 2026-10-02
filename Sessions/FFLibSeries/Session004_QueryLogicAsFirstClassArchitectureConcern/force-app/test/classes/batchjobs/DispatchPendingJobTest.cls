/**
 * Unit tests for {@link DispatchPendingJob} using fflib-apex-mocks. No DML.
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts, PMD.ApexUnitTestClassShouldHaveRunAs') // unit test: ApexMocks verify is the assertion; no DML
private class DispatchPendingJobTest {
	@IsTest
	private static void startUsesInjectedSelector() {
		// Given a stubbed warehouse selector QueryLocator
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		WarehousesSelector warehouseSelectorMock = (WarehousesSelector) mocks.mock(WarehousesSelector.class);
		DispatchService dispatchSvcMock = (DispatchService) mocks.mock(DispatchService.class);
		Database.QueryLocator locator = Database.getQueryLocator(
			[SELECT Id FROM Warehouse__c WHERE Id = NULL]
		);

		mocks.startStubbing();
		mocks.when(warehouseSelectorMock.selectActiveAsQueryLocator()).thenReturn(locator);
		mocks.stopStubbing();

		// When start runs
		Database.QueryLocator actual = new DispatchPendingJob(warehouseSelectorMock, dispatchSvcMock)
			.start(null);

		// Then the injected selector is asked for the active-warehouse locator
		((WarehousesSelector) mocks.verify(warehouseSelectorMock)).selectActiveAsQueryLocator();
		System.assertEquals(locator, actual, 'start should return the selector QueryLocator');
	}

	@IsTest
	private static void executeCallsDispatchService() {
		// Given a stubbed dispatch service and a warehouse chunk
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		WarehousesSelector warehouseSelectorMock = (WarehousesSelector) mocks.mock(WarehousesSelector.class);
		DispatchService dispatchSvcMock = (DispatchService) mocks.mock(DispatchService.class);
		Id warehouseId = TestIdGenerator.generate(Warehouse__c.SObjectType);
		Warehouse__c warehouse = new Warehouse__c(Id = warehouseId, Name = 'North Hub');

		// When the batch chunk is executed
		new DispatchPendingJob(warehouseSelectorMock, dispatchSvcMock)
			.execute(null, new List<Warehouse__c>{ warehouse });

		// Then the service is called with the warehouse ids
		((DispatchService) mocks.verify(dispatchSvcMock)).dispatchWarehouses(new Set<Id>{ warehouseId });
	}
}
