/**
 * Invocable action that releases draft fulfillment orders.
 * Delegates to {@link FulfillmentService}. Accepts an order name.
 *
 * Prefer the no-arg constructor / {@link #execute} for the default service.
 * Use the service constructor when composing deliberately (including tests).
 */
public inherited sharing class ReleaseOrders {
	private final FulfillmentService fulfillmentSvc;
	private final FulfillmentOrdersSelector orderSelector;

	/**
	* Default composition: {@link FulfillmentService#newInstance} and {@link FulfillmentOrdersSelector#newInstance}.
	*/
	public ReleaseOrders() {
		this(FulfillmentService.newInstance(), FulfillmentOrdersSelector.newInstance());
	}

	/**
	* Creates an action with the given service and selector.
	* @param fulfillmentSvc Fulfillment service. Cannot be null.
	* @param orderSelector Order selector used to resolve names. Cannot be null.
	*/
	public ReleaseOrders(FulfillmentService fulfillmentSvc, FulfillmentOrdersSelector orderSelector) {
		this.fulfillmentSvc = fulfillmentSvc;
		this.orderSelector = orderSelector;
	}

	/**
	* Releases draft fulfillment orders through {@link FulfillmentService}.
	* @param requests Invocable requests, each with a fulfillment order name.
	* @return One result per request, with the order name and resolved Id.
	*/
	@InvocableMethod(
		label='Release Fulfillment Orders'
		description='Releases draft fulfillment orders so they can be dispatched. Pass an order name such as FO-00001.'
		category='Warehouse Operations'
	)
	public static List<Result> execute(List<Request> requests) {
		return new ReleaseOrders().handleExecute(requests);
	}

	/**
	* Instance entry used by {@link #execute} and by callers that inject collaborators.
	* @param requests Invocable requests, each with a fulfillment order name.
	* @return One result per request, with the order name and resolved Id.
	*/
	public List<Result> handleExecute(List<Request> requests) {

		// Resolve the order names to Ids
		Set<String> names = new Set<String>();
		for (Request request : requests) {
			names.add(request.orderName.trim());
		}
		Map<String, Id> orderIdByName = new Map<String, Id>();
		for (FulfillmentOrder__c order : orderSelector.selectByName(names)) {
			orderIdByName.put(order.Name, order.Id);
		}
		for (String name : names) {
			if (!orderIdByName.containsKey(name)) {
				throw new ReleaseOrdersException('No fulfillment order named ' + name + '.');
			}
		}

		// Release the orders
		fulfillmentSvc.releaseOrders(new Set<Id>(orderIdByName.values()));

		// Build the results
		List<Result> results = new List<Result>();
		for (Request request : requests) {
			Result result = new Result();
			result.orderName = request.orderName.trim();
			result.orderId = orderIdByName.get(result.orderName);
			results.add(result);
		}
		return results;
	}

	/**
	* Invocable request for {@link ReleaseOrders#execute}.
	*/
	public class Request {
		/**
		* Order name, for example FO-00001.
		*/
		@InvocableVariable(label='Fulfillment Order Name' required=true)
		public String orderName;
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
