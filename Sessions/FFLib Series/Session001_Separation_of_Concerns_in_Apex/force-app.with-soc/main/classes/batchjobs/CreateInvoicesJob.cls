/**
 * Batch and schedulable job that invoices Opportunities marked Ready via {@link OpportunitiesService}.
 * Accumulates per-chunk failures and emails the running user on finish.
 */
public inherited sharing class CreateInvoicesJob
	implements System.Schedulable, Database.Batchable<SObject>, Database.Stateful {

	private List<JobError> jobErrors = new List<JobError>();

	/**
	 * Schedulable entry point that starts a new batch instance of this job.
	 * @param sc Schedulable context provided by the platform.
	 */
	public void execute(SchedulableContext sc) {
		Database.executeBatch(new CreateInvoicesJob());
	}

	/**
	 * Starts the batch using Opportunities with InvoicedStatus__c Ready.
	 * @param context Batchable context provided by the platform.
	 * @return QueryLocator from {@link OpportunitiesSelector#readyToInvoiceAsQueryLocator}.
	 */
	public Database.QueryLocator start(Database.BatchableContext context) {
		return OpportunitiesSelector.newInstance().readyToInvoiceAsQueryLocator();
	}

	/**
	 * Creates invoices for the current chunk of Opportunities with zero discount.
	 * Failures are captured in {@link JobError} without failing the entire batch.
	 * @param context Batchable context provided by the platform.
	 * @param opps Opportunity chunk to invoice.
	 */
	public void execute(Database.BatchableContext context, List<Opportunity> opps) {
		try {
			Set<Id> opportunitiesToInvoice = new Map<Id, SObject>(opps).keySet();
			OpportunitiesService.newInstance().createInvoices(opportunitiesToInvoice, 0);
		} catch (Exception e) {
			JobError jobError = new JobError();
			jobError.records = opps;
			jobError.message = e.getMessage();
			jobErrors.add(jobError);
		}
	}

	/**
	 * Emails the running user a summary of any chunk failures recorded during execute.
	 * Does nothing when {@code jobErrors} is empty.
	 * @param context Batchable context provided by the platform.
	 */
	public void finish(Database.BatchableContext context) {
		if (jobErrors.isEmpty()) {
			return;
		}
		Map<Id, String> usersEmail = UsersSelector.newInstance().getUsersEmail(new Set<Id>{ UserInfo.getUserId() });
		String emailBody = '';
		for (JobError jobError : jobErrors) {
			List<String> failedOpps = new List<String>();
			for (Opportunity opp : jobError.records) {
				failedOpps.add(opp.Name);
			}
			emailBody += String.format(
				'<p>Error {0} occurred during the processing of Opportunities {1}</p>',
				new List<String>{ jobError.message, String.join(failedOpps, ',') }
			);
		}
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setToAddresses(new String[]{ usersEmail.get(UserInfo.getUserId()) });
		mail.setReplyTo(usersEmail.get(UserInfo.getUserId()));
		mail.setSenderDisplayName(UserInfo.getUserName());
		mail.setSubject('Create Invoice Job Failures');
		mail.setHtmlBody(emailBody);
		Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ mail });
	}

	/**
	 * Captures a batch chunk failure message and the Opportunities that failed.
	 */
	public class JobError {
		/**
		 * Exception or error message for the failed chunk.
		 */
		public String message;
		/**
		 * Opportunities in the chunk that failed processing.
		 */
		public List<Opportunity> records;
	}
}
