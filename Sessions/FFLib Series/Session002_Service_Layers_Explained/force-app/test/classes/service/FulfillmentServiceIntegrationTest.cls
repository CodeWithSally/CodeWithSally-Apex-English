/**
 * Integration tests for {@link FulfillmentService} against real rows.
 */
@IsTest
private class FulfillmentServiceIntegrationTest {
	@TestSetup
	static void setup() {
		TestDataFactory.createUserWithWarehousePermissions();
	}

	@IsTest
	private static void completeLinesSchedulesDueRobot() {
		// Given a run-as user with warehouse permissions
		User runAsUser = TestDataFactory.getRunAsUser();
		TestDataFactory data;
		System.runAs(runAsUser) {
			// Given an assigned line on a working robot that will become due after wear
			data = TestDataFactory.createDraftOrder(7, 8);
			update new FulfillmentOrder__c(
				Id = data.order.Id,
				Status__c = FulfillmentOrders.STATUS_IN_PROGRESS
			);
			data.order.Status__c = FulfillmentOrders.STATUS_IN_PROGRESS;
			update new FulfillmentLine__c(
				Id = data.line.Id,
				Status__c = FulfillmentLines.STATUS_ASSIGNED,
				AssignedRobot__c = data.robot.Id
			);
			data.line.Status__c = FulfillmentLines.STATUS_ASSIGNED;
			data.line.AssignedRobot__c = data.robot.Id;
			update new Robot__c(Id = data.robot.Id, Status__c = Robots.STATUS_WORKING);
			data.robot.Status__c = Robots.STATUS_WORKING;
		}

		// When the assigned line is completed
		Test.startTest();
		System.runAs(runAsUser) {
			FulfillmentService.newInstance().completeLines(new Set<Id>{ data.line.Id });
		}
		Test.stopTest();

		// Then the line is complete, the robot is in service, and a maintenance job exists
		FulfillmentLine__c line = [
			SELECT Status__c
			FROM FulfillmentLine__c
			WHERE Id = :data.line.Id
		];
		System.assertEquals(FulfillmentLines.STATUS_COMPLETE, line.Status__c, 'Line should be complete');

		Robot__c robot = [
			SELECT Status__c, HoursSinceService__c, Health__c
			FROM Robot__c
			WHERE Id = :data.robot.Id
		];
		System.assertEquals(Robots.STATUS_IN_SERVICE, robot.Status__c, 'Due robot should be in service');
		System.assertEquals(8, robot.HoursSinceService__c, 'Wear hours should include the completed line');

		List<MaintenanceJob__c> jobs = [
			SELECT Status__c, Type__c, Robot__c
			FROM MaintenanceJob__c
			WHERE Robot__c = :data.robot.Id
		];
		System.assertEquals(1, jobs.size(), 'One maintenance job should be created');
		System.assertEquals(MaintenanceJobs.STATUS_IN_PROGRESS, jobs[0].Status__c, 'Job starts in progress');
	}

	@IsTest
	private static void releaseThenDispatchThenCompleteWithoutDue() {
		// Given a run-as user with warehouse permissions
		User runAsUser = TestDataFactory.getRunAsUser();
		TestDataFactory data;
		System.runAs(runAsUser) {
			// Given a draft order whose robot is not due after one pick
			data = TestDataFactory.createDraftOrder(0, 40);
		}

		// When the order is released, dispatched, and completed
		Test.startTest();
		System.runAs(runAsUser) {
			FulfillmentService.newInstance().releaseOrders(new Set<Id>{ data.order.Id });
			DispatchService.newInstance().dispatchWarehouses(new Set<Id>{ data.warehouse.Id });
			FulfillmentService.newInstance().completeAssignedLinesForOrders(new Set<Id>{ data.order.Id });
		}
		Test.stopTest();

		// Then the order is complete, the robot is idle, and no maintenance job is created
		FulfillmentOrder__c order = [
			SELECT Status__c
			FROM FulfillmentOrder__c
			WHERE Id = :data.order.Id
		];
		System.assertEquals(FulfillmentOrders.STATUS_COMPLETED, order.Status__c, 'Single-line order should complete');

		Robot__c robot = [
			SELECT Status__c
			FROM Robot__c
			WHERE Id = :data.robot.Id
		];
		System.assertEquals(Robots.STATUS_IDLE, robot.Status__c, 'Robot should be idle when not due');

		System.assertEquals(
			0,
			[SELECT COUNT() FROM MaintenanceJob__c WHERE Robot__c = :data.robot.Id],
			'No job when the robot is not due'
		);
	}

	@IsTest
	private static void holdOrdersHoldsReleasedOrder() {
		// Given a run-as user with warehouse permissions
		User runAsUser = TestDataFactory.getRunAsUser();
		TestDataFactory data;
		System.runAs(runAsUser) {
			data = TestDataFactory.createDraftOrder();
		}

		// When the draft is released and then held
		Test.startTest();
		System.runAs(runAsUser) {
			FulfillmentService.newInstance().releaseOrders(new Set<Id>{ data.order.Id });
			FulfillmentService.newInstance().holdOrders(new Set<Id>{ data.order.Id });
		}
		Test.stopTest();

		// Then the order is On Hold
		FulfillmentOrder__c order = [
			SELECT Status__c
			FROM FulfillmentOrder__c
			WHERE Id = :data.order.Id
		];
		System.assertEquals(FulfillmentOrders.STATUS_ON_HOLD, order.Status__c, 'Released order should hold');
	}

	@IsTest
	private static void releaseOrdersRejectsClosedWarehouse() {
		// Given a run-as user with warehouse permissions
		User runAsUser = TestDataFactory.getRunAsUser();
		TestDataFactory data;
		System.runAs(runAsUser) {
			data = TestDataFactory.createDraftOrder();
			update new Warehouse__c(Id = data.warehouse.Id, Status__c = Warehouses.STATUS_CLOSED);
		}

		// When those orders are released
		Boolean thrown = false;
		Test.startTest();
		System.runAs(runAsUser) {
			try {
				FulfillmentService.newInstance().releaseOrders(new Set<Id>{ data.order.Id });
			} catch (FulfillmentService.FulfillmentServiceException e) {
				thrown = e.getMessage().contains('not active');
			}
		}
		Test.stopTest();

		// Then release is rejected and the order stays Draft
		System.assertEquals(true, thrown, 'Closed warehouse should block release');
		FulfillmentOrder__c order = [
			SELECT Status__c
			FROM FulfillmentOrder__c
			WHERE Id = :data.order.Id
		];
		System.assertEquals(FulfillmentOrders.STATUS_DRAFT, order.Status__c, 'Draft should be unchanged');
	}
}
