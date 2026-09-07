/**
 * Selector tests for FulfillmentOrdersSelector.
 */
@IsTest
private class FulfillmentOrdersSelectorTest {
	@IsTest
	private static void selectOpenByWarehouseWithLinesReturnsReleased() {
		// Given a released order with a pending line at North Hub
		TestDataFactory data = TestDataFactory.createDraftOrder();
		update new FulfillmentOrder__c(
			Id = data.order.Id,
			Status__c = FulfillmentOrders.STATUS_RELEASED
		);

		// When open orders at that warehouse are queried
		List<FulfillmentOrder__c> orders = FulfillmentOrdersSelector.newInstance()
			.selectOpenByWarehouseWithLines(data.warehouse.Id);

		// Then the released order and its line are returned
		System.assertEquals(1, orders.size(), 'One open order');
		System.assertEquals(data.order.Id, orders[0].Id, 'Released order');
		System.assertEquals(1, orders[0].FulfillmentLines__r.size(), 'Nested line');
		System.assertEquals(
			0,
			FulfillmentOrdersSelector.newInstance().selectOpenByWarehouseWithLines(null).size(),
			'Null warehouse is empty'
		);
	}
}
