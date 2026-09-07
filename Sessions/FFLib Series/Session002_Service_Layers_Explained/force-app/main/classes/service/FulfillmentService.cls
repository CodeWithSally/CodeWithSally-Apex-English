/**
 * Fulfillment process: release pick work to the floor and complete it.
 * Spans Warehouse, Fulfillment Order, Fulfillment Line, and Robot.
 * Completing a line may hand a due Robot to the Maintenance process on the same Unit of Work.
 */
public virtual inherited sharing class FulfillmentService {
	@TestVisible
	private static FulfillmentService mock;

	/**
	 * Factory that returns this service, or {@link #mock} when tests have set one.
	 * @return {@link FulfillmentService} instance.
	 */
	public static FulfillmentService newInstance() {
		return mock != null ? mock : new FulfillmentService();
	}

	private FulfillmentOrdersSelector orderSelector;
	private FulfillmentLinesSelector lineSelector;
	private RobotsSelector robotSelector;
	private WarehousesSelector warehouseSelector;

	/**
	 * Constructs a service wired to the live selectors.
	 */
	public FulfillmentService() {
		this.orderSelector = FulfillmentOrdersSelector.newInstance();
		this.lineSelector = FulfillmentLinesSelector.newInstance();
		this.robotSelector = RobotsSelector.newInstance();
		this.warehouseSelector = WarehousesSelector.newInstance();
	}

	/**
	 * Release process: Draft Fulfillment Orders become Released after the Warehouse is confirmed Active.
	 * Touches Warehouse and Fulfillment Order (orders must have Fulfillment Lines).
	 * @param orderIds Order Ids to release. Empty set performs no DML.
	 * @throws FulfillmentServiceException if a domain rule fails or DML fails.
	 */
	public virtual void releaseOrders(Set<Id> orderIds) {
		if (orderIds == null || orderIds.isEmpty()) {
			return;
		}
		try {
			fflib_SObjectUnitOfWork uow = UnitOfWork.newInstance();

			// Load Fulfillment Orders with their Fulfillment Lines
			List<FulfillmentOrder__c> orders = orderSelector.selectByIdWithLines(orderIds);

			// Warehouse must be Active before this pick work can be released
			Set<Id> warehouseIds = new Set<Id>();
			for (FulfillmentOrder__c order : orders) {
				if (order.Warehouse__c != null) {
					warehouseIds.add(order.Warehouse__c);
				}
			}
			Warehouses.newInstance(
				warehouseSelector.selectById(warehouseIds)).
					assertCanAcceptWork(warehouseIds);

			// Fulfillment Order: Draft to Released
			FulfillmentOrders.newInstance(orders).release(uow);
			uow.commitWork();
		} catch (Exception e) {
			throw wrap(e);
		}
	}

	/**
	 * Hold process: Released or In Progress Fulfillment Orders move to On Hold.
	 * @param orderIds Order Ids to hold. Empty set performs no DML.
	 * @throws FulfillmentServiceException if a domain rule fails or DML fails.
	 */
	public void holdOrders(Set<Id> orderIds) {
		if (orderIds == null || orderIds.isEmpty()) {
			return;
		}
		try {
			fflib_SObjectUnitOfWork uow = UnitOfWork.newInstance();
			FulfillmentOrders.newInstance(orderSelector.selectById(orderIds)).hold(uow);
			uow.commitWork();
		} catch (Exception e) {
			throw wrap(e);
		}
	}

	/**
	 * Complete process: finish assigned Fulfillment Lines, return Robots to Idle, apply wear,
	 * and close the parent Fulfillment Order when every line is done.
	 * Robots then due for service are handed to {@link MaintenanceService} on the same Unit of Work.
	 * @param lineIds Line Ids to complete. Empty set performs no DML.
	 * @throws FulfillmentServiceException if a domain rule fails or DML fails.
	 */
	public virtual void completeLines(Set<Id> lineIds) {
		if (lineIds == null || lineIds.isEmpty()) {
			return;
		}
		try {
			completeLines(lineSelector.selectById(lineIds));
		} catch (Exception e) {
			throw wrap(e);
		}
	}

	/**
	 * Complete process for lines already loaded. Skips the line re-query.
	 * @param lines Lines to complete. Empty list performs no DML.
	 * @throws FulfillmentServiceException if a domain rule fails or DML fails.
	 */
	public virtual void completeLines(List<FulfillmentLine__c> lines) {
		if (lines == null || lines.isEmpty()) {
			return;
		}
		try {
			fflib_SObjectUnitOfWork uow = UnitOfWork.newInstance();

			// Fulfillment Line: Assigned to Complete
			FulfillmentLines fulfillmentLines = FulfillmentLines.newInstance(lines);
			fulfillmentLines.complete(uow);

			// Robot: return to Idle and apply wear for the hours on those lines
			Map<Id, Decimal> hoursByRobotId = fulfillmentLines.getEstimatedHoursByAssignedRobotId();
			List<Robot__c> robotRecords = robotSelector.selectByIdWithModel(hoursByRobotId.keySet());
			Robots robots = Robots.newInstance(robotRecords);
			robots.goIdle(uow);
			robots.applyWear(hoursByRobotId, uow);

			// Fulfillment Order: Completed when every related Fulfillment Line is Complete
			Set<Id> orderIds = new Set<Id>();
			for (FulfillmentLine__c line : lines) {
				if (line.FulfillmentOrder__c != null) {
					orderIds.add(line.FulfillmentOrder__c);
				}
			}
			List<FulfillmentOrder__c> orders = orderSelector.selectByIdWithLines(orderIds);
			Set<Id> lineIds = new Map<Id, FulfillmentLine__c>(lines).keySet();
			FulfillmentOrders.newInstance(orders).complete(uow, lineIds);

			// Maintenance process: due Robots share this Unit of Work (Robot + Maintenance Job)
			Set<Robot__c> dueRobots = robots.getDueForService();
			if (!dueRobots.isEmpty()) {
				MaintenanceService.newInstance().scheduleService(dueRobots, uow);
			}

			uow.commitWork();
		} catch (Exception e) {
			throw wrap(e);
		}
	}

	/**
	 * Completes every assigned line on the given orders.
	 * @param orderIds Order Ids whose assigned lines should complete. Empty set performs no DML.
	 */
	public virtual void completeAssignedLinesForOrders(Set<Id> orderIds) {
		if (orderIds == null || orderIds.isEmpty()) {
			return;
		}
		completeLines(lineSelector.selectAssignedByOrderId(orderIds));
	}

	private static FulfillmentServiceException wrap(Exception e) {
		if (e instanceof FulfillmentServiceException) {
			return (FulfillmentServiceException) e;
		}
		if (e instanceof DmlException) {
			return new FulfillmentServiceException(
				'Error in fulfillment: ' + ((DmlException) e).getDmlMessage(0),
				e
			);
		}
		return new FulfillmentServiceException(e.getMessage(), e);
	}

	/**
	 * Client-agnostic exception thrown by fulfillment service methods.
	 */
	public class FulfillmentServiceException extends Exception {
	}
}
