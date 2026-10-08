/**
 * Unit tests for DispatchService using fflib-apex-mocks. No DML.
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts, PMD.ApexUnitTestClassShouldHaveRunAs') // unit test: ApexMocks verify is the assertion; no DML
private class DispatchServiceTest {
	@IsTest
	@SuppressWarnings('PMD.DetectCopyPasteForApex') // teaching: keep this test readable top-to-bottom; extract newMocks() to DRY
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

		Robots.mock = robotsMock;
		FulfillmentLines.mock = linesMock;
		FulfillmentOrders.mock = ordersMock;
		UnitOfWork.mock = uowMock;

		// When warehouses are dispatched
		new DispatchService(lineSelectorMock, robotSelectorMock, orderSelectorMock)
			.dispatchWarehouses(warehouseIds);

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
	@SuppressWarnings('PMD.DetectCopyPasteForApex') // teaching: keep this test readable top-to-bottom; extract newMocks() to DRY
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

		Robots.mock = robotsMock;
		FulfillmentLines.mock = linesMock;
		FulfillmentOrders.mock = ordersMock;
		UnitOfWork.mock = uowMock;

		// When the given pairs are assigned
		new DispatchService(lineSelectorMock, robotSelectorMock, orderSelectorMock)
			.assignRobots(robotIdByLineId);

		// Then robots start, lines assign, the released order moves in progress, and the UoW commits
		((Robots) mocks.verify(robotsMock)).startWork(uowMock);
		((FulfillmentLines) mocks.verify(linesMock)).assign(robotIdByLineId, uowMock);
		((FulfillmentOrders) mocks.verify(ordersMock)).markInProgress(uowMock);
		((fflib_SObjectUnitOfWork) mocks.verify(uowMock, 1)).commitWork();
	}

	@IsTest
	private static void skipsRobotWhenLineHeavierThanMaxLoad() {
		// Given a line heavier than the robot model max load
		Id warehouseId = TestIdGenerator.generate(Warehouse__c.SObjectType);
		FulfillmentOrder__c order = newReleasedOrder(warehouseId);
		FulfillmentLine__c line = newPendingLine(order, 60);
		Robot__c robot = newIdleRobot(warehouseId, 50);
		Collaborators collaborators = new Collaborators();
		collaborators.stub(new List<FulfillmentLine__c>{ line }, new List<Robot__c>{ robot }, warehouseId);

		// When the warehouse is dispatched
		collaborators.dispatch(warehouseId);

		// Then no pair is assigned
		collaborators.assertNoMatch();
	}

	@IsTest
	private static void pairsWhenLineWeightEqualsMaxLoad() {
		// Given a line whose weight equals the robot model max load
		Id warehouseId = TestIdGenerator.generate(Warehouse__c.SObjectType);
		FulfillmentOrder__c order = newReleasedOrder(warehouseId);
		FulfillmentLine__c line = newPendingLine(order, 50);
		Robot__c robot = newIdleRobot(warehouseId, 50);
		Collaborators collaborators = new Collaborators();
		collaborators.stub(new List<FulfillmentLine__c>{ line }, new List<Robot__c>{ robot }, warehouseId);

		// When the warehouse is dispatched
		collaborators.dispatch(warehouseId);

		// Then the line is paired (skip only when weight is greater)
		collaborators.assertAssigned(new Map<Id, Id>{ line.Id => robot.Id });
	}

	@IsTest
	private static void pairsWhenRobotHasNoModel() {
		// Given a heavy line and a robot with no model (no max-load limit)
		Id warehouseId = TestIdGenerator.generate(Warehouse__c.SObjectType);
		FulfillmentOrder__c order = newReleasedOrder(warehouseId);
		FulfillmentLine__c line = newPendingLine(order, 99);
		Robot__c robot = newIdleRobot(warehouseId, null);
		Collaborators collaborators = new Collaborators();
		collaborators.stub(new List<FulfillmentLine__c>{ line }, new List<Robot__c>{ robot }, warehouseId);

		// When the warehouse is dispatched
		collaborators.dispatch(warehouseId);

		// Then the robot is still paired
		collaborators.assertAssigned(new Map<Id, Id>{ line.Id => robot.Id });
	}

	@IsTest
	private static void firstLineClaimsTheOnlyRobot() {
		// Given two lines that both fit and only one robot
		Id warehouseId = TestIdGenerator.generate(Warehouse__c.SObjectType);
		FulfillmentOrder__c order = newReleasedOrder(warehouseId);
		FulfillmentLine__c first = newPendingLine(order, 10);
		FulfillmentLine__c second = newPendingLine(order, 10);
		Robot__c robot = newIdleRobot(warehouseId, 50);
		Collaborators collaborators = new Collaborators();
		collaborators.stub(
			new List<FulfillmentLine__c>{ first, second },
			new List<Robot__c>{ robot },
			warehouseId
		);

		// When the warehouse is dispatched
		collaborators.dispatch(warehouseId);

		// Then only the first line is paired
		collaborators.assertAssigned(new Map<Id, Id>{ first.Id => robot.Id });
	}

	@IsTest
	private static void doesNotPairLineAndRobotInDifferentWarehouses() {
		// Given a line at one warehouse and a robot at another
		Id warehouseA = TestIdGenerator.generate(Warehouse__c.SObjectType);
		Id warehouseB = TestIdGenerator.generate(Warehouse__c.SObjectType);
		FulfillmentOrder__c order = newReleasedOrder(warehouseA);
		FulfillmentLine__c line = newPendingLine(order, 10);
		Robot__c robot = newIdleRobot(warehouseB, 50);
		Set<Id> warehouseIds = new Set<Id>{ warehouseA, warehouseB };
		Collaborators collaborators = new Collaborators();
		collaborators.stub(new List<FulfillmentLine__c>{ line }, new List<Robot__c>{ robot }, warehouseIds);

		// When both warehouses are dispatched
		collaborators.dispatch(warehouseIds);

		// Then they are not paired
		collaborators.assertNoMatch();
	}

	@IsTest
	private static void pairsEachLineWithARobotInTheSameWarehouse() {
		// Given a line and robot at each of two warehouses
		Id warehouseA = TestIdGenerator.generate(Warehouse__c.SObjectType);
		Id warehouseB = TestIdGenerator.generate(Warehouse__c.SObjectType);
		FulfillmentOrder__c orderA = newReleasedOrder(warehouseA);
		FulfillmentOrder__c orderB = newReleasedOrder(warehouseB);
		FulfillmentLine__c lineA = newPendingLine(orderA, 10);
		FulfillmentLine__c lineB = newPendingLine(orderB, 10);
		Robot__c robotA = newIdleRobot(warehouseA, 50);
		Robot__c robotB = newIdleRobot(warehouseB, 50);
		Set<Id> warehouseIds = new Set<Id>{ warehouseA, warehouseB };
		Collaborators collaborators = new Collaborators();
		collaborators.stub(
			new List<FulfillmentLine__c>{ lineA, lineB },
			new List<Robot__c>{ robotA, robotB },
			warehouseIds
		);

		// When both warehouses are dispatched
		collaborators.dispatch(warehouseIds);

		// Then each line stays with the robot in its own warehouse
		collaborators.assertAssigned(new Map<Id, Id>{ lineA.Id => robotA.Id, lineB.Id => robotB.Id });
	}

	@IsTest
	private static void skipsLineWithNoWarehouse() {
		// Given a line with no parent warehouse and a robot that would otherwise fit
		Id warehouseId = TestIdGenerator.generate(Warehouse__c.SObjectType);
		FulfillmentLine__c line = new FulfillmentLine__c(
			Id = TestIdGenerator.generate(FulfillmentLine__c.SObjectType),
			Status__c = FulfillmentLines.STATUS_PENDING,
			WeightKg__c = 10
		);
		Robot__c robot = newIdleRobot(warehouseId, 50);
		Collaborators collaborators = new Collaborators();
		collaborators.stub(new List<FulfillmentLine__c>{ line }, new List<Robot__c>{ robot }, warehouseId);

		// When the warehouse is dispatched
		collaborators.dispatch(warehouseId);

		// Then the line is skipped
		collaborators.assertNoMatch();
	}

	@IsTest
	private static void skipsRobotWithNoWarehouse() {
		// Given a line at a warehouse and a robot with no warehouse
		Id warehouseId = TestIdGenerator.generate(Warehouse__c.SObjectType);
		FulfillmentOrder__c order = newReleasedOrder(warehouseId);
		FulfillmentLine__c line = newPendingLine(order, 10);
		Robot__c robot = newIdleRobot(null, 50);
		Collaborators collaborators = new Collaborators();
		collaborators.stub(new List<FulfillmentLine__c>{ line }, new List<Robot__c>{ robot }, warehouseId);

		// When the warehouse is dispatched
		collaborators.dispatch(warehouseId);

		// Then the robot is skipped
		collaborators.assertNoMatch();
	}

	private static FulfillmentOrder__c newReleasedOrder(Id warehouseId) {
		return new FulfillmentOrder__c(
			Id = TestIdGenerator.generate(FulfillmentOrder__c.SObjectType),
			Warehouse__c = warehouseId,
			Status__c = FulfillmentOrders.STATUS_RELEASED
		);
	}

	private static FulfillmentLine__c newPendingLine(FulfillmentOrder__c order, Decimal weightKg) {
		FulfillmentLine__c line = new FulfillmentLine__c(
			Id = TestIdGenerator.generate(FulfillmentLine__c.SObjectType),
			FulfillmentOrder__c = order.Id,
			Status__c = FulfillmentLines.STATUS_PENDING,
			WeightKg__c = weightKg
		);
		line.FulfillmentOrder__r = order;
		return line;
	}

	private static Robot__c newIdleRobot(Id warehouseId, Decimal maxLoadKg) {
		Robot__c robot = new Robot__c(
			Id = TestIdGenerator.generate(Robot__c.SObjectType),
			Name = 'Atlas',
			Warehouse__c = warehouseId,
			Status__c = Robots.STATUS_IDLE
		);
		if (maxLoadKg != null) {
			Id modelId = TestIdGenerator.generate(RobotModel__c.SObjectType);
			robot.Model__c = modelId;
			robot.Model__r = new RobotModel__c(Id = modelId, MaxLoadKg__c = maxLoadKg);
		}
		return robot;
	}

	/**
	* Shared selector / domain / UoW stubs for match-rule tests.
	*/
	private class Collaborators {
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		fflib_SObjectUnitOfWork uowMock;
		FulfillmentLinesSelector lineSelectorMock;
		RobotsSelector robotSelectorMock;
		FulfillmentOrdersSelector orderSelectorMock;
		Robots robotsMock;
		FulfillmentLines linesMock;
		FulfillmentOrders ordersMock;

		Collaborators() {
			uowMock = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);
			lineSelectorMock = (FulfillmentLinesSelector) mocks.mock(FulfillmentLinesSelector.class);
			robotSelectorMock = (RobotsSelector) mocks.mock(RobotsSelector.class);
			orderSelectorMock = (FulfillmentOrdersSelector) mocks.mock(FulfillmentOrdersSelector.class);
			robotsMock = (Robots) mocks.mock(Robots.class);
			linesMock = (FulfillmentLines) mocks.mock(FulfillmentLines.class);
			ordersMock = (FulfillmentOrders) mocks.mock(FulfillmentOrders.class);
			Robots.mock = robotsMock;
			FulfillmentLines.mock = linesMock;
			FulfillmentOrders.mock = ordersMock;
			UnitOfWork.mock = uowMock;
		}

		void stub(List<FulfillmentLine__c> lines, List<Robot__c> robots, Id warehouseId) {
			stub(lines, robots, new Set<Id>{ warehouseId });
		}

		void stub(List<FulfillmentLine__c> lines, List<Robot__c> robots, Set<Id> warehouseIds) {
			Set<Id> orderIds = new Set<Id>();
			List<FulfillmentOrder__c> orders = new List<FulfillmentOrder__c>();
			for (FulfillmentLine__c line : lines) {
				if (line.FulfillmentOrder__c != null) {
					orderIds.add(line.FulfillmentOrder__c);
				}
				if (line.FulfillmentOrder__r != null) {
					orders.add(line.FulfillmentOrder__r);
				}
			}
			mocks.startStubbing();
			mocks.when(lineSelectorMock.selectPendingUnassignedByWarehouseWithOrder(warehouseIds))
				.thenReturn(lines);
			mocks.when(robotSelectorMock.selectIdleByWarehouseWithModel(warehouseIds)).thenReturn(robots);
			mocks.when(robotsMock.getAvailableForWork()).thenReturn(robots);
			if (!orderIds.isEmpty()) {
				mocks.when(orderSelectorMock.selectById(orderIds)).thenReturn(orders);
			}
			mocks.stopStubbing();
		}

		void dispatch(Id warehouseId) {
			dispatch(new Set<Id>{ warehouseId });
		}

		void dispatch(Set<Id> warehouseIds) {
			new DispatchService(lineSelectorMock, robotSelectorMock, orderSelectorMock)
				.dispatchWarehouses(warehouseIds);
		}

		void assertAssigned(Map<Id, Id> robotIdByLineId) {
			((FulfillmentLines) mocks.verify(linesMock)).assign(robotIdByLineId, uowMock);
			((fflib_SObjectUnitOfWork) mocks.verify(uowMock, 1)).commitWork();
		}

		void assertNoMatch() {
			((FulfillmentLines) mocks.verify(linesMock, 0)).assign(
				(Map<Id, Id>) fflib_Match.anyObject(),
				(fflib_SObjectUnitOfWork) fflib_Match.anyObject()
			);
			((fflib_SObjectUnitOfWork) mocks.verify(uowMock, 0)).commitWork();
		}
	}
}
