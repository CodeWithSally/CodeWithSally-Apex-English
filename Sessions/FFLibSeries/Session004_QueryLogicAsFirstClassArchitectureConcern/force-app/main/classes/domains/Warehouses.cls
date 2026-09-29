/**
 * Domain for Warehouse records. A closed warehouse cannot accept new work.
 */
public virtual inherited sharing class Warehouses extends fflib_SObjects {
	/** Warehouse is open and can accept pick work. */
	public static final String STATUS_ACTIVE = 'Active';
	/** Warehouse is closed and cannot accept pick work. */
	public static final String STATUS_CLOSED = 'Closed';

	@TestVisible
	private static Warehouses mock;

	/**
	* Factory that wraps the given Warehouse records, or {@link #mock} when tests have set one.
	* @param recordList Warehouses to manage. Null is treated as an empty list.
	* @return {@link Warehouses} instance.
	*/
	public static Warehouses newInstance(List<Warehouse__c> recordList) {
		return mock != null ? mock : new Warehouses(recordList);
	}

	/**
	* Creates a domain wrapping the given Warehouse records.
	* @param sObjectList Warehouses to manage. Null is treated as an empty list.
	*/
	public Warehouses(List<Warehouse__c> sObjectList) {
		super(sObjectList == null ? new List<Warehouse__c>() : sObjectList);
	}

	/**
	* Whether every given warehouse can accept new pick work.
	* @param warehouseIds Warehouse Ids to check. Null or empty returns false.
	* @return True when every given warehouse is in this domain and Active.
	*/
	public virtual Boolean canAcceptWork(Set<Id> warehouseIds) {
		if (warehouseIds == null || warehouseIds.isEmpty()) {
			return false;
		}
		Map<Id, Warehouse__c> byId = new Map<Id, Warehouse__c>((List<Warehouse__c>) getRecords());
		for (Id warehouseId : warehouseIds) {
			Warehouse__c warehouse = byId.get(warehouseId);
			if (warehouse == null || warehouse.Status__c != STATUS_ACTIVE) {
				return false;
			}
		}
		return true;
	}

	/**
	* Throws when any given warehouse cannot accept work.
	* @param warehouseIds Warehouse Ids that must be Active. Null or empty performs no check.
	*/
	public virtual void assertCanAcceptWork(Set<Id> warehouseIds) {
		if (warehouseIds == null || warehouseIds.isEmpty()) {
			return;
		}
		Map<Id, Warehouse__c> byId = new Map<Id, Warehouse__c>((List<Warehouse__c>) getRecords());
		for (Id warehouseId : warehouseIds) {
			Warehouse__c warehouse = byId.get(warehouseId);
			if (warehouse == null || warehouse.Status__c != STATUS_ACTIVE) {
				String name = warehouse != null ? warehouse.Name : String.valueOf(warehouseId);
				throw new WarehousesException(
					'Warehouse ' + name + ' is not active and cannot accept work.'
				);
			}
		}
	}

	/**
	* Thrown when a warehouse cannot accept work.
	*/
	public class WarehousesException extends Exception {
	}
}
