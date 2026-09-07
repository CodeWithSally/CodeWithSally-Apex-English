/**
 * Selector for Warehouse queries used by release and dispatch.
 */
public virtual inherited sharing class WarehousesSelector extends fflib_SObjectSelector {
	@TestVisible
	private static WarehousesSelector mock;

	/**
	 * Factory that returns this selector, or {@link #mock} when tests have set one.
	 * @return {@link WarehousesSelector} instance.
	 */
	public static WarehousesSelector newInstance() {
		return mock != null ? mock : new WarehousesSelector();
	}

	/**
	 * Constructs a user-mode warehouse selector.
	 */
	public WarehousesSelector() {
		super(false, fflib_SObjectSelector.DataAccess.USER_MODE);
	}

	/**
	 * Common warehouse fields used by this selector.
	 * @return Field list for the query factory.
	 */
	public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField>{
			Warehouse__c.Id,
			Warehouse__c.Name,
			Warehouse__c.Status__c,
			Warehouse__c.Location__c
		};
	}

	/**
	 * SObject type this selector queries.
	 * @return {@link Warehouse__c} SObject type.
	 */
	public Schema.SObjectType getSObjectType() {
		return Warehouse__c.SObjectType;
	}

	/**
	 * Warehouses by Id.
	 * @param idSet Warehouse Ids to query. Empty set returns an empty list.
	 * @return Matching warehouses.
	 */
	public virtual List<Warehouse__c> selectById(Set<Id> idSet) {
		if (idSet == null || idSet.isEmpty()) {
			return new List<Warehouse__c>();
		}
		return (List<Warehouse__c>) selectSObjectsById(idSet);
	}

	/**
	 * Warehouses by Name, for desk lookup and name-based dispatch.
	 * @param names Warehouse names. Empty set returns an empty map.
	 * @return Matching warehouses keyed by Name.
	 */
	public virtual Map<String, Warehouse__c> selectByName(Set<String> names) {
		Map<String, Warehouse__c> warehouseByName = new Map<String, Warehouse__c>();
		if (names == null || names.isEmpty()) {
			return warehouseByName;
		}
		for (Warehouse__c warehouse : (List<Warehouse__c>) Database.query(
			newQueryFactory().setCondition('Name IN :names').toSOQL()
		)) {
			warehouseByName.put(warehouse.Name, warehouse);
		}
		return warehouseByName;
	}

	/**
	 * Active warehouses, for batch dispatch.
	 * @return Active warehouses.
	 */
	public virtual List<Warehouse__c> selectActive() {
		return (List<Warehouse__c>) Database.query(
			newQueryFactory().setCondition('Status__c = \'' + Warehouses.STATUS_ACTIVE + '\'').toSOQL()
		);
	}

	/**
	 * QueryLocator of active warehouses for Batch Apex.
	 * @return QueryLocator of active warehouses.
	 */
	public virtual Database.QueryLocator selectActiveAsQueryLocator() {
		return Database.getQueryLocator(
			newQueryFactory().setCondition('Status__c = \'' + Warehouses.STATUS_ACTIVE + '\'').toSOQL()
		);
	}
}
