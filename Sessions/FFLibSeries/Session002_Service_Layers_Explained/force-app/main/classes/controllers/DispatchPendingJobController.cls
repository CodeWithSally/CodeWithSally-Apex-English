/**
 * Controller that submits warehouse dispatch Batch Apex from a headless Lightning action.
 *
 * Prefer the no-arg constructor / {@link #startJob} for the default service.
 * Use the service constructor when composing deliberately (including tests).
 */
public inherited sharing class DispatchPendingJobController {
	private final DispatchService dispatchSvc;

	/**
	* Default composition: {@link DispatchService#newInstance}.
	*/
	public DispatchPendingJobController() {
		this(DispatchService.newInstance());
	}

	/**
	* Creates a controller with the given service.
	* @param dispatchSvc Dispatch service. Cannot be null.
	*/
	public DispatchPendingJobController(DispatchService dispatchSvc) {
		this.dispatchSvc = dispatchSvc;
	}

	/**
	* Submits {@link DispatchPendingJob} through {@link DispatchService}.
	* @return Batch job Id.
	* @throws AuraHandledException when the service throws.
	*/
	@AuraEnabled(cacheable=false)
	public static Id startJob() {
		return new DispatchPendingJobController().handleStartJob();
	}

	/**
	* Instance entry used by {@link #startJob} and by callers that inject a service.
	* @return Batch job Id.
	* @throws AuraHandledException when the service throws.
	*/
	public Id handleStartJob() {
		try {
			return dispatchSvc.submitDispatchJob();
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
