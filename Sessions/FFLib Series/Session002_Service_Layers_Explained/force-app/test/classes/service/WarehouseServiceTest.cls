/**
 * Tests for {@link WarehouseService}.
 */
@IsTest
private class WarehouseServiceTest {
	@IsTest
	private static void summariesDescribesNorthHub() {
		// Given North Hub with one pending draft line and one idle robot
		TestDataFactory data = TestDataFactory.createDraftOrder();
		FulfillmentOrder__c named = [SELECT Name FROM FulfillmentOrder__c WHERE Id = :data.order.Id];

		// When the desk snapshot is requested
		List<WarehouseService.Summary> summaries = WarehouseService.newInstance()
			.summaries(new List<String>{ 'North Hub' });

		// Then pending work, idle robots, and the draft name are returned
		System.assertEquals(1, summaries.size(), 'One warehouse summary');
		System.assertEquals('North Hub', summaries[0].warehouseName, 'Warehouse name');
		System.assertEquals(data.warehouse.Id, summaries[0].warehouseId, 'Warehouse Id');
		System.assertEquals(1, summaries[0].pendingUnassignedLines, 'One pending line');
		System.assertEquals(1, summaries[0].idleAvailableRobots, 'One available robot');
		System.assertEquals(0, summaries[0].robotShortfall, 'No shortfall');
		System.assertEquals(named.Name, summaries[0].draftOrderNames, 'Draft order name');
	}
}
