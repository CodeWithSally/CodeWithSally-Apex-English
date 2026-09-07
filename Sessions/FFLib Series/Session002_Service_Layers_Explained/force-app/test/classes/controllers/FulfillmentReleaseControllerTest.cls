/**
 * Unit tests for FulfillmentReleaseController using fflib-apex-mocks.
 */
@IsTest
private class FulfillmentReleaseControllerTest {
	@IsTest
	private static void releaseOrderCallsService() {
		// Given a stubbed fulfillment service and an order id
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		FulfillmentService mockService = (FulfillmentService) mocks.mock(FulfillmentService.class);
		Id orderId = TestIdGenerator.generate(FulfillmentOrder__c.SObjectType);
		FulfillmentService.mock = mockService;

		// When release is invoked from the Lightning action
		FulfillmentReleaseController.releaseOrder(orderId);

		// Then the service is called with the order id
		((FulfillmentService) mocks.verify(mockService)).releaseOrders(new Set<Id>{ orderId });
	}
}
