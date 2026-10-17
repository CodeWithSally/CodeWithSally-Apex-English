/**
 * Thin Unit of Work factory for the Widgets example. No Application class.
 *
 * Service methods call {@link #newInstance} so each persist operation gets a fresh
 * Unit of Work. The type list is the Widgets registry of SObject types.
 *
 * Tests set {@link #mock} to substitute the instance that {@link #newInstance} returns.
 */
public inherited sharing class WDGT_UnitOfWork {
	@TestVisible
	private static fflib_SObjectUnitOfWork mock;

	/**
	* Returns a Unit of Work registered for the Widgets types, or {@link #mock} when tests have set one.
	* DML runs in user mode.
	* @return Unit of Work instance.
	*/
	public static fflib_SObjectUnitOfWork newInstance() {
		if (mock != null) {
			return mock;
		}
		return new fflib_SObjectUnitOfWork(
			new List<SObjectType>{
				WDGT_Widget__c.SObjectType
			},
			new fflib_SObjectUnitOfWork.UserModeDML()
		);
	}
}
