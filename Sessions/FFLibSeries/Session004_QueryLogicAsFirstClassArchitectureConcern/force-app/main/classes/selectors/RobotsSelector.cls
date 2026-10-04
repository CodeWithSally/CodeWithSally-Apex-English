/**
 * Selector for Robot queries used by dispatch, fulfillment, and maintenance.
 */
public virtual inherited sharing class RobotsSelector extends fflib_SObjectSelector {
	/**
	* Factory that returns this selector.
	* @return {@link RobotsSelector} instance.
	*/
	public static RobotsSelector newInstance() {
		return new RobotsSelector();
	}

	/**
	* Constructs a user-mode robot selector.
	*/
	public RobotsSelector() {
		super(false, fflib_SObjectSelector.DataAccess.USER_MODE);
	}

	/**
	* Constructs a robot selector with the given data access. Elevation is named by the caller, never ambient.
	* @param access Data access for every query this instance runs. Cannot be null.
	*/
	public RobotsSelector(fflib_SObjectSelector.DataAccess access) {
		super(false, access);
	}

	/**
	* Common robot fields used by this selector.
	* @return Field list for the query factory.
	*/
	public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField>{
			Robot__c.Id,
			Robot__c.Name,
			Robot__c.Warehouse__c,
			Robot__c.Model__c,
			Robot__c.Status__c,
			Robot__c.Health__c,
			Robot__c.WearPercent__c,
			Robot__c.HoursSinceService__c,
			Robot__c.BatteryLevel__c
		};
	}

	/**
	* SObject type this selector queries.
	* @return {@link Robot__c} SObject type.
	*/
	public Schema.SObjectType getSObjectType() {
		return Robot__c.SObjectType;
	}

	/**
	* Robots by Id without model fields.
	* @param idSet Robot Ids to query. Empty set returns an empty list.
	* @return Matching robots without model fields.
	*/
	public virtual List<Robot__c> selectById(Set<Id> idSet) {
		return (List<Robot__c>) selectSObjectsById(idSet);
	}

	/**
	* Robots by Id without model fields, with the data access named for this query only.
	* Overrides this instance's data access for this query; the instance is unchanged.
	* @param idSet Robot Ids to query. Cannot be null; an empty set returns an empty list.
	* @param access Data access for this query only. Anything but SYSTEM_MODE runs in user mode.
	* @return Matching robots without model fields.
	*/
	public virtual List<Robot__c> selectById(Set<Id> idSet, fflib_SObjectSelector.DataAccess access) {
		return (List<Robot__c>) Database.query(
			newQueryFactory(access).setCondition(Robot__c.Id + ' IN :idSet').toSOQL()
		);
	}

	/**
	* Robots by Id with the common fields plus fields the caller adds. The common fields are always included.
	* @param idSet Robot Ids to query. Cannot be null; an empty set returns an empty list.
	* @param additionalFields Robot fields to add. Null or empty adds none.
	* @return Matching robots with the common and additional fields.
	*/
	public virtual List<Robot__c> selectById(Set<Id> idSet, Set<Schema.SObjectField> additionalFields) {
		fflib_QueryFactory query = newQueryFactory();
		if (additionalFields != null) {
			query.selectFields(additionalFields);
		}
		return (List<Robot__c>) Database.query(query.setCondition(Robot__c.Id + ' IN :idSet').toSOQL());
	}

	/**
	* Robots by Id with their owner, for telling whoever looks after each robot.
	* @param idSet Robot Ids to query. Cannot be null; an empty set returns an empty list.
	* @return Matching robots with OwnerId.
	*/
	public virtual List<Robot__c> selectByIdWithOwner(Set<Id> idSet) {
		return (List<Robot__c>) Database.query(
			newQueryFactory().selectField(Robot__c.OwnerId).setCondition(Robot__c.Id + ' IN :idSet').toSOQL()
		);
	}

	/**
	* Robots by Id including model interval and load used by wear and dispatch.
	* @param idSet Robot Ids to query. Empty set returns an empty list.
	* @return Matching robots with Model__r fields.
	*/
	public virtual List<Robot__c> selectByIdWithModel(Set<Id> idSet) {
		if (idSet == null || idSet.isEmpty()) {
			return new List<Robot__c>();
		}
		fflib_QueryFactory query = newQueryFactory();
		RobotModelsSelector.newInstance().configureQueryFactoryFields(query, 'Model__r');
		return (List<Robot__c>) Database.query(query.setCondition('Id IN :idSet').toSOQL());
	}

	/**
	* Robots that can accept work at the given warehouses, for the desk snapshot.
	* Uses the same Idle / not Critical / wear / battery rules as {@link Robots#canAcceptWork}.
	* @param warehouseIds Warehouses to query. Empty set returns an empty map.
	* @return Available robot count keyed by Warehouse Id.
	*/
	public virtual Map<Id, Integer> countAvailableByWarehouse(Set<Id> warehouseIds) {
		if (warehouseIds == null || warehouseIds.isEmpty()) {
			return new Map<Id, Integer>();
		}
		Map<Id, Integer> counts = new Map<Id, Integer>();
		for (AggregateResult row : [
			SELECT Warehouse__c warehouseId, COUNT(Id) robotCount
			FROM Robot__c
			WHERE Warehouse__c IN :warehouseIds
				AND Status__c = :Robots.STATUS_IDLE
				AND (Health__c = null OR Health__c != :Robots.HEALTH_CRITICAL)
				AND (WearPercent__c = null OR WearPercent__c < :Robots.WEAR_CANNOT_WORK)
				AND BatteryLevel__c > :Robots.MIN_BATTERY_TO_WORK
			WITH USER_MODE
			GROUP BY Warehouse__c
		]) {
			counts.put((Id) row.get('warehouseId'), (Integer) row.get('robotCount'));
		}
		return counts;
	}

	/**
	* Idle robots in the given warehouses, with model fields, for dispatch to filter with domain rules.
	* @param warehouseIds Warehouses to query. Empty set returns an empty list.
	* @return Idle robots at those warehouses.
	*/
	public virtual List<Robot__c> selectIdleByWarehouseWithModel(Set<Id> warehouseIds) {
		if (warehouseIds == null || warehouseIds.isEmpty()) {
			return new List<Robot__c>();
		}
		fflib_QueryFactory query = newQueryFactory();
		RobotModelsSelector.newInstance().configureQueryFactoryFields(query, 'Model__r');
		return (List<Robot__c>) Database.query(
			query.setCondition('Warehouse__c IN :warehouseIds AND Status__c = \'' + Robots.STATUS_IDLE + '\'').toSOQL()
		);
	}

	/**
	* Robots at the given warehouses that are not already in service, with model fields, for due-for-service checks.
	* @param warehouseIds Warehouses to query. Empty set returns an empty list.
	* @return Robots at those warehouses excluding InService.
	*/
	public virtual List<Robot__c> selectNotInServiceByWarehouseWithModel(Set<Id> warehouseIds) {
		if (warehouseIds == null || warehouseIds.isEmpty()) {
			return new List<Robot__c>();
		}
		fflib_QueryFactory query = newQueryFactory();
		RobotModelsSelector.newInstance().configureQueryFactoryFields(query, 'Model__r');
		return (List<Robot__c>) Database.query(
			query.setCondition(
				'Warehouse__c IN :warehouseIds AND Status__c != \'' + Robots.STATUS_IN_SERVICE + '\''
			).toSOQL()
		);
	}

	/**
	* PaginationCursor of robots at the given warehouses, for paging the desk's robot list.
	* @param warehouseIds Warehouses to query. Cannot be null; an empty set gives a cursor with no records.
	* @return PaginationCursor over the matching robots.
	*/
	public virtual Database.PaginationCursor selectByWarehouseAsPaginationCursor(Set<Id> warehouseIds) {
		return Database.getPaginationCursor(
			newQueryFactory().setCondition(Robot__c.Warehouse__c + ' IN :warehouseIds').toSOQL()
		);
	}

	/**
	* Query factory with this selector's fields and order, in the data access named for one query.
	* Elevation is named, never ambient, so anything but SYSTEM_MODE runs in user mode.
	* @param access Data access for this query only.
	* @return Query factory whose SOQL ends WITH USER_MODE or WITH SYSTEM_MODE.
	*/
	private fflib_QueryFactory newQueryFactory(fflib_SObjectSelector.DataAccess access) {
		// setEnforceFLS is fflib's legacy name; with USER_MODE or SYSTEM_MODE it emits native WITH USER_MODE / WITH SYSTEM_MODE
		return newQueryFactory().setEnforceFLS(
			access == fflib_SObjectSelector.DataAccess.SYSTEM_MODE
				? fflib_QueryFactory.FLSEnforcement.SYSTEM_MODE
				: fflib_QueryFactory.FLSEnforcement.USER_MODE
		);
	}
}
