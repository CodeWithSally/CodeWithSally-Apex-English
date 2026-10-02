/**
 * Unit tests for FulfillmentService using fflib-apex-mocks. No DML.
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts, PMD.ApexUnitTestClassShouldHaveRunAs') // unit test: ApexMocks verify is the assertion; no DML
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

		FulfillmentLines.mock = linesMock;
		Robots.mock = robotsMock;
		FulfillmentOrders.mock = ordersMock;
		UnitOfWork.mock = uowMock;
		WarehousesSelector warehouseSelectorMock = (WarehousesSelector) mocks.mock(WarehousesSelector.class);

		// When the assigned lines are completed
		new FulfillmentService(
			orderSelectorMock,
			lineSelectorMock,
			robotSelectorMock,
			warehouseSelectorMock,
			maintenanceMock
		).completeLines(lineIds);

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
	private static void completeLinesSchedulesWhenWearReachesInterval() {
		// Given a working robot one hour short of its model interval
		FulfillmentOrder__c order = newInProgressOrder();
		Robot__c robot = newWorkingRobot(7, 8);
		FulfillmentLine__c line = newAssignedLine(order, robot.Id, 1);
		Collaborators collaborators = new Collaborators();

		// When that assigned line is completed
		collaborators.complete(new List<FulfillmentLine__c>{ line }, new List<Robot__c>{ robot });

		// Then the same in-memory robot is idle, worn to the interval, and handed to maintenance
		System.assertEquals(FulfillmentLines.STATUS_COMPLETE, line.Status__c, 'Line should complete');
		System.assertEquals(Robots.STATUS_IDLE, robot.Status__c, 'Robot should go idle before service');
		System.assertEquals(8, robot.HoursSinceService__c, 'Wear hours should include this pick');
		System.assertEquals(true, Robots.isDueForService(robot), 'Interval hours should make the robot due');
		collaborators.assertScheduled(new Set<Robot__c>{ robot });
	}

	@IsTest
	private static void completeLinesDoesNotScheduleWhenWearStaysBelowInterval() {
		// Given a working robot well below its model interval
		FulfillmentOrder__c order = newInProgressOrder();
		Robot__c robot = newWorkingRobot(0, 40);
		FulfillmentLine__c line = newAssignedLine(order, robot.Id, 1);
		Collaborators collaborators = new Collaborators();

		// When that assigned line is completed
		collaborators.complete(new List<FulfillmentLine__c>{ line }, new List<Robot__c>{ robot });

		// Then the robot is idle and worn, but maintenance is not called
		System.assertEquals(Robots.STATUS_IDLE, robot.Status__c, 'Robot should go idle');
		System.assertEquals(1, robot.HoursSinceService__c, 'Wear hours should include this pick');
		System.assertEquals(false, Robots.isDueForService(robot), 'One hour on a 40 hour interval is not due');
		collaborators.assertNotScheduled();
	}

	@IsTest
	private static void completeLinesDoesNotScheduleWhenWearIsExactlyWarning() {
		// Given a 100 hour interval so 80 hours of wear is Warning, not Critical
		FulfillmentOrder__c order = newInProgressOrder();
		Robot__c robot = newWorkingRobot(0, 100);
		FulfillmentLine__c line = newAssignedLine(order, robot.Id, 80);
		Collaborators collaborators = new Collaborators();

		// When that assigned line is completed
		collaborators.complete(new List<FulfillmentLine__c>{ line }, new List<Robot__c>{ robot });

		// Then health is Warning and maintenance is not called
		System.assertEquals(Robots.HEALTH_WARNING, robot.Health__c, '80 wear is warning');
		System.assertEquals(false, Robots.isDueForService(robot), 'Warning below the interval is not due');
		collaborators.assertNotScheduled();
	}

	@IsTest
	private static void completeLinesSchedulesWhenHealthBecomesCritical() {
		// Given a 100 hour interval so 81 hours of wear is Critical while hours stay under the interval
		FulfillmentOrder__c order = newInProgressOrder();
		Robot__c robot = newWorkingRobot(0, 100);
		FulfillmentLine__c line = newAssignedLine(order, robot.Id, 81);
		Collaborators collaborators = new Collaborators();

		// When that assigned line is completed
		collaborators.complete(new List<FulfillmentLine__c>{ line }, new List<Robot__c>{ robot });

		// Then the same robot is Critical and handed to maintenance
		System.assertEquals(Robots.STATUS_IDLE, robot.Status__c, 'Robot should go idle before service');
		System.assertEquals(Robots.HEALTH_CRITICAL, robot.Health__c, '81 wear is critical');
		System.assertEquals(81, robot.HoursSinceService__c, 'Hours should stay under the 100 hour interval');
		System.assertEquals(true, Robots.isDueForService(robot), 'Critical health should make the robot due');
		collaborators.assertScheduled(new Set<Robot__c>{ robot });
	}

	@IsTest
	private static void completeLinesUsesDefaultIntervalWhenRobotHasNoModel() {
		// Given a working robot with no model, one hour short of the 40 hour default
		FulfillmentOrder__c order = newInProgressOrder();
		Robot__c robot = newWorkingRobot(39, null);
		FulfillmentLine__c line = newAssignedLine(order, robot.Id, 1);
		Collaborators collaborators = new Collaborators();

		// When that assigned line is completed
		collaborators.complete(new List<FulfillmentLine__c>{ line }, new List<Robot__c>{ robot });

		// Then the default interval is used and maintenance is scheduled
		System.assertEquals(40, robot.HoursSinceService__c, 'Default interval is 40 hours');
		System.assertEquals(true, Robots.isDueForService(robot), 'Default interval hours should make the robot due');
		collaborators.assertScheduled(new Set<Robot__c>{ robot });
	}

	@IsTest
	private static void completeLinesAddsHoursAcrossLinesOnTheSameRobot() {
		// Given two assigned lines on one robot that is two hours short of its interval
		FulfillmentOrder__c order = newInProgressOrder();
		Robot__c robot = newWorkingRobot(6, 8);
		FulfillmentLine__c first = newAssignedLine(order, robot.Id, 1);
		FulfillmentLine__c second = newAssignedLine(order, robot.Id, 1);
		Collaborators collaborators = new Collaborators();

		// When both lines are completed together
		collaborators.complete(new List<FulfillmentLine__c>{ first, second }, new List<Robot__c>{ robot });

		// Then hours from both lines are applied before due is evaluated
		System.assertEquals(8, robot.HoursSinceService__c, 'Hours from both lines should be applied');
		System.assertEquals(true, Robots.isDueForService(robot), 'Combined hours should reach the interval');
		collaborators.assertScheduled(new Set<Robot__c>{ robot });
	}

	@IsTest
	private static void completeLinesSchedulesOnlyTheDueRobot() {
		// Given two working robots; only one will reach its interval on this pick
		FulfillmentOrder__c order = newInProgressOrder();
		Robot__c dueRobot = newWorkingRobot(7, 8);
		Robot__c freshRobot = newWorkingRobot(0, 40);
		FulfillmentLine__c dueLine = newAssignedLine(order, dueRobot.Id, 1);
		FulfillmentLine__c freshLine = newAssignedLine(order, freshRobot.Id, 1);
		Collaborators collaborators = new Collaborators();

		// When both assigned lines are completed
		collaborators.complete(
			new List<FulfillmentLine__c>{ dueLine, freshLine },
			new List<Robot__c>{ dueRobot, freshRobot }
		);

		// Then only the robot that reached its interval is handed to maintenance
		System.assertEquals(true, Robots.isDueForService(dueRobot), 'First robot should be due');
		System.assertEquals(false, Robots.isDueForService(freshRobot), 'Second robot should not be due');
		collaborators.assertScheduled(new Set<Robot__c>{ dueRobot });
	}

	@IsTest
	private static void completeLinesDoesNotScheduleWhenLineHasNoAssignedRobot() {
		// Given an assigned line with no robot
		FulfillmentOrder__c order = newInProgressOrder();
		FulfillmentLine__c line = newAssignedLine(order, null, 1);
		Collaborators collaborators = new Collaborators();

		// When that line is completed
		collaborators.complete(new List<FulfillmentLine__c>{ line }, new List<Robot__c>());

		// Then the line completes and maintenance is not called
		System.assertEquals(FulfillmentLines.STATUS_COMPLETE, line.Status__c, 'Line should complete');
		collaborators.assertNotScheduled();
	}

	@IsTest
	private static void completeLinesReturnsWhenNothingToComplete() {
		// Given no line Ids
		Collaborators collaborators = new Collaborators();

		// When complete is called with null or empty Ids or an empty list
		collaborators.newService().completeLines((Set<Id>) null);
		collaborators.newService().completeLines(new Set<Id>());
		collaborators.newService().completeLines((List<FulfillmentLine__c>) null);
		collaborators.newService().completeLines(new List<FulfillmentLine__c>());

		// Then no Unit of Work is created
		collaborators.assertNoCommit();
	}

	@IsTest
	private static void completeLinesRejectsLineThatIsNotAssigned() {
		// Given a pending line
		FulfillmentOrder__c order = newInProgressOrder();
		Robot__c robot = newWorkingRobot(0, 40);
		FulfillmentLine__c line = newAssignedLine(order, robot.Id, 1);
		line.Status__c = FulfillmentLines.STATUS_PENDING;
		Collaborators collaborators = new Collaborators();

		// When that line is completed
		Boolean thrown = false;
		try {
			collaborators.complete(new List<FulfillmentLine__c>{ line }, new List<Robot__c>{ robot });
		} catch (FulfillmentService.FulfillmentServiceException e) {
			thrown = e.getMessage().contains('must be Assigned');
		}

		// Then the service rejects the line and does not commit
		System.assertEquals(true, thrown, 'Pending line should not complete');
		collaborators.assertNoCommit();
	}

	@IsTest
	private static void completeLinesRejectsRobotThatIsNotWorking() {
		// Given an assigned line whose robot is already Idle
		FulfillmentOrder__c order = newInProgressOrder();
		Robot__c robot = newWorkingRobot(0, 40);
		robot.Status__c = Robots.STATUS_IDLE;
		FulfillmentLine__c line = newAssignedLine(order, robot.Id, 1);
		Collaborators collaborators = new Collaborators();

		// When that line is completed
		Boolean thrown = false;
		try {
			collaborators.complete(new List<FulfillmentLine__c>{ line }, new List<Robot__c>{ robot });
		} catch (FulfillmentService.FulfillmentServiceException e) {
			thrown = e.getMessage().contains('cannot go idle');
		}

		// Then the service rejects the robot and does not commit
		System.assertEquals(true, thrown, 'Idle robot cannot go idle');
		collaborators.assertNoCommit();
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

		FulfillmentLinesSelector lineSelectorMock = (FulfillmentLinesSelector) mocks.mock(
			FulfillmentLinesSelector.class
		);
		RobotsSelector robotSelectorMock = (RobotsSelector) mocks.mock(RobotsSelector.class);
		MaintenanceService maintenanceMock = (MaintenanceService) mocks.mock(MaintenanceService.class);

		// When those orders are released
		Boolean thrown = false;
		try {
			new FulfillmentService(
				orderSelectorMock,
				lineSelectorMock,
				robotSelectorMock,
				warehouseSelectorMock,
				maintenanceMock
			).releaseOrders(orderIds);
		} catch (FulfillmentService.FulfillmentServiceException e) {
			thrown = e.getMessage().contains('not active');
		}

		// Then the service rejects the closed warehouse
		System.assertEquals(true, thrown, 'Closed warehouse should block release');
	}

	private static FulfillmentOrder__c newInProgressOrder() {
		return new FulfillmentOrder__c(
			Id = TestIdGenerator.generate(FulfillmentOrder__c.SObjectType),
			Status__c = FulfillmentOrders.STATUS_IN_PROGRESS
		);
	}

	private static FulfillmentLine__c newAssignedLine(FulfillmentOrder__c order, Id robotId, Decimal hours) {
		FulfillmentLine__c line = new FulfillmentLine__c(
			Id = TestIdGenerator.generate(FulfillmentLine__c.SObjectType),
			FulfillmentOrder__c = order.Id,
			Status__c = FulfillmentLines.STATUS_ASSIGNED,
			AssignedRobot__c = robotId
		);
		if (hours != null && hours > 1) {
			line.Quantity__c = hours;
			line.WeightKg__c = 100;
		}
		return line;
	}

	private static Robot__c newWorkingRobot(Decimal hoursSinceService, Decimal intervalHours) {
		Robot__c robot = new Robot__c(
			Id = TestIdGenerator.generate(Robot__c.SObjectType),
			Name = 'Atlas',
			Status__c = Robots.STATUS_WORKING,
			Health__c = Robots.HEALTH_HEALTHY,
			HoursSinceService__c = hoursSinceService,
			WearPercent__c = 0,
			BatteryLevel__c = 100
		);
		if (intervalHours != null) {
			Id modelId = TestIdGenerator.generate(RobotModel__c.SObjectType);
			robot.Model__c = modelId;
			robot.Model__r = new RobotModel__c(Id = modelId, ServiceIntervalHours__c = intervalHours);
		}
		return robot;
	}

	/**
	 * Shared stubs for completeLines tests that run the real Robot and Line domains.
	 * Selectors, orders, maintenance, and the Unit of Work stay mocked.
	 */
	private class Collaborators {
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		fflib_SObjectUnitOfWork uowMock;
		FulfillmentLinesSelector lineSelectorMock;
		FulfillmentOrdersSelector orderSelectorMock;
		RobotsSelector robotSelectorMock;
		WarehousesSelector warehouseSelectorMock;
		MaintenanceService maintenanceMock;

		Collaborators() {
			uowMock = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);
			lineSelectorMock = (FulfillmentLinesSelector) mocks.mock(FulfillmentLinesSelector.class);
			orderSelectorMock = (FulfillmentOrdersSelector) mocks.mock(FulfillmentOrdersSelector.class);
			robotSelectorMock = (RobotsSelector) mocks.mock(RobotsSelector.class);
			warehouseSelectorMock = (WarehousesSelector) mocks.mock(WarehousesSelector.class);
			maintenanceMock = (MaintenanceService) mocks.mock(MaintenanceService.class);
			FulfillmentOrders.mock = (FulfillmentOrders) mocks.mock(FulfillmentOrders.class);
			UnitOfWork.mock = uowMock;
		}

		void complete(List<FulfillmentLine__c> lines, List<Robot__c> robots) {
			Set<Id> lineIds = new Map<Id, FulfillmentLine__c>(lines).keySet();
			Set<Id> robotIds = new Map<Id, Robot__c>(robots).keySet();
			Set<Id> orderIds = new Set<Id>();
			for (FulfillmentLine__c line : lines) {
				if (line.FulfillmentOrder__c != null) {
					orderIds.add(line.FulfillmentOrder__c);
				}
			}

			mocks.startStubbing();
			mocks.when(lineSelectorMock.selectById(lineIds)).thenReturn(lines);
			mocks.when(robotSelectorMock.selectByIdWithModel(robotIds)).thenReturn(robots);
			if (!orderIds.isEmpty()) {
				mocks.when(orderSelectorMock.selectByIdWithLines(orderIds))
					.thenReturn(new List<FulfillmentOrder__c>());
			}
			mocks.stopStubbing();

			newService().completeLines(lineIds);
		}

		FulfillmentService newService() {
			return new FulfillmentService(
				orderSelectorMock,
				lineSelectorMock,
				robotSelectorMock,
				warehouseSelectorMock,
				maintenanceMock
			);
		}

		void assertScheduled(Set<Robot__c> dueRobots) {
			((MaintenanceService) mocks.verify(maintenanceMock)).scheduleService(
				(Set<Robot__c>) fflib_Match.eq(dueRobots),
				(fflib_SObjectUnitOfWork) fflib_Match.eq(uowMock)
			);
			((fflib_SObjectUnitOfWork) mocks.verify(uowMock, 1)).commitWork();
		}

		void assertNotScheduled() {
			((MaintenanceService) mocks.verify(maintenanceMock, 0)).scheduleService(
				(Set<Robot__c>) fflib_Match.anyObject(),
				(fflib_SObjectUnitOfWork) fflib_Match.anyObject()
			);
			((fflib_SObjectUnitOfWork) mocks.verify(uowMock, 1)).commitWork();
		}

		void assertNoCommit() {
			((fflib_SObjectUnitOfWork) mocks.verify(uowMock, 0)).commitWork();
		}
	}
}
