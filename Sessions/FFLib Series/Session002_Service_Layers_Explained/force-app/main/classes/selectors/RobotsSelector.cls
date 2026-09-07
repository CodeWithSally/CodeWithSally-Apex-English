/**
 * Selector for Robot queries used by dispatch, fulfillment, and maintenance.
 */
public virtual inherited sharing class RobotsSelector extends fflib_SObjectSelector {
	@TestVisible
	private static RobotsSelector mock;

	/**
	 * Factory that returns this selector, or {@link #mock} when tests have set one.
	 * @return {@link RobotsSelector} instance.
	 */
	public static RobotsSelector newInstance() {
		return mock != null ? mock : new RobotsSelector();
	}

	/**
	 * Constructs a user-mode robot selector.
	 */
	public RobotsSelector() {
		super(false, fflib_SObjectSelector.DataAccess.USER_MODE);
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
}
