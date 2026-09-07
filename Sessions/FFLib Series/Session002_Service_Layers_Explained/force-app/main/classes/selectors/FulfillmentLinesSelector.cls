/**
 * Selector for Fulfillment Line queries used by the desk, dispatch, and complete.
 */
public virtual inherited sharing class FulfillmentLinesSelector extends fflib_SObjectSelector {
	@TestVisible
	private static FulfillmentLinesSelector mock;

	/**
	 * Factory that returns this selector, or {@link #mock} when tests have set one.
	 * @return {@link FulfillmentLinesSelector} instance.
	 */
	public static FulfillmentLinesSelector newInstance() {
		return mock != null ? mock : new FulfillmentLinesSelector();
	}

	/**
	 * Constructs a user-mode fulfillment line selector.
	 */
	public FulfillmentLinesSelector() {
		super(false, fflib_SObjectSelector.DataAccess.USER_MODE);
	}

	/**
	 * Common fulfillment line fields used by this selector.
	 * @return Field list for the query factory.
	 */
	public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField>{
			FulfillmentLine__c.Id,
			FulfillmentLine__c.Name,
			FulfillmentLine__c.FulfillmentOrder__c,
			FulfillmentLine__c.Status__c,
			FulfillmentLine__c.ProductSku__c,
			FulfillmentLine__c.Quantity__c,
			FulfillmentLine__c.WeightKg__c,
			FulfillmentLine__c.AssignedRobot__c
		};
	}

	/**
	 * SObject type this selector queries.
	 * @return {@link FulfillmentLine__c} SObject type.
	 */
	public Schema.SObjectType getSObjectType() {
		return FulfillmentLine__c.SObjectType;
	}

	/**
	 * Dispatch matches in this order: High before Normal, then line Name.
	 * @return Default ORDER BY for this selector's query factory.
	 */
	public override String getOrderBy() {
		return 'FulfillmentOrder__r.Priority__c, Name';
	}

	/**
	 * Lines by Id.
	 * @param idSet Line Ids to query. Empty set returns an empty list.
	 * @return Matching lines.
	 */
	public virtual List<FulfillmentLine__c> selectById(Set<Id> idSet) {
		return (List<FulfillmentLine__c>) selectSObjectsById(idSet);
	}

	/**
	 * Pending unassigned line counts on Draft, Released, or In Progress orders, for the desk snapshot.
	 * @param warehouseIds Warehouses to query. Empty set returns an empty map.
	 * @return Pending unassigned line count keyed by Warehouse Id.
	 */
	public virtual Map<Id, Integer> countDeskPendingUnassignedByWarehouse(Set<Id> warehouseIds) {
		if (warehouseIds == null || warehouseIds.isEmpty()) {
			return new Map<Id, Integer>();
		}
		Map<Id, Integer> counts = new Map<Id, Integer>();
		for (AggregateResult row : [
			SELECT FulfillmentOrder__r.Warehouse__c warehouseId, COUNT(Id) lineCount
			FROM FulfillmentLine__c
			WHERE Status__c = :FulfillmentLines.STATUS_PENDING
				AND AssignedRobot__c = null
				AND FulfillmentOrder__r.Warehouse__c IN :warehouseIds
				AND FulfillmentOrder__r.Status__c IN (
					:FulfillmentOrders.STATUS_DRAFT,
					:FulfillmentOrders.STATUS_RELEASED,
					:FulfillmentOrders.STATUS_IN_PROGRESS
				)
			WITH USER_MODE
			GROUP BY FulfillmentOrder__r.Warehouse__c
		]) {
			counts.put((Id) row.get('warehouseId'), (Integer) row.get('lineCount'));
		}
		return counts;
	}

	/**
	 * Pending unassigned lines at the given warehouses, for dispatch.
	 * @param warehouseIds Warehouses to query. Empty set returns an empty list.
	 * @return Pending lines whose parent order is Released or In Progress, with FulfillmentOrder__r fields.
	 */
	public virtual List<FulfillmentLine__c> selectPendingUnassignedByWarehouseWithOrder(Set<Id> warehouseIds) {
		if (warehouseIds == null || warehouseIds.isEmpty()) {
			return new List<FulfillmentLine__c>();
		}
		fflib_QueryFactory query = newQueryFactory();
		FulfillmentOrdersSelector.newInstance().configureQueryFactoryFields(query, 'FulfillmentOrder__r');
		return (List<FulfillmentLine__c>) Database.query(
			query.setCondition(
				'Status__c = \'' + FulfillmentLines.STATUS_PENDING + '\''
					+ ' AND AssignedRobot__c = null'
					+ ' AND FulfillmentOrder__r.Warehouse__c IN :warehouseIds'
					+ ' AND FulfillmentOrder__r.Status__c IN (\''
					+ FulfillmentOrders.STATUS_RELEASED + '\', \''
					+ FulfillmentOrders.STATUS_IN_PROGRESS + '\')'
			).toSOQL()
		);
	}

	/**
	 * Assigned lines on the given orders, for complete-from-order.
	 * @param orderIds Parent order Ids. Empty set returns an empty list.
	 * @return Assigned lines on those orders.
	 */
	public virtual List<FulfillmentLine__c> selectAssignedByOrderId(Set<Id> orderIds) {
		if (orderIds == null || orderIds.isEmpty()) {
			return new List<FulfillmentLine__c>();
		}
		return (List<FulfillmentLine__c>) Database.query(
			newQueryFactory()
				.setCondition(
					'FulfillmentOrder__c IN :orderIds AND Status__c = \''
						+ FulfillmentLines.STATUS_ASSIGNED + '\''
				)
				.toSOQL()
		);
	}
}
