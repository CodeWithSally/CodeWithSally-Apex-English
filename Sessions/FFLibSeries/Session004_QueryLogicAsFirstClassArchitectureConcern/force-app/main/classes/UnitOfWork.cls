/**
 * Thin Unit of Work factory for the warehouse operations sample. No Application class.
 *
 * Service methods call {@link #newInstance} so each persist operation gets a fresh
 * Unit of Work. The type list is the app-level registry of SObject types.
 *
 * Tests set {@link #mock} to substitute the instance that {@link #newInstance} returns.
 */
public inherited sharing class UnitOfWork {
	@TestVisible
	private static fflib_SObjectUnitOfWork mock;

	/**
	* Returns a Unit of Work registered for this app's types, or {@link #mock} when tests have set one.
	* DML runs in user mode.
	* @return Unit of Work instance.
	*/
	public static fflib_SObjectUnitOfWork newInstance() {
		if (mock != null) {
			return mock;
		}
		return new fflib_SObjectUnitOfWork(
			new List<SObjectType>{
				Warehouse__c.SObjectType,
				RobotModel__c.SObjectType,
				Robot__c.SObjectType,
				FulfillmentOrder__c.SObjectType,
				FulfillmentLine__c.SObjectType,
				MaintenanceJob__c.SObjectType
			},
			new fflib_SObjectUnitOfWork.UserModeDML()
		);
	}
}
