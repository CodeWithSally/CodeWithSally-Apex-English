/**
 * Batch and schedulable job that invoices Opportunities marked Ready.
 * Delegates invoice creation to {@link OpportunityCreateInvoiceController}.
 * Accumulates per-record failures for output in {@link #finish}.
 */
public inherited sharing class CreateInvoicesJob
	implements System.Schedulable, Database.Batchable<SObject>, Database.Stateful {

	private List<Exception> exceptions = new List<Exception>();

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
	 * @return QueryLocator for Opportunities ready to invoice.
	 */
	public Database.QueryLocator start(Database.BatchableContext context) {
		return Database.getQueryLocator([
			SELECT Id
			FROM Opportunity
			WHERE InvoicedStatus__c = 'Ready'
		]);
	}

	/**
	 * Creates invoices for the current chunk of Opportunities with zero discount.
	 * @param context Batchable context provided by the platform.
	 * @param opps Opportunity chunk to invoice.
	 */
	public void execute(Database.BatchableContext context, List<Opportunity> opps) {
		for (Opportunity opp : opps) {
			try {
				OpportunityCreateInvoiceController.createInvoice(opp.Id, 0);
			} catch (Exception e) {
				exceptions.add(e);
			}
		}
	}

	/**
	 * Batch finish hook.
	 * @param context Batchable context provided by the platform.
	 */
	public void finish(Database.BatchableContext context) {
		// Output accumulated exceptions to a custom object for ops review
	}
}
