/**
 * Visualforce controller for the Apply Discounts list-view button.
 * Delegates discounting to {@link OpportunitiesService}.
 */
public inherited sharing class OpportunityApplyDiscountsController {
	/**
	 * Discount percent entered on the list page (for example 10 for 10%).
	 */
	public Decimal DiscountPercentage { get; set; }

	private ApexPages.StandardSetController standardSetController;

	/**
	 * Creates a controller for a list StandardSetController (bulk apply).
	 * @param controller StandardSetController with selected Opportunities. Cannot be null.
	 */
	public OpportunityApplyDiscountsController(ApexPages.StandardSetController controller) {
		standardSetController = controller;
	}

	/**
	 * Applies {@link #DiscountPercentage} to all selected Opportunities on the list view.
	 * @return Null so the list page remains; adds an info message on success.
	 */
	public PageReference applyDiscounts() {
		try {
			Set<Id> selectedOpportunityIds =
				new Map<Id, SObject>(standardSetController.getSelected()).keySet();
			OpportunitiesService.newInstance()
				.applyDiscounts(selectedOpportunityIds, DiscountPercentage);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Opportunities updated.'));
		} catch (Exception e) {
			ApexPages.addMessages(e);
		}
		return null;
	}
}
