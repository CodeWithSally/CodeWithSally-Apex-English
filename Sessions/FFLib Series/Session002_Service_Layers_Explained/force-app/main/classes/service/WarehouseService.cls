/**
 * Warehouse desk: snapshot pending work, idle robots, and draft orders.
 * Spans Warehouse, Fulfillment Line, Fulfillment Order, and Robot.
 */
public virtual inherited sharing class WarehouseService {
	@TestVisible
	private static WarehouseService mock;

	/**
	 * Factory that returns this service, or {@link #mock} when tests have set one.
	 * @return {@link WarehouseService} instance.
	 */
	public static WarehouseService newInstance() {
		return mock != null ? mock : new WarehouseService();
	}

	private WarehousesSelector warehouseSelector;
	private FulfillmentLinesSelector lineSelector;
	private RobotsSelector robotSelector;
	private FulfillmentOrdersSelector orderSelector;

	/**
	 * Constructs a service wired to the live selectors.
	 */
	public WarehouseService() {
		this.warehouseSelector = WarehousesSelector.newInstance();
		this.lineSelector = FulfillmentLinesSelector.newInstance();
		this.robotSelector = RobotsSelector.newInstance();
		this.orderSelector = FulfillmentOrdersSelector.newInstance();
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
