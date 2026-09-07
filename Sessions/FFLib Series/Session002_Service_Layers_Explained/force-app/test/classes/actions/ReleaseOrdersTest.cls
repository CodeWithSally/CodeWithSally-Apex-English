/**
 * Unit tests for {@link ReleaseOrders} using fflib-apex-mocks.
 */
@IsTest
private class ReleaseOrdersTest {
	@IsTest
	private static void executeCallsServiceAndReturnsOrderId() {
		// Given a stubbed fulfillment service and an order id
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		FulfillmentService mockService = (FulfillmentService) mocks.mock(FulfillmentService.class);
		Id orderId = TestIdGenerator.generate(FulfillmentOrder__c.SObjectType);
		FulfillmentService.mock = mockService;
		ReleaseOrders.Request request = new ReleaseOrders.Request();
		request.orderId = orderId;

		// When the invocable action is executed
		List<ReleaseOrders.Result> results = ReleaseOrders.execute(
			new List<ReleaseOrders.Request>{ request }
		);

		// Then the service is called and the order id is returned
		((FulfillmentService) mocks.verify(mockService)).releaseOrders(new Set<Id>{ orderId });
		System.assertEquals(1, results.size(), 'One result should be returned');
		System.assertEquals(orderId, results[0].orderId, 'Order Id should be returned');
	}

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
		FulfillmentOrdersSelector.mock = orderSelectorMock;
		FulfillmentService.mock = mockService;
		ReleaseOrders.Request request = new ReleaseOrders.Request();
		request.orderName = 'FO-00001';

		// When the invocable is called with the order name
		List<ReleaseOrders.Result> results = ReleaseOrders.execute(
			new List<ReleaseOrders.Request>{ request }
		);

		// Then the service receives the resolved Id
		((FulfillmentService) mocks.verify(mockService)).releaseOrders(new Set<Id>{ orderId });
		System.assertEquals('FO-00001', results[0].orderName, 'Order name should be returned');
		System.assertEquals(orderId, results[0].orderId, 'Resolved order Id should be returned');
	}
}
