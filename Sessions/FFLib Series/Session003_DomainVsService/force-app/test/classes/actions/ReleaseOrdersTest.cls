/**
 * Unit tests for {@link ReleaseOrders} using fflib-apex-mocks.
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs') // unit test: no DML
private class ReleaseOrdersTest {
	@IsTest
	private static void executeResolvesOrderName() {
		// Given a stubbed name lookup and fulfillment service
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		FulfillmentService mockService = (FulfillmentService) mocks.mock(FulfillmentService.class);
		FulfillmentOrdersSelector orderSelectorMock = (FulfillmentOrdersSelector) mocks.mock(
			FulfillmentOrdersSelector.class
		);
		Id orderId = TestIdGenerator.generate(FulfillmentOrder__c.SObjectType);
		FulfillmentOrder__c named = (FulfillmentOrder__c) JSON.deserialize(
			'{"attributes":{"type":"FulfillmentOrder__c"},"Id":"'
				+ orderId
				+ '","Name":"FO-00001"}',
			FulfillmentOrder__c.class
		);
		mocks.startStubbing();
		mocks.when(orderSelectorMock.selectByName(new Set<String>{ 'FO-00001' }))
			.thenReturn(new List<FulfillmentOrder__c>{ named });
		mocks.stopStubbing();
		ReleaseOrders.Request request = new ReleaseOrders.Request();
		request.orderName = 'FO-00001';

		// When the invocable is called with the order name
		List<ReleaseOrders.Result> results = new ReleaseOrders(mockService, orderSelectorMock)
			.handleExecute(new List<ReleaseOrders.Request>{ request });

		// Then the service receives the resolved Id and the name is echoed
		((FulfillmentService) mocks.verify(mockService)).releaseOrders(new Set<Id>{ orderId });
		System.assertEquals(1, results.size(), 'One result should be returned');
		System.assertEquals('FO-00001', results[0].orderName, 'Order name should be returned');
		System.assertEquals(orderId, results[0].orderId, 'Resolved order Id should be returned');
	}
}
