/**
 * Controller for the Complete Lines Lightning action.
 * Delegates to {@link FulfillmentService}.
 *
 * Prefer the no-arg constructor / {@link #completeAssignedLines} for the default service.
 * Use the service constructor when composing deliberately (including tests).
 */
public inherited sharing class FulfillmentCompleteLinesController {
	private final FulfillmentService fulfillmentSvc;

	/**
	* Default composition: {@link FulfillmentService#newInstance}.
	*/
	public FulfillmentCompleteLinesController() {
		this(FulfillmentService.newInstance());
	}

	/**
	* Creates a controller with the given service.
	* @param fulfillmentSvc Fulfillment service. Cannot be null.
	*/
	public FulfillmentCompleteLinesController(FulfillmentService fulfillmentSvc) {
		this.fulfillmentSvc = fulfillmentSvc;
	}

	/**
	* Completes assigned lines on a fulfillment order through {@link FulfillmentService}.
	* @param orderId Fulfillment Order Id. Cannot be null.
	* @throws AuraHandledException when the service throws.
	*/
	@AuraEnabled(cacheable=false)
	public static void completeAssignedLines(Id orderId) {
		new FulfillmentCompleteLinesController().handleCompleteAssignedLines(orderId);
	}

	/**
	* Instance entry used by {@link #completeAssignedLines} and by callers that inject a service.
	* @param orderId Fulfillment Order Id. Cannot be null.
	* @throws AuraHandledException when the service throws.
	*/
	public void handleCompleteAssignedLines(Id orderId) {
		try {
			fulfillmentSvc.completeAssignedLinesForOrders(new Set<Id>{ orderId });
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
