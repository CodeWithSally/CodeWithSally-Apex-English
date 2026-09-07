/**
 * Controller that submits warehouse dispatch Batch Apex from a headless Lightning action.
 */
public inherited sharing class DispatchPendingJobController {
	/**
	 * Submits {@link DispatchPendingJob} through {@link DispatchService}.
	 * @return Batch job Id.
	 * @throws AuraHandledException when the service throws.
	 */
	@AuraEnabled(cacheable=false)
	public static Id startJob() {
		try {
			return DispatchService.newInstance().submitDispatchJob();
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
