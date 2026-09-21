/**
 * Controller that submits the Opportunity invoicing Batch Apex job from a headless Lightning action.
 */
public inherited sharing class OpportunityInvoicingController {
	/**
	 * Submits {@link CreateInvoicesJob} as a Batch Apex job from the Lightning action.
	 * @param recordId Current Opportunity Id from the record action (the job scans all ready Opportunities).
	 * @return Async Apex job Id.
	 */
	@AuraEnabled(cacheable=false)
	public static Id startJob(Id recordId) {
		try {
			return Database.executeBatch(new CreateInvoicesJob());
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
