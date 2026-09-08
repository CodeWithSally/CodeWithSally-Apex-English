/**
 * Selector for Fulfillment Order queries used by release, dispatch, and complete.
 */
public virtual inherited sharing class FulfillmentOrdersSelector extends fflib_SObjectSelector {
	/**
	* Factory that returns this selector.
	* @return {@link FulfillmentOrdersSelector} instance.
	*/
	public static FulfillmentOrdersSelector newInstance() {
		return new FulfillmentOrdersSelector();
	}

	/**
	* Constructs a user-mode fulfillment order selector.
	*/
	public FulfillmentOrdersSelector() {
		super(false, fflib_SObjectSelector.DataAccess.USER_MODE);
	}

	/**
	* Common fulfillment order fields used by this selector.
	* @return Field list for the query factory.
	*/
	public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField>{
			FulfillmentOrder__c.Id,
			FulfillmentOrder__c.Name,
			FulfillmentOrder__c.Warehouse__c,
			FulfillmentOrder__c.Status__c,
			FulfillmentOrder__c.Priority__c,
			FulfillmentOrder__c.DueDate__c
		};
	}

	/**
	* SObject type this selector queries.
	* @return {@link FulfillmentOrder__c} SObject type.
	*/
	public Schema.SObjectType getSObjectType() {
		return FulfillmentOrder__c.SObjectType;
	}

	/**
	* Orders by Id without lines.
	* @param idSet Order Ids to query. Empty set returns an empty list.
	* @return Matching orders without lines.
	*/
	public virtual List<FulfillmentOrder__c> selectById(Set<Id> idSet) {
		return (List<FulfillmentOrder__c>) selectSObjectsById(idSet);
	}

	/**
	* Orders by Name, for name-based release.
	* @param names Order names such as FO-00001. Empty set returns an empty list.
	* @return Matching orders.
	*/
	public virtual List<FulfillmentOrder__c> selectByName(Set<String> names) {
		if (names == null || names.isEmpty()) {
			return new List<FulfillmentOrder__c>();
		}
		return (List<FulfillmentOrder__c>) Database.query(
			newQueryFactory().setCondition('Name IN :names').toSOQL()
		);
	}

	/**
	* Draft orders at the given warehouses, for the desk snapshot.
	* @param warehouseIds Warehouses to query. Empty set returns an empty list.
	* @return Draft orders at those warehouses.
	*/
	public virtual List<FulfillmentOrder__c> selectDraftByWarehouse(Set<Id> warehouseIds) {
		if (warehouseIds == null || warehouseIds.isEmpty()) {
			return new List<FulfillmentOrder__c>();
		}
		return (List<FulfillmentOrder__c>) Database.query(
			newQueryFactory()
				.setCondition(
					'Warehouse__c IN :warehouseIds AND Status__c = \''
						+ FulfillmentOrders.STATUS_DRAFT + '\''
				)
				.toSOQL()
		);
	}

	/**
	* Orders by Id including lines, used by release and complete-when-lines-done.
	* @param idSet Order Ids to query. Empty set returns an empty list.
	* @return Matching orders with nested FulfillmentLines__r.
	*/
	public virtual List<FulfillmentOrder__c> selectByIdWithLines(Set<Id> idSet) {
		if (idSet == null || idSet.isEmpty()) {
			return new List<FulfillmentOrder__c>();
		}
		fflib_QueryFactory ordersQuery = newQueryFactory();
		FulfillmentLinesSelector.newInstance().addQueryFactorySubselect(ordersQuery);
		return (List<FulfillmentOrder__c>) Database.query(
			ordersQuery.setCondition('Id IN :idSet').toSOQL()
		);
	}

	/**
	* Released or In Progress orders at a warehouse, with lines, for dispatch parent updates.
	* @param warehouseId Warehouse to query. Null returns an empty list.
	* @return Matching orders with nested lines.
	*/
	public virtual List<FulfillmentOrder__c> selectOpenByWarehouseWithLines(Id warehouseId) {
		if (warehouseId == null) {
			return new List<FulfillmentOrder__c>();
		}
		fflib_QueryFactory ordersQuery = newQueryFactory();
		FulfillmentLinesSelector.newInstance().addQueryFactorySubselect(ordersQuery);
		return (List<FulfillmentOrder__c>) Database.query(
			ordersQuery.setCondition(
				'Warehouse__c = :warehouseId AND Status__c IN (\''
					+ FulfillmentOrders.STATUS_RELEASED + '\', \''
					+ FulfillmentOrders.STATUS_IN_PROGRESS + '\')'
			).toSOQL()
		);
	}
}
