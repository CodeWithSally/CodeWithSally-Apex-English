/**
 * Visualforce controller for the Create Invoices list-view button.
 * Reuses {@link OpportunityCreateInvoiceController#createInvoice} per selected record.
 */
public inherited sharing class OpportunityCreateInvoicesController {
	/**
	 * Optional discount percent applied before invoice creation (for example 10 for 10%).
	 */
	public Decimal DiscountPercentage { get; set; }

	private ApexPages.StandardSetController standardSetController;

	/**
	 * Creates a controller for a list StandardSetController (bulk create).
	 * @param controller StandardSetController with selected Opportunities. Cannot be null.
	 */
	public OpportunityCreateInvoicesController(ApexPages.StandardSetController controller) {
		standardSetController = controller;
	}

	/**
	 * Creates invoices for all selected Opportunities on the list view.
	 * @return Null so the list page remains; adds an info message on success.
	 */
	public PageReference createInvoices() {
		Set<Id> selectedOpportunityIds =
			new Map<Id, SObject>(standardSetController.getSelected()).keySet();
		for (Id opportunityId : selectedOpportunityIds) {
			OpportunityCreateInvoiceController.createInvoice(opportunityId, DiscountPercentage);
		}
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Invoices created.'));
		return null;
	}
}
