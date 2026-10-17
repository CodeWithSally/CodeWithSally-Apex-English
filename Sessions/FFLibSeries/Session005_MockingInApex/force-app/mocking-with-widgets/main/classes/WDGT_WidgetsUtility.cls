/**
 * Widgets helper logic called by {@link WDGT_WidgetsService}. Session 005 mocking example.
 */
public virtual inherited sharing class WDGT_WidgetsUtility {
	/**
	* Default composition.
	* @return {@link WDGT_WidgetsUtility} instance.
	*/
	public static WDGT_WidgetsUtility newInstance() {
		return new WDGT_WidgetsUtility();
	}

	/**
	* Creates a utility. Add collaborator parameters here so tests can inject mocks.
	*/
	public WDGT_WidgetsUtility() {
	}

	/**
	* New random GUID from the platform's cryptographically strong generator.
	* @return Version 4 GUID as 32 lowercase hex characters, no hyphens, e.g. {@code 3f2504e04f8941d39a0c0305e82c3301}.
	*/
	public virtual String generateGuid() {
		return UUID.randomUUID().toString().remove('-');
	}

	/**
	* Client-agnostic exception thrown by widgets utility methods.
	*/
	public class WidgetsUtilityException extends Exception {
	}
}
