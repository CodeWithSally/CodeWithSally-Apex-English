/**
 * Controller that submits the Opportunity invoicing Batch Apex job from a headless Lightning action.
 */
public inherited sharing class OpportunityInvoicingController {
	/**
	 * Submits {@link CreateInvoicesJob} through {@link OpportunitiesService#submitInvoicingJob}.
	 * @return Async Apex job Id returned after a successful submit.
	 */
	@AuraEnabled(cacheable=false)
	public static Id startJob() {
		try {
			return OpportunitiesService.newInstance().submitInvoicingJob();
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
