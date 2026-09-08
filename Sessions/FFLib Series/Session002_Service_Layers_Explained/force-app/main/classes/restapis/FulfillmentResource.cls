/**
 * REST resource for warehouse fulfillment operations.
 * Path pattern: {@code /warehouse/fulfillment/{action}}.
 * POST body is JSON with the Id collection for that action.
 *
 * Prefer the no-arg constructor / {@link #post} for the default services.
 * Use the service constructor when composing deliberately (including tests).
 */
@RestResource(UrlMapping='/warehouse/fulfillment/*')
global inherited sharing class FulfillmentResource {
	private final FulfillmentService fulfillmentSvc;
	private final DispatchService dispatchSvc;

	/**
	* Default composition: {@link FulfillmentService#newInstance} and {@link DispatchService#newInstance}.
	*/
	public FulfillmentResource() {
		this(FulfillmentService.newInstance(), DispatchService.newInstance());
	}

	/**
	* Creates a resource with the given services.
	* @param fulfillmentSvc Fulfillment service. Cannot be null.
	* @param dispatchSvc Dispatch service. Cannot be null.
	*/
	public FulfillmentResource(FulfillmentService fulfillmentSvc, DispatchService dispatchSvc) {
		this.fulfillmentSvc = fulfillmentSvc;
		this.dispatchSvc = dispatchSvc;
	}

	/**
	* Routes a POST to release, dispatch, or complete.
	* Path: {@code /warehouse/fulfillment/release} with {@code {"orderIds":["…"]}}.
	* Path: {@code /warehouse/fulfillment/dispatch} with {@code {"warehouseIds":["…"]}}.
	* Path: {@code /warehouse/fulfillment/complete} with {@code {"lineIds":["…"]}}.
	* @throws FulfillmentService.FulfillmentServiceException when the action is unknown or a service fails.
	*/
	@HttpPost
	global static void post() {
		new FulfillmentResource().handlePost();
	}

	/**
	* Instance entry used by {@link #post} and by callers that inject services.
	*/
	public void handlePost() {
		RestRequest req = RestContext.request;
		String[] uriParts = req.requestURI.split('/');
		String action = uriParts[uriParts.size() - 1];
		Request body = parseBody(req);
		switch on action {
			when 'release' {
				fulfillmentSvc.releaseOrders(idSet(body.orderIds));
			}
			when 'dispatch' {
				dispatchSvc.dispatchWarehouses(idSet(body.warehouseIds));
			}
			when 'complete' {
				fulfillmentSvc.completeLines(idSet(body.lineIds));
			}
			when else {
				throw new FulfillmentService.FulfillmentServiceException(
					'Unknown fulfillment action: ' + action
				);
			}
		}
	}

	private static Request parseBody(RestRequest req) {
		String jsonBody = req.requestBody == null ? '{}' : req.requestBody.toString();
		if (String.isBlank(jsonBody)) {
			jsonBody = '{}';
		}
		return (Request) JSON.deserialize(jsonBody, Request.class);
	}

	private static Set<Id> idSet(List<Id> ids) {
		return ids == null ? new Set<Id>() : new Set<Id>(ids);
	}

	/**
	* JSON body for {@link #post}. Populate the collection that matches the URL action.
	*/
	public class Request {
		/** Fulfillment Order Ids for the release action. */
		public List<Id> orderIds;
		/** Warehouse Ids for the dispatch action. */
		public List<Id> warehouseIds;
		/** Fulfillment Line Ids for the complete action. */
		public List<Id> lineIds;
	}
}
