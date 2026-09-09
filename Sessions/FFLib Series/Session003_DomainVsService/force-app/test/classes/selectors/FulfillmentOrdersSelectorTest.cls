/**
 * Integration tests for {@link FulfillmentOrdersSelector} against real rows.
 */
@IsTest
private class FulfillmentOrdersSelectorTest {
	@TestSetup
	static void setup() {
		TestDataFactory.createUserWithWarehousePermissions();
	}

	@IsTest
	private static void selectOpenByWarehouseWithLinesReturnsReleased() {
		// Given a run-as user with warehouse permissions
		User runAsUser = TestDataFactory.getRunAsUser();
		TestDataFactory data;
		System.runAs(runAsUser) {
			data = TestDataFactory.createDraftOrder();
			update new FulfillmentOrder__c(
				Id = data.order.Id,
				Status__c = FulfillmentOrders.STATUS_RELEASED
			);
		}

		// When open orders at that warehouse are queried
		List<FulfillmentOrder__c> orders;
		Integer emptyForNull;
		Test.startTest();
		System.runAs(runAsUser) {
			orders = FulfillmentOrdersSelector.newInstance()
				.selectOpenByWarehouseWithLines(data.warehouse.Id);
			emptyForNull = FulfillmentOrdersSelector.newInstance()
				.selectOpenByWarehouseWithLines(null)
				.size();
		}
		Test.stopTest();

		// Then the released order and its line are returned
		System.assertEquals(1, orders.size(), 'One open order');
		System.assertEquals(data.order.Id, orders[0].Id, 'Released order');
		System.assertEquals(1, orders[0].FulfillmentLines__r.size(), 'Nested line');
		System.assertEquals(0, emptyForNull, 'Null warehouse is empty');
	}
}
