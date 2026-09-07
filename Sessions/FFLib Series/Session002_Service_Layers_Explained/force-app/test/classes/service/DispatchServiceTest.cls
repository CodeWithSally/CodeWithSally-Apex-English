/**
 * Unit tests for DispatchService using fflib-apex-mocks. No DML.
 */
@IsTest
private class DispatchServiceTest {
	@IsTest
	private static void dispatchWarehousesCallsSelectorDomainAndCommit() {
		// Given a released line, an idle robot that can take the load, and stubbed selectors
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		fflib_SObjectUnitOfWork uowMock = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);
		FulfillmentLinesSelector lineSelectorMock = (FulfillmentLinesSelector) mocks.mock(FulfillmentLinesSelector.class);
		RobotsSelector robotSelectorMock = (RobotsSelector) mocks.mock(RobotsSelector.class);
		FulfillmentOrdersSelector orderSelectorMock = (FulfillmentOrdersSelector) mocks.mock(FulfillmentOrdersSelector.class);
		Robots robotsMock = (Robots) mocks.mock(Robots.class);
		FulfillmentLines linesMock = (FulfillmentLines) mocks.mock(FulfillmentLines.class);
		FulfillmentOrders ordersMock = (FulfillmentOrders) mocks.mock(FulfillmentOrders.class);

		Id warehouseId = TestIdGenerator.generate(Warehouse__c.SObjectType);
		Id lineId = TestIdGenerator.generate(FulfillmentLine__c.SObjectType);
		Id orderId = TestIdGenerator.generate(FulfillmentOrder__c.SObjectType);
		Id robotId = TestIdGenerator.generate(Robot__c.SObjectType);
		Id modelId = TestIdGenerator.generate(RobotModel__c.SObjectType);

		FulfillmentOrder__c order = new FulfillmentOrder__c(
			Id = orderId,
			Warehouse__c = warehouseId,
			Status__c = FulfillmentOrders.STATUS_RELEASED
		);
		FulfillmentLine__c line = new FulfillmentLine__c(
			Id = lineId,
			FulfillmentOrder__c = orderId,
			Status__c = FulfillmentLines.STATUS_PENDING,
			WeightKg__c = 10
		);
		line.FulfillmentOrder__r = order;
		Robot__c robot = new Robot__c(
			Id = robotId,
			Name = 'Atlas',
			Warehouse__c = warehouseId,
			Status__c = Robots.STATUS_IDLE,
			Health__c = Robots.HEALTH_HEALTHY,
			WearPercent__c = 0,
			BatteryLevel__c = 100,
			Model__c = modelId
		);
		robot.Model__r = new RobotModel__c(Id = modelId, MaxLoadKg__c = 50);

		Set<Id> warehouseIds = new Set<Id>{ warehouseId };

		mocks.startStubbing();
		mocks.when(lineSelectorMock.selectPendingUnassignedByWarehouseWithOrder(warehouseIds))
			.thenReturn(new List<FulfillmentLine__c>{ line });
		mocks.when(robotSelectorMock.selectIdleByWarehouseWithModel(warehouseIds)).thenReturn(new List<Robot__c>{ robot });
		mocks.when(robotsMock.getAvailableForWork()).thenReturn(new List<Robot__c>{ robot });
		mocks.when(orderSelectorMock.selectById(new Set<Id>{ orderId }))
			.thenReturn(new List<FulfillmentOrder__c>{ order });
		mocks.stopStubbing();

		UnitOfWork.mock = uowMock;
		FulfillmentLinesSelector.mock = lineSelectorMock;
		RobotsSelector.mock = robotSelectorMock;
		FulfillmentOrdersSelector.mock = orderSelectorMock;
		Robots.mock = robotsMock;
		FulfillmentLines.mock = linesMock;
		FulfillmentOrders.mock = ordersMock;

		// When warehouses are dispatched
		DispatchService.newInstance().dispatchWarehouses(warehouseIds);

		// Then robots start work, lines are assigned, orders move in progress, and the UoW commits
		((Robots) mocks.verify(robotsMock)).startWork(uowMock);
		((FulfillmentLines) mocks.verify(linesMock)).assign(
			(Map<Id, Id>) fflib_Match.anyObject(),
			(fflib_SObjectUnitOfWork) fflib_Match.eq(uowMock)
		);
		((FulfillmentOrders) mocks.verify(ordersMock)).markInProgress(uowMock);
		((fflib_SObjectUnitOfWork) mocks.verify(uowMock, 1)).commitWork();
	}

	@IsTest
	private static void assignRobotsStartsWorkAndMarksOrder() {
		// Given a pending line, an idle robot, and a released parent
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		fflib_SObjectUnitOfWork uowMock = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);
		FulfillmentLinesSelector lineSelectorMock = (FulfillmentLinesSelector) mocks.mock(FulfillmentLinesSelector.class);
		RobotsSelector robotSelectorMock = (RobotsSelector) mocks.mock(RobotsSelector.class);
		FulfillmentOrdersSelector orderSelectorMock = (FulfillmentOrdersSelector) mocks.mock(FulfillmentOrdersSelector.class);
		Robots robotsMock = (Robots) mocks.mock(Robots.class);
		FulfillmentLines linesMock = (FulfillmentLines) mocks.mock(FulfillmentLines.class);
		FulfillmentOrders ordersMock = (FulfillmentOrders) mocks.mock(FulfillmentOrders.class);

		Id lineId = TestIdGenerator.generate(FulfillmentLine__c.SObjectType);
		Id orderId = TestIdGenerator.generate(FulfillmentOrder__c.SObjectType);
		Id robotId = TestIdGenerator.generate(Robot__c.SObjectType);
		FulfillmentLine__c line = new FulfillmentLine__c(
			Id = lineId,
			FulfillmentOrder__c = orderId,
			Status__c = FulfillmentLines.STATUS_PENDING
		);
		FulfillmentOrder__c order = new FulfillmentOrder__c(
			Id = orderId,
			Status__c = FulfillmentOrders.STATUS_RELEASED
		);
		Robot__c robot = new Robot__c(Id = robotId, Name = 'Atlas', Status__c = Robots.STATUS_IDLE);
		Map<Id, Id> robotIdByLineId = new Map<Id, Id>{ lineId => robotId };
		Set<Id> lineIds = new Set<Id>{ lineId };
		Set<Id> robotIds = new Set<Id>{ robotId };
		Set<Id> orderIds = new Set<Id>{ orderId };

		mocks.startStubbing();
		mocks.when(lineSelectorMock.selectById(lineIds)).thenReturn(new List<FulfillmentLine__c>{ line });
		mocks.when(robotSelectorMock.selectByIdWithModel(robotIds)).thenReturn(new List<Robot__c>{ robot });
		mocks.when(orderSelectorMock.selectById(orderIds)).thenReturn(new List<FulfillmentOrder__c>{ order });
		mocks.stopStubbing();

		UnitOfWork.mock = uowMock;
		FulfillmentLinesSelector.mock = lineSelectorMock;
		RobotsSelector.mock = robotSelectorMock;
		FulfillmentOrdersSelector.mock = orderSelectorMock;
		Robots.mock = robotsMock;
		FulfillmentLines.mock = linesMock;
		FulfillmentOrders.mock = ordersMock;

		// When the given pairs are assigned
		DispatchService.newInstance().assignRobots(robotIdByLineId);

		// Then robots start, lines assign, the released order moves in progress, and the UoW commits
		((Robots) mocks.verify(robotsMock)).startWork(uowMock);
		((FulfillmentLines) mocks.verify(linesMock)).assign(robotIdByLineId, uowMock);
		((FulfillmentOrders) mocks.verify(ordersMock)).markInProgress(uowMock);
		((fflib_SObjectUnitOfWork) mocks.verify(uowMock, 1)).commitWork();
	}
}
