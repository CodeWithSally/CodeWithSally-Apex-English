/**
 * Controller for the Release Order Lightning action.
 * Delegates to {@link FulfillmentService}.
 *
 * Prefer the no-arg constructor / {@link #releaseOrder} for the default service.
 * Use the service constructor when composing deliberately (including tests).
 */
public inherited sharing class FulfillmentReleaseController {
	private final FulfillmentService fulfillmentSvc;

	/**
	* Default composition: {@link FulfillmentService#newInstance}.
	*/
	public FulfillmentReleaseController() {
		this(FulfillmentService.newInstance());
	}

	/**
	* Creates a controller with the given service.
	* @param fulfillmentSvc Fulfillment service. Cannot be null.
	*/
	public FulfillmentReleaseController(FulfillmentService fulfillmentSvc) {
		this.fulfillmentSvc = fulfillmentSvc;
	}

	/**
	* Releases a draft fulfillment order through {@link FulfillmentService}.
	* @param orderId Fulfillment Order Id. Cannot be null.
	* @throws AuraHandledException when the service throws.
	*/
	@AuraEnabled(cacheable=false)
	public static void releaseOrder(Id orderId) {
		new FulfillmentReleaseController().handleReleaseOrder(orderId);
	}

	/**
	* Instance entry used by {@link #releaseOrder} and by callers that inject a service.
	* @param orderId Fulfillment Order Id. Cannot be null.
	* @throws AuraHandledException when the service throws.
	*/
	public void handleReleaseOrder(Id orderId) {
		try {
			fulfillmentSvc.releaseOrders(new Set<Id>{ orderId });
		} catch (Exception e) {
			throw toAura(e);
		}
	}

	private static AuraHandledException toAura(Exception e) {
		AuraHandledException auraException = new AuraHandledException(e.getMessage());
		auraException.setMessage(e.getMessage());
		return auraException;
	}
}
