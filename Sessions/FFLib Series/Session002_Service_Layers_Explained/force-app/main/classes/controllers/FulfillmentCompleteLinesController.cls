/**
 * Controller for the Complete Lines Lightning action.
 * Delegates to {@link FulfillmentService}.
 */
public inherited sharing class FulfillmentCompleteLinesController {
	/**
	 * Completes assigned lines on a fulfillment order through {@link FulfillmentService}.
	 * @param orderId Fulfillment Order Id. Cannot be null.
	 * @throws AuraHandledException when the service throws.
	 */
	@AuraEnabled(cacheable=false)
	public static void completeAssignedLines(Id orderId) {
		try {
			FulfillmentService.newInstance().completeAssignedLinesForOrders(new Set<Id>{ orderId });
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
