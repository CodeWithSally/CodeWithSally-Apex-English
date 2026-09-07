/**
 * Domain tests for FulfillmentOrders.
 */
@IsTest
private class FulfillmentOrdersTest {
	@IsTest
	private static void releaseRequiresDraftAndLines() {
		// Given a draft order with one pending line
		FulfillmentOrder__c order = new FulfillmentOrder__c(
			Id = TestIdGenerator.generate(FulfillmentOrder__c.SObjectType),
			Status__c = FulfillmentOrders.STATUS_DRAFT
		);
		order = (FulfillmentOrder__c) JSON.deserialize(
			'{"attributes":{"type":"FulfillmentOrder__c"},"Id":"'
				+ order.Id
				+ '","Name":"FO-1","Status__c":"Draft","FulfillmentLines__r":{"totalSize":1,"done":true,"records":['
				+ '{"attributes":{"type":"FulfillmentLine__c"},"Id":"'
				+ TestIdGenerator.generate(FulfillmentLine__c.SObjectType)
				+ '","Status__c":"Pending"}]}}',
			FulfillmentOrder__c.class
		);
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		fflib_SObjectUnitOfWork uowMock = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);

		// When the order is released
		FulfillmentOrders.newInstance(new List<FulfillmentOrder__c>{ order }).release(uowMock);

		// Then the order status is Released
		System.assertEquals(FulfillmentOrders.STATUS_RELEASED, order.Status__c, 'Should be released');
	}

	@IsTest
	private static void completeClosesWhenLinesAreDone() {
		// Given an in-progress order whose only line is already complete
		Id orderId = TestIdGenerator.generate(FulfillmentOrder__c.SObjectType);
		Id lineId = TestIdGenerator.generate(FulfillmentLine__c.SObjectType);
		FulfillmentOrder__c order = (FulfillmentOrder__c) JSON.deserialize(
			'{"attributes":{"type":"FulfillmentOrder__c"},"Id":"'
				+ orderId
				+ '","Name":"FO-1","Status__c":"In Progress","FulfillmentLines__r":{"totalSize":1,"done":true,"records":['
				+ '{"attributes":{"type":"FulfillmentLine__c"},"Id":"'
				+ lineId
				+ '","Status__c":"Complete"}]}}',
			FulfillmentOrder__c.class
		);
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		fflib_SObjectUnitOfWork uowMock = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);

		// When complete is invoked
		FulfillmentOrders.newInstance(new List<FulfillmentOrder__c>{ order }).complete(uowMock);

		// Then the order is Completed
		System.assertEquals(FulfillmentOrders.STATUS_COMPLETED, order.Status__c, 'Should complete');
	}

	@IsTest
	private static void completeTreatsCompletingIdsAsDone() {
		// Given an in-progress order whose nested line is still Assigned
		Id orderId = TestIdGenerator.generate(FulfillmentOrder__c.SObjectType);
		Id lineId = TestIdGenerator.generate(FulfillmentLine__c.SObjectType);
		FulfillmentOrder__c order = (FulfillmentOrder__c) JSON.deserialize(
			'{"attributes":{"type":"FulfillmentOrder__c"},"Id":"'
				+ orderId
				+ '","Name":"FO-1","Status__c":"In Progress","FulfillmentLines__r":{"totalSize":1,"done":true,"records":['
				+ '{"attributes":{"type":"FulfillmentLine__c"},"Id":"'
				+ lineId
				+ '","Status__c":"Assigned"}]}}',
			FulfillmentOrder__c.class
		);
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		fflib_SObjectUnitOfWork uowMock = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);

		// When complete is told that line is completing in this commit
		FulfillmentOrders.newInstance(new List<FulfillmentOrder__c>{ order })
			.complete(uowMock, new Set<Id>{ lineId });

		// Then the order is Completed
		System.assertEquals(FulfillmentOrders.STATUS_COMPLETED, order.Status__c, 'Completing Ids count as done');
	}

	@IsTest
	private static void completeSkipsOnHold() {
		// Given an on-hold order whose only line is already complete
		Id orderId = TestIdGenerator.generate(FulfillmentOrder__c.SObjectType);
		Id lineId = TestIdGenerator.generate(FulfillmentLine__c.SObjectType);
		FulfillmentOrder__c order = (FulfillmentOrder__c) JSON.deserialize(
			'{"attributes":{"type":"FulfillmentOrder__c"},"Id":"'
				+ orderId
				+ '","Name":"FO-1","Status__c":"On Hold","FulfillmentLines__r":{"totalSize":1,"done":true,"records":['
				+ '{"attributes":{"type":"FulfillmentLine__c"},"Id":"'
				+ lineId
				+ '","Status__c":"Complete"}]}}',
			FulfillmentOrder__c.class
		);
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		fflib_SObjectUnitOfWork uowMock = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);

		// When complete is invoked
		FulfillmentOrders.newInstance(new List<FulfillmentOrder__c>{ order }).complete(uowMock);

		// Then the order stays On Hold
		System.assertEquals(FulfillmentOrders.STATUS_ON_HOLD, order.Status__c, 'On Hold should not close');
	}

	@IsTest
	private static void unholdReturnsToReleased() {
		// Given an on-hold order
		FulfillmentOrder__c order = new FulfillmentOrder__c(
			Id = TestIdGenerator.generate(FulfillmentOrder__c.SObjectType),
			Status__c = FulfillmentOrders.STATUS_ON_HOLD
		);
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		fflib_SObjectUnitOfWork uowMock = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);

		// When the order is unheld
		FulfillmentOrders.newInstance(new List<FulfillmentOrder__c>{ order }).unhold(uowMock);

		// Then the order is Released
		System.assertEquals(FulfillmentOrders.STATUS_RELEASED, order.Status__c, 'Should return to Released');
	}
}
