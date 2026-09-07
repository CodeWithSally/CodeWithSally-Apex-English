/**
 * Tests for {@link GetWarehouseDesk}.
 */
@IsTest
private class GetWarehouseDeskTest {
	@IsTest
	private static void executeDescribesNorthHubByName() {
		// Given North Hub with one pending draft line and one idle robot
		TestDataFactory data = TestDataFactory.createDraftOrder();
		FulfillmentOrder__c named = [SELECT Name FROM FulfillmentOrder__c WHERE Id = :data.order.Id];
		GetWarehouseDesk.Request request = new GetWarehouseDesk.Request();
		request.warehouseName = 'North Hub';

		// When the desk is looked up by name
		List<GetWarehouseDesk.Result> results = GetWarehouseDesk.execute(
			new List<GetWarehouseDesk.Request>{ request }
		);

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
		// Given North Hub looked up twice in the same request list
		TestDataFactory data = TestDataFactory.createDraftOrder();
		GetWarehouseDesk.Request first = new GetWarehouseDesk.Request();
		first.warehouseName = 'North Hub';
		GetWarehouseDesk.Request second = new GetWarehouseDesk.Request();
		second.warehouseName = 'North Hub';

		// When both desks are looked up together
		List<GetWarehouseDesk.Result> results = GetWarehouseDesk.execute(
			new List<GetWarehouseDesk.Request>{ first, second }
		);

		// Then each request gets the same North Hub snapshot
		System.assertEquals(2, results.size(), 'One result per request');
		System.assertEquals(data.warehouse.Id, results[0].warehouseId, 'First name lookup should resolve North Hub');
		System.assertEquals(data.warehouse.Id, results[1].warehouseId, 'Second name lookup should resolve North Hub');
		System.assertEquals(1, results[0].pendingUnassignedLines, 'Pending lines on first result');
		System.assertEquals(1, results[1].pendingUnassignedLines, 'Pending lines on second result');
	}
}
