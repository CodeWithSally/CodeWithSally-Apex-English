/**
 * Warehouse desk: snapshot pending work, idle robots, and draft orders.
 * Spans Warehouse, Fulfillment Line, Fulfillment Order, and Robot.
 */
public virtual inherited sharing class WarehouseService {
	private final WarehousesSelector warehouseSelector;
	private final FulfillmentLinesSelector lineSelector;
	private final RobotsSelector robotSelector;
	private final FulfillmentOrdersSelector orderSelector;

	/**
	* Default composition: live selectors.
	* @return {@link WarehouseService} instance.
	*/
	public static WarehouseService newInstance() {
		return new WarehouseService(
			WarehousesSelector.newInstance(),
			FulfillmentLinesSelector.newInstance(),
			RobotsSelector.newInstance(),
			FulfillmentOrdersSelector.newInstance()
		);
	}

	/**
	* Creates a service with the given selectors.
	* @param warehouseSelector Warehouse selector. Cannot be null.
	* @param lineSelector Line selector. Cannot be null.
	* @param robotSelector Robot selector. Cannot be null.
	* @param orderSelector Order selector. Cannot be null.
	*/
	@SuppressWarnings('PMD.ExcessiveParameterList') // dependency injection: collaborators passed in so tests can stub them
	public WarehouseService(
		WarehousesSelector warehouseSelector,
		FulfillmentLinesSelector lineSelector,
		RobotsSelector robotSelector,
		FulfillmentOrdersSelector orderSelector
	) {
		this.warehouseSelector = warehouseSelector;
		this.lineSelector = lineSelector;
		this.robotSelector = robotSelector;
		this.orderSelector = orderSelector;
	}

	/**
	* Desk snapshot: pending line counts, available robots, and draft order names.
	* @param warehouseNames Warehouse names such as North Hub. One summary per name, in order.
	* @return One summary per requested warehouse.
	*/
	public virtual List<Summary> summaries(List<String> warehouseNames) {
		if (warehouseNames == null || warehouseNames.isEmpty()) {
			return new List<Summary>();
		}
		Map<String, Warehouse__c> warehouseByName = warehouseSelector.selectByName(new Set<String>(warehouseNames));
		Set<Id> warehouseIds = new Map<Id, Warehouse__c>(warehouseByName.values()).keySet();
		Map<Id, Integer> pendingByWarehouse = lineSelector.countDeskPendingUnassignedByWarehouse(warehouseIds);
		Map<Id, Integer> availableByWarehouse = robotSelector.countAvailableByWarehouse(warehouseIds);
		Map<Id, String> draftNamesByWarehouse = new Map<Id, String>();
		for (FulfillmentOrder__c order : orderSelector.selectDraftByWarehouse(warehouseIds)) {
			String names = draftNamesByWarehouse.get(order.Warehouse__c);
			draftNamesByWarehouse.put(
				order.Warehouse__c,
				names == null ? order.Name : names + ', ' + order.Name
			);
		}

		List<Summary> summaries = new List<Summary>();
		for (String warehouseName : warehouseNames) {
			Warehouse__c warehouse = warehouseByName.get(warehouseName);
			if (warehouse == null) {
				throw new WarehouseServiceException('No warehouse named ' + warehouseName + '.');
			}
			summaries.add(
				new Summary(
					warehouse,
					pendingByWarehouse.get(warehouse.Id),
					availableByWarehouse.get(warehouse.Id),
					draftNamesByWarehouse.get(warehouse.Id)
				)
			);
		}
		return summaries;
	}

	/**
	* Desk snapshot for one warehouse.
	*/
	public class Summary {
		public Id warehouseId;
		public String warehouseName;
		public Integer pendingUnassignedLines;
		public Integer idleAvailableRobots;
		public Integer robotShortfall;
		public String draftOrderNames;

		/**
		* Builds a desk snapshot from a warehouse and its pending and idle counts.
		* @param warehouse Warehouse the snapshot describes. Cannot be null.
		* @param pending Pending unassigned line count. Null is treated as 0.
		* @param available Idle available robot count. Null is treated as 0.
		* @param draftNames Comma-separated draft order names. Null is treated as blank.
		*/
		@SuppressWarnings('PMD.ExcessiveParameterList') // data only: this class holds snapshot fields; constructor sets them in one place
		public Summary(
			Warehouse__c warehouse,
			Integer pending,
			Integer available,
			String draftNames
		) {
			this.warehouseId = warehouse.Id;
			this.warehouseName = warehouse.Name;
			this.pendingUnassignedLines = pending == null ? 0 : pending;
			this.idleAvailableRobots = available == null ? 0 : available;
			this.robotShortfall = Math.max(0, this.pendingUnassignedLines - this.idleAvailableRobots);
			this.draftOrderNames = draftNames == null ? '' : draftNames;
		}
	}

	/**
	* Thrown when a warehouse cannot be resolved.
	*/
	public class WarehouseServiceException extends Exception {
	}
}
