/**
 * Integration tests for {@link WarehouseService} against real rows.
 */
@IsTest
private class WarehouseServiceTest {
	@TestSetup
	static void setup() {
		TestDataFactory.createUserWithWarehousePermissions();
	}

	@IsTest
	private static void summariesDescribesNorthHub() {
		// Given a run-as user with warehouse permissions
		User runAsUser = TestDataFactory.getRunAsUser();
		TestDataFactory data;
		FulfillmentOrder__c named;
		System.runAs(runAsUser) {
			data = TestDataFactory.createDraftOrder();
			named = [SELECT Name FROM FulfillmentOrder__c WHERE Id = :data.order.Id];
		}

		// When the desk snapshot is requested
		List<WarehouseService.Summary> summaries;
		Test.startTest();
		System.runAs(runAsUser) {
			summaries = WarehouseService.newInstance().summaries(new List<String>{ 'North Hub' });
		}
		Test.stopTest();

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
