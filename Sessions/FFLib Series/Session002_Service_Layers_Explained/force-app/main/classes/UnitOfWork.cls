/**
 * Thin Unit of Work factory for the warehouse operations sample.
 * One app-level type list so services can share a Unit of Work in a single commit
 * (for example completing lines and scheduling maintenance together).
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
