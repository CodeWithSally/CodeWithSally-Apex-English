/**
 * Batch job that dispatches active warehouses via {@link DispatchService#dispatchWarehouses}.
 * One service call per chunk — same shape as {@code CreateInvoicesJob}.
 */
public inherited sharing class DispatchPendingJob
	implements System.Schedulable, Database.Batchable<SObject>, Database.Stateful
{
	private List<JobError> jobErrors = new List<JobError>();

	/**
	 * Starts a batch of this job from the scheduler.
	 * @param sc Scheduler context provided by the platform.
	 */
	public void execute(SchedulableContext sc) {
		Database.executeBatch(new DispatchPendingJob());
	}

	/**
	 * Queries active warehouses for dispatch.
	 * @param context Batch context provided by the platform.
	 * @return Query locator of active warehouses.
	 */
	public Database.QueryLocator start(Database.BatchableContext context) {
		return WarehousesSelector.newInstance().selectActiveAsQueryLocator();
	}

	/**
	 * Dispatches the warehouses in this chunk through {@link DispatchService}.
	 * @param context Batch context provided by the platform.
	 * @param warehouses Active warehouses in this chunk.
	 */
	public void execute(Database.BatchableContext context, List<Warehouse__c> warehouses) {
		try {
			DispatchService.newInstance().dispatchWarehouses(new Map<Id, Warehouse__c>(warehouses).keySet());
		} catch (Exception e) {
			JobError jobError = new JobError();
			jobError.records = warehouses;
			jobError.message = e.getMessage();
			jobErrors.add(jobError);
		}
	}

	/**
	 * Emails chunk failures to the running user when any chunk threw.
	 * @param context Batch context provided by the platform.
	 */
	public void finish(Database.BatchableContext context) {
		if (jobErrors.isEmpty()) {
			return;
		}
		String emailBody = '';
		for (JobError jobError : jobErrors) {
			List<String> names = new List<String>();
			for (Warehouse__c warehouse : jobError.records) {
				names.add(warehouse.Name);
			}
			emailBody += String.format(
				'<p>Error {0} occurred during dispatch of Warehouses {1}</p>',
				new List<String>{ jobError.message, String.join(names, ',') }
			);
		}
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setTargetObjectId(UserInfo.getUserId());
		mail.setSaveAsActivity(false);
		mail.setSubject('Dispatch Pending Job Failures');
		mail.setHtmlBody(emailBody);
		Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
	}

	/**
	 * Failure recorded for one batch chunk so {@link #finish} can email it.
	 */
	public class JobError {
		/** Exception message from the failed dispatch. */
		public String message;
		/** Warehouses in the failed chunk. */
		public List<Warehouse__c> records;
	}
}
