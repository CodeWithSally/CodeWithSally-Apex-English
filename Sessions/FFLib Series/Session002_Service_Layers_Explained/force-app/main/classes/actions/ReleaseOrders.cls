/**
 * Invocable action that releases draft fulfillment orders.
 * Delegates to {@link FulfillmentService}. Accepts an order name or Id.
 */
public inherited sharing class ReleaseOrders {
	/**
	 * Releases draft fulfillment orders through {@link FulfillmentService}.
	 * @param requests Invocable requests, each with a fulfillment order name or Id.
	 * @return One result per request, echoing the order that was released.
	 */
	@InvocableMethod(
		label='Release Fulfillment Orders'
		description='Releases draft fulfillment orders so they can be dispatched. Pass an order name such as FO-00001.'
		category='Warehouse Operations'
	)
	public static List<Result> execute(List<Request> requests) {
		// Resolve names to Ids when the caller did not pass Ids
		Map<String, FulfillmentOrder__c> orderByName = ordersByName(requests);
		List<Id> resolvedIds = new List<Id>();
		for (Request request : requests) {
			resolvedIds.add(resolveOrderId(request, orderByName));
		}

		FulfillmentService.newInstance().releaseOrders(new Set<Id>(resolvedIds));

		List<Result> results = new List<Result>();
		for (Integer i = 0; i < requests.size(); i++) {
			Result result = new Result();
			result.orderId = resolvedIds[i];
			result.orderName = requests[i].orderName;
			if (String.isNotBlank(requests[i].orderName)) {
				FulfillmentOrder__c order = orderByName.get(requests[i].orderName.trim());
				if (order != null) {
					result.orderName = order.Name;
				}
			}
			results.add(result);
		}
		return results;
	}

	private static Map<String, FulfillmentOrder__c> ordersByName(List<Request> requests) {
		Set<String> names = new Set<String>();
		for (Request request : requests) {
			if (request.orderId == null && String.isNotBlank(request.orderName)) {
				names.add(request.orderName.trim());
			}
		}
		Map<String, FulfillmentOrder__c> orderByName = new Map<String, FulfillmentOrder__c>();
		for (FulfillmentOrder__c order : FulfillmentOrdersSelector.newInstance().selectByName(names)) {
			orderByName.put(order.Name, order);
		}
		return orderByName;
	}

	private static Id resolveOrderId(Request request, Map<String, FulfillmentOrder__c> orderByName) {
		if (request.orderId != null) {
			return request.orderId;
		}
		if (String.isBlank(request.orderName)) {
			throw new ReleaseOrdersException('Give a fulfillment order name, for example FO-00001.');
		}
		FulfillmentOrder__c order = orderByName.get(request.orderName.trim());
		if (order == null) {
			throw new ReleaseOrdersException('No fulfillment order named ' + request.orderName.trim() + '.');
		}
		return order.Id;
	}

	/**
	 * Invocable request for {@link ReleaseOrders#execute}.
	 */
	public class Request {
		/**
		 * Order name, for example FO-00001.
		 */
		@InvocableVariable(label='Fulfillment Order Name')
		public String orderName;

		/**
		 * Id of the fulfillment order to release when the name is not used.
		 */
		@InvocableVariable(label='Fulfillment Order Id')
		public Id orderId;
	}

	/**
	 * Invocable result for {@link ReleaseOrders#execute}.
	 */
	public class Result {
		@InvocableVariable(label='Fulfillment Order Name')
		public String orderName;
		@InvocableVariable(label='Fulfillment Order Id')
		public Id orderId;
	}

	/**
	 * Thrown when the order cannot be resolved.
	 */
	public class ReleaseOrdersException extends Exception {
	}
}
