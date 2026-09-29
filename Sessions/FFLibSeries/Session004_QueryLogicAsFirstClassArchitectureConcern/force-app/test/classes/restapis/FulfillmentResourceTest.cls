/**
 * Unit tests for {@link FulfillmentResource} using fflib-apex-mocks.
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts, PMD.ApexUnitTestClassShouldHaveRunAs') // unit test: ApexMocks verify is the assertion; no DML
private class FulfillmentResourceTest {
	@IsTest
	private static void postReleaseCallsFulfillmentService() {
		// Given a stubbed fulfillment service and order Ids in the POST body
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		FulfillmentService mockService = (FulfillmentService) mocks.mock(FulfillmentService.class);
		DispatchService dispatchMock = (DispatchService) mocks.mock(DispatchService.class);
		Id orderId = TestIdGenerator.generate(FulfillmentOrder__c.SObjectType);

		// When POST /warehouse/fulfillment/release is invoked
		preparePost('release', '{"orderIds":["' + orderId + '"]}');
		new FulfillmentResource(mockService, dispatchMock).handlePost();

		// Then releaseOrders receives those Ids
		((FulfillmentService) mocks.verify(mockService)).releaseOrders(new Set<Id>{ orderId });
	}

	@IsTest
	private static void postDispatchCallsDispatchService() {
		// Given a stubbed dispatch service and warehouse Ids in the POST body
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		FulfillmentService fulfillmentMock = (FulfillmentService) mocks.mock(FulfillmentService.class);
		DispatchService mockService = (DispatchService) mocks.mock(DispatchService.class);
		Id warehouseId = TestIdGenerator.generate(Warehouse__c.SObjectType);

		// When POST /warehouse/fulfillment/dispatch is invoked
		preparePost('dispatch', '{"warehouseIds":["' + warehouseId + '"]}');
		new FulfillmentResource(fulfillmentMock, mockService).handlePost();

		// Then dispatchWarehouses receives those Ids
		((DispatchService) mocks.verify(mockService)).dispatchWarehouses(new Set<Id>{ warehouseId });
	}

	@IsTest
	private static void postCompleteCallsFulfillmentService() {
		// Given a stubbed fulfillment service and line Ids in the POST body
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		FulfillmentService mockService = (FulfillmentService) mocks.mock(FulfillmentService.class);
		DispatchService dispatchMock = (DispatchService) mocks.mock(DispatchService.class);
		Id lineId = TestIdGenerator.generate(FulfillmentLine__c.SObjectType);

		// When POST /warehouse/fulfillment/complete is invoked
		preparePost('complete', '{"lineIds":["' + lineId + '"]}');
		new FulfillmentResource(mockService, dispatchMock).handlePost();

		// Then completeLines receives those Ids
		((FulfillmentService) mocks.verify(mockService)).completeLines(new Set<Id>{ lineId });
	}

	@IsTest
	private static void postUnknownActionThrows() {
		// Given a POST to an action the resource does not route
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		FulfillmentService fulfillmentMock = (FulfillmentService) mocks.mock(FulfillmentService.class);
		DispatchService dispatchMock = (DispatchService) mocks.mock(DispatchService.class);
		Boolean thrown = false;

		// When that path is invoked
		try {
			preparePost('hold', '{}');
			new FulfillmentResource(fulfillmentMock, dispatchMock).handlePost();
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

	private static void preparePost(String action, String jsonBody) {
		RestRequest request = new RestRequest();
		request.requestURI = '/warehouse/fulfillment/' + action;
		request.httpMethod = 'POST';
		request.requestBody = Blob.valueOf(jsonBody);
		RestContext.request = request;
		RestContext.response = new RestResponse();
	}
}
