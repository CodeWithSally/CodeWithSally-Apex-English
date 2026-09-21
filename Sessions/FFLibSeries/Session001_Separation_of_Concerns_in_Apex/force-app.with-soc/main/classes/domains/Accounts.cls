/**
 * Domain logic for Account records, including opportunity activity description updates.
 */
public virtual inherited sharing class Accounts {
	@TestVisible
	private static Accounts mock;

	/**
	 * Factory that wraps the given Account records, or {@link #mock} when tests have set one.
	 * @param recordList Accounts to manage. Null is treated as an empty list.
	 * @return {@link Accounts} instance.
	 */
	public static Accounts newInstance(List<Account> recordList) {
		return mock != null ? mock : new Accounts(recordList);
	}

	/**
	 * Prefix written to Account.Description when opportunity activity is recorded.
	 */
	public static final String OPPORTUNITY_RAISED_DESCRIPTION = 'Last Opportunity Raised';

	private List<Account> records;

	/**
	 * Creates a domain wrapping the given Account records.
	 * @param sObjectList Accounts to manage. Null is treated as an empty list.
	 */
	public Accounts(List<Account> sObjectList) {
		this.records = sObjectList == null ? new List<Account>() : sObjectList;
	}

	/**
	 * Returns the Account records held by this domain.
	 * @return The in-memory Account list; never null.
	 */
	public List<Account> getRecords() {
		return records;
	}

	/**
	 * Returns the Account records held by this domain.
	 * @return The in-memory Account list; never null. Same as {@link #getRecords()}.
	 */
	public List<Account> getAccounts() {
		return records;
	}

	/**
	 * Sets Description on every Account in the domain.
	 * @param description Value to assign to Account.Description.
	 */
	public void setDescription(String description) {
		for (Account account : records) {
			account.Description = description;
		}
	}

	/**
	 * Updates Description to record that an opportunity was raised today.
	 * Uses {@link #OPPORTUNITY_RAISED_DESCRIPTION} plus {@code System.today()}.
	 */
	public void updateOpportunityActivity() {
		setDescription(OPPORTUNITY_RAISED_DESCRIPTION + ' ' + System.today());
	}
}
