/**
 * Selector for User email addresses used by job notification flows.
 */
public virtual inherited sharing class UsersSelector {
	@TestVisible
	private static UsersSelector mock;

	/**
	 * Factory that returns this selector, or {@link #mock} when tests have set one.
	 * @return {@link UsersSelector} instance.
	 */
	public static UsersSelector newInstance() {
		return mock != null ? mock : new UsersSelector();
	}

	/**
	 * Maps User Ids to their Email addresses.
	 * @param userIds User Ids to query. Empty set returns an empty map.
	 * @return Map of User Id to Email; users without a matching row are omitted.
	 */
	public Map<Id, String> getUsersEmail(Set<Id> userIds) {
		Map<Id, String> emailsById = new Map<Id, String>();
		for (User u : [
			SELECT Id, Email
			FROM User
			WHERE Id IN :userIds
		]) {
			emailsById.put(u.Id, u.Email);
		}
		return emailsById;
	}
}
