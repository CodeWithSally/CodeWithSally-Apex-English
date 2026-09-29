/**
 * Controller for the Complete Maintenance Lightning action.
 * Delegates to {@link MaintenanceService}.
 *
 * Prefer the no-arg constructor / {@link #completeJob} for the default service.
 * Use the service constructor when composing deliberately (including tests).
 */
public inherited sharing class MaintenanceCompleteController {
	private final MaintenanceService maintenanceSvc;

	/**
	* Default composition: {@link MaintenanceService#newInstance}.
	*/
	public MaintenanceCompleteController() {
		this(MaintenanceService.newInstance());
	}

	/**
	* Creates a controller with the given service.
	* @param maintenanceSvc Maintenance service. Cannot be null.
	*/
	public MaintenanceCompleteController(MaintenanceService maintenanceSvc) {
		this.maintenanceSvc = maintenanceSvc;
	}

	/**
	* Completes a maintenance job through {@link MaintenanceService}.
	* @param jobId Maintenance Job Id. Cannot be null.
	* @throws AuraHandledException when the service throws.
	*/
	@AuraEnabled(cacheable=false)
	public static void completeJob(Id jobId) {
		new MaintenanceCompleteController().handleCompleteJob(jobId);
	}

	/**
	* Instance entry used by {@link #completeJob} and by callers that inject a service.
	* @param jobId Maintenance Job Id. Cannot be null.
	* @throws AuraHandledException when the service throws.
	*/
	public void handleCompleteJob(Id jobId) {
		try {
			maintenanceSvc.completeJobs(new Set<Id>{ jobId });
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
