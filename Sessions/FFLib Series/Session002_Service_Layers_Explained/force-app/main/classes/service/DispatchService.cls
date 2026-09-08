/**
 * Dispatch process: match idle robots to pending pick lines at a warehouse.
 * Spans Warehouse, Robot, Robot Model (max load), Fulfillment Line, and Fulfillment Order.
 * Each method that persists creates a fresh {@link UnitOfWork#newInstance}.
 */
public virtual inherited sharing class DispatchService {
	private final FulfillmentLinesSelector lineSelector;
	private final RobotsSelector robotSelector;
	private final FulfillmentOrdersSelector orderSelector;

	/**
	* Default composition: live selectors.
	* @return {@link DispatchService} instance.
	*/
	public static DispatchService newInstance() {
		return new DispatchService(
			FulfillmentLinesSelector.newInstance(),
			RobotsSelector.newInstance(),
			FulfillmentOrdersSelector.newInstance()
		);
	}

	/**
	* Creates a service with the given selectors.
	* @param lineSelector Line selector. Cannot be null.
	* @param robotSelector Robot selector. Cannot be null.
	* @param orderSelector Order selector. Cannot be null.
	*/
	public DispatchService(
		FulfillmentLinesSelector lineSelector,
		RobotsSelector robotSelector,
		FulfillmentOrdersSelector orderSelector
	) {
		this.lineSelector = lineSelector;
		this.robotSelector = robotSelector;
		this.orderSelector = orderSelector;
	}

	/**
	* Runs dispatch at the given warehouses: one available Robot per pending Fulfillment Line
	* that fits the Robot Model max load. Matching stays inside each Warehouse.
	* Updates Robot, Fulfillment Line, and Fulfillment Order in one Unit of Work.
	* @param warehouseIds Warehouses to dispatch. Empty set performs no DML.
	* @throws DispatchServiceException if a domain rule fails or DML fails.
	*/
	@SuppressWarnings('PMD.DetectCopyPasteForApex') // teaching: keep this method readable top-to-bottom; extract markReleasedOrdersInProgress(orderIds) to DRY
	public virtual void dispatchWarehouses(Set<Id> warehouseIds) {
		if (warehouseIds == null || warehouseIds.isEmpty()) {
			return;
		}
		try {
			fflib_SObjectUnitOfWork uow = UnitOfWork.newInstance();
			// Load Fulfillment Line and Robot records at these Warehouses
			List<FulfillmentLine__c> pending = lineSelector.selectPendingUnassignedByWarehouseWithOrder(warehouseIds);
			if (pending.isEmpty()) {
				return;
			}
			List<Robot__c> idle = robotSelector.selectIdleByWarehouseWithModel(warehouseIds);

			// Robot domain: keep only robots that can legally accept work
			List<Robot__c> available = Robots.newInstance(idle).getAvailableForWork();
			if (available.isEmpty()) {
				return;
			}

			// One Robot per Fulfillment Line that fits the Robot Model max load; stay inside one Warehouse
			Map<Id, Id> robotIdByLineId = match(pending, available);
			if (robotIdByLineId.isEmpty()) {
				return;
			}

			// Robot: Idle to Working for each robot that received a line
			Set<Id> assignedRobotIds = new Set<Id>(robotIdByLineId.values());
			List<Robot__c> robotsToStart = new List<Robot__c>();
			for (Robot__c robot : available) {
				if (assignedRobotIds.contains(robot.Id)) {
					robotsToStart.add(robot);
				}
			}
			Robots.newInstance(robotsToStart).startWork(uow);

			// Fulfillment Line: Pending to Assigned with that robot
			List<FulfillmentLine__c> linesToAssign = new List<FulfillmentLine__c>();
			Set<Id> orderIds = new Set<Id>();
			for (FulfillmentLine__c line : pending) {
				if (robotIdByLineId.containsKey(line.Id)) {
					linesToAssign.add(line);
					orderIds.add(line.FulfillmentOrder__c);
				}
			}
			FulfillmentLines.newInstance(linesToAssign).assign(robotIdByLineId, uow);

			// Fulfillment Order: Released to In Progress once a child line is assigned
			List<FulfillmentOrder__c> orders = orderSelector.selectById(orderIds);
			List<FulfillmentOrder__c> released = new List<FulfillmentOrder__c>();
			for (FulfillmentOrder__c order : orders) {
				if (order.Status__c == FulfillmentOrders.STATUS_RELEASED) {
					released.add(order);
				}
			}
			if (!released.isEmpty()) {
				FulfillmentOrders.newInstance(released).markInProgress(uow);
			}

			// One Unit of Work commits Robot, Fulfillment Line, and Fulfillment Order together
			uow.commitWork();
		} catch (Exception e) {
			throw wrap(e);
		}
	}

	/**
	* Assigns given Robot to Fulfillment Line pairs and marks parent Fulfillment Orders In Progress.
	* @param robotIdByLineId Line Id to robot Id. Empty map performs no DML.
	* @throws DispatchServiceException if a domain rule fails or DML fails.
	*/
	@SuppressWarnings('PMD.DetectCopyPasteForApex') // teaching: keep this method readable top-to-bottom; extract markReleasedOrdersInProgress(orderIds) to DRY
	public virtual void assignRobots(Map<Id, Id> robotIdByLineId) {
		if (robotIdByLineId == null || robotIdByLineId.isEmpty()) {
			return;
		}
		try {
			fflib_SObjectUnitOfWork uow = UnitOfWork.newInstance();
			// Load the named Fulfillment Line and Robot records
			List<FulfillmentLine__c> lines = lineSelector.selectById(robotIdByLineId.keySet());
			List<Robot__c> robotRecords = robotSelector.selectByIdWithModel(new Set<Id>(robotIdByLineId.values()));

			// Robot Idle to Working; Fulfillment Line Pending to Assigned
			Robots.newInstance(robotRecords).startWork(uow);
			FulfillmentLines.newInstance(lines).assign(robotIdByLineId, uow);

			// Fulfillment Order: Released to In Progress once a child line is assigned
			Set<Id> orderIds = new Set<Id>();
			for (FulfillmentLine__c line : lines) {
				orderIds.add(line.FulfillmentOrder__c);
			}
			List<FulfillmentOrder__c> orders = orderSelector.selectById(orderIds);
			List<FulfillmentOrder__c> released = new List<FulfillmentOrder__c>();
			for (FulfillmentOrder__c order : orders) {
				if (order.Status__c == FulfillmentOrders.STATUS_RELEASED) {
					released.add(order);
				}
			}
			if (!released.isEmpty()) {
				FulfillmentOrders.newInstance(released).markInProgress(uow);
			}

			uow.commitWork();
		} catch (Exception e) {
			throw wrap(e);
		}
	}

	/**
	* Submits {@link DispatchPendingJob} as a Batch Apex job.
	* @return Async Apex job Id.
	*/
	public Id submitDispatchJob() {
		return Database.executeBatch(new DispatchPendingJob());
	}

	private static Map<Id, Id> match(List<FulfillmentLine__c> lines, List<Robot__c> robots) {
		// Group Fulfillment Lines by the Warehouse on their parent Fulfillment Order
		Map<Id, List<FulfillmentLine__c>> linesByWarehouse = new Map<Id, List<FulfillmentLine__c>>();
		for (FulfillmentLine__c line : lines) {
			Id warehouseId = line.FulfillmentOrder__r != null ? line.FulfillmentOrder__r.Warehouse__c : null;
			if (warehouseId == null) {
				continue;
			}
			if (!linesByWarehouse.containsKey(warehouseId)) {
				linesByWarehouse.put(warehouseId, new List<FulfillmentLine__c>());
			}
			linesByWarehouse.get(warehouseId).add(line);
		}

		// Group Robots by the Warehouse they belong to
		Map<Id, List<Robot__c>> robotsByWarehouse = new Map<Id, List<Robot__c>>();
		for (Robot__c robot : robots) {
			if (robot.Warehouse__c == null) {
				continue;
			}
			if (!robotsByWarehouse.containsKey(robot.Warehouse__c)) {
				robotsByWarehouse.put(robot.Warehouse__c, new List<Robot__c>());
			}
			robotsByWarehouse.get(robot.Warehouse__c).add(robot);
		}

		// Pair Fulfillment Lines and Robots only inside the same Warehouse
		Map<Id, Id> robotIdByLineId = new Map<Id, Id>();
		for (Id warehouseId : linesByWarehouse.keySet()) {
			List<Robot__c> warehouseRobots = robotsByWarehouse.get(warehouseId);
			if (warehouseRobots == null || warehouseRobots.isEmpty()) {
				continue;
			}
			robotIdByLineId.putAll(matchAtWarehouse(linesByWarehouse.get(warehouseId), warehouseRobots));
		}
		return robotIdByLineId;
	}

	private static Map<Id, Id> matchAtWarehouse(List<FulfillmentLine__c> lines, List<Robot__c> robots) {
		Map<Id, Id> robotIdByLineId = new Map<Id, Id>();
		Set<Id> usedRobotIds = new Set<Id>();
		for (FulfillmentLine__c line : lines) {
			for (Robot__c robot : robots) {
				// Skip a Robot already claimed by an earlier Fulfillment Line
				if (usedRobotIds.contains(robot.Id)) {
					continue;
				}
				// Skip a Robot whose Robot Model cannot carry this Fulfillment Line's weight
				Decimal maxLoad = robot.Model__r != null ? robot.Model__r.MaxLoadKg__c : null;
				Decimal weight = line.WeightKg__c == null ? 0 : line.WeightKg__c;
				if (maxLoad != null && weight > maxLoad) {
					continue;
				}
				robotIdByLineId.put(line.Id, robot.Id);
				usedRobotIds.add(robot.Id);
				break;
			}
		}
		return robotIdByLineId;
	}

	private static DispatchServiceException wrap(Exception e) {
		if (e instanceof DispatchServiceException) {
			return (DispatchServiceException) e;
		}
		if (e instanceof DmlException) {
			return new DispatchServiceException(
				'Error in dispatch: ' + ((DmlException) e).getDmlMessage(0),
				e
			);
		}
		return new DispatchServiceException(e.getMessage(), e);
	}

	/**
	* Client-agnostic exception thrown by dispatch service methods.
	*/
	public class DispatchServiceException extends Exception {
	}
}
