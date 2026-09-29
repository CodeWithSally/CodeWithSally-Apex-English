/**
 * Integration tests for {@link GetWarehouseDesk} against real rows.
 */
@IsTest
private class GetWarehouseDeskTest {
	@TestSetup
	static void setup() {
		TestDataFactory.createUserWithWarehousePermissions();
	}

	@IsTest
	private static void executeDescribesNorthHubByName() {
		// Given a run-as user with warehouse permissions
		User runAsUser = TestDataFactory.getRunAsUser();
		TestDataFactory data;
		FulfillmentOrder__c named;
		GetWarehouseDesk.Request request = new GetWarehouseDesk.Request();
		request.warehouseName = 'North Hub';
		System.runAs(runAsUser) {
			data = TestDataFactory.createDraftOrder();
			named = [SELECT Name FROM FulfillmentOrder__c WHERE Id = :data.order.Id];
		}

		// When the desk is looked up by name
		List<GetWarehouseDesk.Result> results;
		Test.startTest();
		System.runAs(runAsUser) {
			results = GetWarehouseDesk.execute(new List<GetWarehouseDesk.Request>{ request });
		}
		Test.stopTest();

		// Then the snapshot uses names and counts the shortfall
		System.assertEquals(1, results.size(), 'One result should be returned');
		System.assertEquals('North Hub', results[0].warehouseName, 'Warehouse name should be North Hub');
		System.assertEquals(data.warehouse.Id, results[0].warehouseId, 'Warehouse Id should match');
		System.assertEquals(1, results[0].pendingUnassignedLines, 'One pending line');
		System.assertEquals(1, results[0].idleAvailableRobots, 'One idle robot');
		System.assertEquals(0, results[0].robotShortfall, 'No shortfall when counts match');
		System.assertEquals(named.Name, results[0].draftOrderNames, 'Draft order name should be returned');
	}

	@IsTest
	private static void executeDescribesTwoNamesInOneCall() {
		// Given a run-as user with warehouse permissions
		User runAsUser = TestDataFactory.getRunAsUser();
		GetWarehouseDesk.Request first = new GetWarehouseDesk.Request();
		first.warehouseName = 'North Hub';
		GetWarehouseDesk.Request second = new GetWarehouseDesk.Request();
		second.warehouseName = 'North Hub';
		System.runAs(runAsUser) {
			TestDataFactory.createDraftOrder();
		}

		// When both desks are looked up together
		List<GetWarehouseDesk.Result> results;
		Test.startTest();
		System.runAs(runAsUser) {
			results = GetWarehouseDesk.execute(new List<GetWarehouseDesk.Request>{ first, second });
		}
		Test.stopTest();

		// Then each request gets the same North Hub snapshot
		System.assertEquals(2, results.size(), 'One result per request');
		System.assertEquals('North Hub', results[0].warehouseName, 'First name lookup should resolve North Hub');
		System.assertEquals('North Hub', results[1].warehouseName, 'Second name lookup should resolve North Hub');
		System.assertEquals(1, results[0].pendingUnassignedLines, 'Pending lines on first result');
		System.assertEquals(1, results[1].pendingUnassignedLines, 'Pending lines on second result');
	}
}
