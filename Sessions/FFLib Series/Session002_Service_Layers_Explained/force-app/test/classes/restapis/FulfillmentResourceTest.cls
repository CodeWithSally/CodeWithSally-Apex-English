/**
 * Unit tests for {@link FulfillmentResource} using fflib-apex-mocks.
 */
@IsTest
private class FulfillmentResourceTest {
	@IsTest
	private static void postReleaseCallsFulfillmentService() {
		// Given a stubbed fulfillment service and order Ids in the POST body
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		FulfillmentService mockService = (FulfillmentService) mocks.mock(FulfillmentService.class);
		Id orderId = TestIdGenerator.generate(FulfillmentOrder__c.SObjectType);
		FulfillmentService.mock = mockService;

		// When POST /warehouse/fulfillment/release is invoked
		post('release', '{"orderIds":["' + orderId + '"]}');

		// Then releaseOrders receives those Ids
		((FulfillmentService) mocks.verify(mockService)).releaseOrders(new Set<Id>{ orderId });
	}

	@IsTest
	private static void postDispatchCallsDispatchService() {
		// Given a stubbed dispatch service and warehouse Ids in the POST body
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		DispatchService mockService = (DispatchService) mocks.mock(DispatchService.class);
		Id warehouseId = TestIdGenerator.generate(Warehouse__c.SObjectType);
		DispatchService.mock = mockService;

		// When POST /warehouse/fulfillment/dispatch is invoked
		post('dispatch', '{"warehouseIds":["' + warehouseId + '"]}');

		// Then dispatchWarehouses receives those Ids
		((DispatchService) mocks.verify(mockService)).dispatchWarehouses(new Set<Id>{ warehouseId });
	}

	@IsTest
	private static void postCompleteCallsFulfillmentService() {
		// Given a stubbed fulfillment service and line Ids in the POST body
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		FulfillmentService mockService = (FulfillmentService) mocks.mock(FulfillmentService.class);
		Id lineId = TestIdGenerator.generate(FulfillmentLine__c.SObjectType);
		FulfillmentService.mock = mockService;

		// When POST /warehouse/fulfillment/complete is invoked
		post('complete', '{"lineIds":["' + lineId + '"]}');

		// Then completeLines receives those Ids
		((FulfillmentService) mocks.verify(mockService)).completeLines(new Set<Id>{ lineId });
	}

	@IsTest
	private static void postUnknownActionThrows() {
		// Given a POST to an action the resource does not route
		Boolean thrown = false;

		// When that path is invoked
		try {
			post('hold', '{}');
		} catch (FulfillmentService.FulfillmentServiceException e) {
			thrown = true;
			System.assert(
				e.getMessage().contains('Unknown fulfillment action: hold'),
				'Exception names the unknown action'
			);
		}

		// Then the resource rejects it without calling a service
		System.assertEquals(true, thrown, 'Unknown action should throw');
	}

	private static void post(String action, String jsonBody) {
		RestRequest request = new RestRequest();
		request.requestURI = '/warehouse/fulfillment/' + action;
		request.httpMethod = 'POST';
		request.requestBody = Blob.valueOf(jsonBody);
		RestContext.request = request;
		RestContext.response = new RestResponse();
		FulfillmentResource.post();
	}
}
