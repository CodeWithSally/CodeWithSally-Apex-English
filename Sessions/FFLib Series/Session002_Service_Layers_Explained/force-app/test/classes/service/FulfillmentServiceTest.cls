/**
 * Unit tests for FulfillmentService using fflib-apex-mocks. No DML.
 */
@IsTest
private class FulfillmentServiceTest {
	@IsTest
	private static void completeLinesCallsMaintenanceWhenRobotsAreDue() {
		// Given an assigned line whose robot is due for service, and stubbed collaborators
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		fflib_SObjectUnitOfWork uowMock = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);
		FulfillmentLinesSelector lineSelectorMock = (FulfillmentLinesSelector) mocks.mock(FulfillmentLinesSelector.class);
		FulfillmentOrdersSelector orderSelectorMock = (FulfillmentOrdersSelector) mocks.mock(FulfillmentOrdersSelector.class);
		RobotsSelector robotSelectorMock = (RobotsSelector) mocks.mock(RobotsSelector.class);
		FulfillmentLines linesMock = (FulfillmentLines) mocks.mock(FulfillmentLines.class);
		Robots robotsMock = (Robots) mocks.mock(Robots.class);
		FulfillmentOrders ordersMock = (FulfillmentOrders) mocks.mock(FulfillmentOrders.class);
		MaintenanceService maintenanceMock = (MaintenanceService) mocks.mock(MaintenanceService.class);

		Id lineId = TestIdGenerator.generate(FulfillmentLine__c.SObjectType);
		Id orderId = TestIdGenerator.generate(FulfillmentOrder__c.SObjectType);
		Id robotId = TestIdGenerator.generate(Robot__c.SObjectType);
		FulfillmentLine__c line = new FulfillmentLine__c(
			Id = lineId,
			FulfillmentOrder__c = orderId,
			Status__c = FulfillmentLines.STATUS_ASSIGNED,
			AssignedRobot__c = robotId
		);
		FulfillmentOrder__c order = (FulfillmentOrder__c) JSON.deserialize(
			'{"attributes":{"type":"FulfillmentOrder__c"},"Id":"'
				+ orderId
				+ '","Status__c":"In Progress","FulfillmentLines__r":{"totalSize":1,"done":true,"records":['
				+ '{"attributes":{"type":"FulfillmentLine__c"},"Id":"'
				+ lineId
				+ '","FulfillmentOrder__c":"'
				+ orderId
				+ '","Status__c":"Assigned","AssignedRobot__c":"'
				+ robotId
				+ '"}]}}',
			FulfillmentOrder__c.class
		);
		Robot__c robot = new Robot__c(Id = robotId, Name = 'Atlas', Status__c = Robots.STATUS_WORKING);
		Set<Id> lineIds = new Set<Id>{ lineId };
		Set<Id> orderIds = new Set<Id>{ orderId };
		Set<Id> robotIds = new Set<Id>{ robotId };
		Map<Id, Decimal> hoursByRobotId = new Map<Id, Decimal>{ robotId => 1 };

		mocks.startStubbing();
		mocks.when(lineSelectorMock.selectById(lineIds)).thenReturn(new List<FulfillmentLine__c>{ line });
		mocks.when(orderSelectorMock.selectByIdWithLines(orderIds)).thenReturn(new List<FulfillmentOrder__c>{ order });
		mocks.when(linesMock.getEstimatedHoursByAssignedRobotId()).thenReturn(hoursByRobotId);
		mocks.when(robotSelectorMock.selectByIdWithModel(robotIds)).thenReturn(new List<Robot__c>{ robot });
		mocks.when(robotsMock.getDueForService()).thenReturn(new Set<Robot__c>{ robot });
		mocks.stopStubbing();

		UnitOfWork.mock = uowMock;
		FulfillmentLinesSelector.mock = lineSelectorMock;
		FulfillmentOrdersSelector.mock = orderSelectorMock;
		RobotsSelector.mock = robotSelectorMock;
		FulfillmentLines.mock = linesMock;
		Robots.mock = robotsMock;
		FulfillmentOrders.mock = ordersMock;
		MaintenanceService.mock = maintenanceMock;

		// When the assigned lines are completed
		FulfillmentService.newInstance().completeLines(lineIds);

		// Then lines complete, the robot goes idle and wears, and maintenance is scheduled on the same UoW
		((FulfillmentLines) mocks.verify(linesMock)).complete(uowMock);
		((Robots) mocks.verify(robotsMock)).goIdle(uowMock);
		((Robots) mocks.verify(robotsMock)).applyWear(hoursByRobotId, uowMock);
		((FulfillmentOrders) mocks.verify(ordersMock)).complete(uowMock, lineIds);
		((MaintenanceService) mocks.verify(maintenanceMock)).scheduleService(
			(Set<Robot__c>) fflib_Match.anyObject(),
			(fflib_SObjectUnitOfWork) fflib_Match.eq(uowMock)
		);
		((fflib_SObjectUnitOfWork) mocks.verify(uowMock, 1)).commitWork();
	}

	@IsTest
	private static void releaseOrdersRejectsClosedWarehouse() {
		// Given a draft order at a closed warehouse
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		FulfillmentOrdersSelector orderSelectorMock = (FulfillmentOrdersSelector) mocks.mock(
			FulfillmentOrdersSelector.class
		);
		WarehousesSelector warehouseSelectorMock = (WarehousesSelector) mocks.mock(WarehousesSelector.class);

		Id orderId = TestIdGenerator.generate(FulfillmentOrder__c.SObjectType);
		Id warehouseId = TestIdGenerator.generate(Warehouse__c.SObjectType);
		FulfillmentOrder__c order = new FulfillmentOrder__c(
			Id = orderId,
			Warehouse__c = warehouseId,
			Status__c = FulfillmentOrders.STATUS_DRAFT
		);
		Warehouse__c warehouse = new Warehouse__c(
			Id = warehouseId,
			Name = 'North Hub',
			Status__c = Warehouses.STATUS_CLOSED
		);
		Set<Id> orderIds = new Set<Id>{ orderId };
		Set<Id> warehouseIds = new Set<Id>{ warehouseId };

		mocks.startStubbing();
		mocks.when(orderSelectorMock.selectByIdWithLines(orderIds))
			.thenReturn(new List<FulfillmentOrder__c>{ order });
		mocks.when(warehouseSelectorMock.selectById(warehouseIds))
			.thenReturn(new List<Warehouse__c>{ warehouse });
		mocks.stopStubbing();

		FulfillmentOrdersSelector.mock = orderSelectorMock;
		WarehousesSelector.mock = warehouseSelectorMock;

		// When those orders are released
		Boolean thrown = false;
		try {
			FulfillmentService.newInstance().releaseOrders(orderIds);
		} catch (FulfillmentService.FulfillmentServiceException e) {
			thrown = e.getMessage().contains('not active');
		}

		// Then the service rejects the closed warehouse
		System.assertEquals(true, thrown, 'Closed warehouse should block release');
	}
}
