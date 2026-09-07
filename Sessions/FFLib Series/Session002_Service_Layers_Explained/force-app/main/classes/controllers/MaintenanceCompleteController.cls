/**
 * Controller for the Complete Maintenance Lightning action.
 * Delegates to {@link MaintenanceService}.
 */
public inherited sharing class MaintenanceCompleteController {
	/**
	 * Completes a maintenance job through {@link MaintenanceService}.
	 * @param jobId Maintenance Job Id. Cannot be null.
	 * @throws AuraHandledException when the service throws.
	 */
	@AuraEnabled(cacheable=false)
	public static void completeJob(Id jobId) {
		try {
			MaintenanceService.newInstance().completeJobs(new Set<Id>{ jobId });
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
