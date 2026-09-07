/**
 * Domain for Fulfillment Order records. Owns release, hold, and complete-when-lines-done.
 */
public virtual inherited sharing class FulfillmentOrders extends fflib_SObjects {
	/** Order is not yet on the floor. */
	public static final String STATUS_DRAFT = 'Draft';
	/** Order is released and ready to dispatch. */
	public static final String STATUS_RELEASED = 'Released';
	/** At least one line has been assigned. */
	public static final String STATUS_IN_PROGRESS = 'In Progress';
	/** Every related line is complete. */
	public static final String STATUS_COMPLETED = 'Completed';
	/** Order is held and not dispatchable. */
	public static final String STATUS_ON_HOLD = 'On Hold';

	@TestVisible
	private static FulfillmentOrders mock;

	/**
	 * Factory that wraps the given order records, or {@link #mock} when tests have set one.
	 * @param recordList Orders to manage. Null is treated as an empty list.
	 * @return {@link FulfillmentOrders} instance.
	 */
	public static FulfillmentOrders newInstance(List<FulfillmentOrder__c> recordList) {
		return mock != null ? mock : new FulfillmentOrders(recordList);
	}

	/**
	 * Creates a domain wrapping the given Fulfillment Order records.
	 * @param sObjectList Orders to manage. Null is treated as an empty list.
	 */
	public FulfillmentOrders(List<FulfillmentOrder__c> sObjectList) {
		super(sObjectList == null ? new List<FulfillmentOrder__c>() : sObjectList);
	}

	/**
	 * Draft to Released. Requires at least one line.
	 * @param uow Unit of Work that receives dirty orders. Cannot be null.
	 */
	public virtual void release(fflib_SObjectUnitOfWork uow) {
		for (FulfillmentOrder__c order : (List<FulfillmentOrder__c>) getRecords()) {
			if (order.Status__c != STATUS_DRAFT) {
				throw new FulfillmentOrdersException(
					'Order ' + order.Name + ' must be Draft to release.'
				);
			}
			if (order.FulfillmentLines__r == null || order.FulfillmentLines__r.isEmpty()) {
				throw new FulfillmentOrdersException(
					'Order ' + order.Name + ' has no lines to release.'
				);
			}
			order.Status__c = STATUS_RELEASED;
			registerStatusDirty(uow, order);
		}
	}

	/**
	 * Released or In Progress to On Hold.
	 * @param uow Unit of Work that receives dirty orders. Cannot be null.
	 */
	public virtual void hold(fflib_SObjectUnitOfWork uow) {
		for (FulfillmentOrder__c order : (List<FulfillmentOrder__c>) getRecords()) {
			if (order.Status__c != STATUS_RELEASED && order.Status__c != STATUS_IN_PROGRESS) {
				throw new FulfillmentOrdersException(
					'Order ' + order.Name + ' cannot be held from ' + order.Status__c + '.'
				);
			}
			order.Status__c = STATUS_ON_HOLD;
			registerStatusDirty(uow, order);
		}
	}

	/**
	 * On Hold to Released.
	 * @param uow Unit of Work that receives dirty orders. Cannot be null.
	 */
	public virtual void unhold(fflib_SObjectUnitOfWork uow) {
		for (FulfillmentOrder__c order : (List<FulfillmentOrder__c>) getRecords()) {
			if (order.Status__c != STATUS_ON_HOLD) {
				throw new FulfillmentOrdersException(
					'Order ' + order.Name + ' is not on hold.'
				);
			}
			order.Status__c = STATUS_RELEASED;
			registerStatusDirty(uow, order);
		}
	}

	/**
	 * Released to In Progress. Already In Progress is a no-op.
	 * @param uow Unit of Work that receives dirty orders. Cannot be null.
	 */
	public virtual void markInProgress(fflib_SObjectUnitOfWork uow) {
		for (FulfillmentOrder__c order : (List<FulfillmentOrder__c>) getRecords()) {
			if (order.Status__c == STATUS_IN_PROGRESS) {
				continue;
			}
			if (order.Status__c != STATUS_RELEASED) {
				throw new FulfillmentOrdersException(
					'Order ' + order.Name + ' must be Released to start.'
				);
			}
			order.Status__c = STATUS_IN_PROGRESS;
			registerStatusDirty(uow, order);
		}
	}

	/**
	 * Sets Completed when every related line is Complete.
	 * Only Released or In Progress orders close. Requires lines to be queried.
	 * @param uow Unit of Work that receives dirty orders. Cannot be null.
	 */
	public virtual void complete(fflib_SObjectUnitOfWork uow) {
		complete(uow, new Set<Id>());
	}

	/**
	 * Sets Completed when every related line is Complete.
	 * Lines in completingLineIds count as Complete (same commit, different instances).
	 * Only Released or In Progress orders close. Requires lines to be queried.
	 * @param uow Unit of Work that receives dirty orders. Cannot be null.
	 * @param completingLineIds Line Ids completed in this commit. Null is treated as empty.
	 */
	public virtual void complete(
		fflib_SObjectUnitOfWork uow,
		Set<Id> completingLineIds
	) {
		Set<Id> justCompleted = completingLineIds == null ? new Set<Id>() : completingLineIds;
		for (FulfillmentOrder__c order : (List<FulfillmentOrder__c>) getRecords()) {
			if (
				order.Status__c != STATUS_RELEASED
				&& order.Status__c != STATUS_IN_PROGRESS
			) {
				continue;
			}
			if (order.FulfillmentLines__r == null || order.FulfillmentLines__r.isEmpty()) {
				continue;
			}

			// Only close when every related line is Complete
			Boolean allComplete = true;
			for (FulfillmentLine__c line : order.FulfillmentLines__r) {
				if (
					line.Status__c != FulfillmentLines.STATUS_COMPLETE
					&& !justCompleted.contains(line.Id)
				) {
					allComplete = false;
					break;
				}
			}
			if (allComplete) {
				order.Status__c = STATUS_COMPLETED;
				registerStatusDirty(uow, order);
			}
		}
	}

	private static void registerStatusDirty(fflib_SObjectUnitOfWork uow, FulfillmentOrder__c order) {
		uow.registerDirty(new FulfillmentOrder__c(Id = order.Id, Status__c = order.Status__c));
	}

	/**
	 * Thrown when an order status change is illegal.
	 */
	public class FulfillmentOrdersException extends Exception {
	}
}
