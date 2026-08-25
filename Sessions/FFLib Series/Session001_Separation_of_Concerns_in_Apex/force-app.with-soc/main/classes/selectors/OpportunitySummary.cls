/**
 * Read-only DTO wrapping Opportunity fields and related Account summary values for UI or API views.
 */
public class OpportunitySummary {
	private Opportunity opportunity;

	/**
	 * Creates a DTO from a queried Opportunity that includes related Account fields.
	 * @param opportunity Opportunity with Account.Name, Account.AccountNumber, and Account.Owner.Name populated as needed.
	 */
	public OpportunitySummary(Opportunity opportunity) {
		this.opportunity = opportunity;
	}

	/**
	 * Opportunity Id.
	 */
	public Id Id { get { return this.opportunity.Id; } }

	/**
	 * Opportunity Amount.
	 */
	public Decimal Amount { get { return this.opportunity.Amount; } }

	/**
	 * Opportunity StageName.
	 */
	public String Stage { get { return this.opportunity.StageName; } }

	/**
	 * Related Account Name.
	 */
	public String AccountName { get { return this.opportunity.Account.Name; } }

	/**
	 * Related Account Number.
	 */
	public String AccountNumber { get { return this.opportunity.Account.AccountNumber; } }

	/**
	 * Related Account owner Name.
	 */
	public String AccountOwner { get { return this.opportunity.Account.Owner.Name; } }
}
