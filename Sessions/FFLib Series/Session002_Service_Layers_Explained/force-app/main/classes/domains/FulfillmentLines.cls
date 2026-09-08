/**
 * Domain for Fulfillment Line records. Owns assign, complete, and estimated hours.
 */
public virtual inherited sharing class FulfillmentLines extends fflib_SObjects {
	/** Line is waiting for a robot. */
	public static final String STATUS_PENDING = 'Pending';
	/** Line has an assigned robot. */
	public static final String STATUS_ASSIGNED = 'Assigned';
	/** Line pick is finished. */
	public static final String STATUS_COMPLETE = 'Complete';

	@TestVisible
	private static FulfillmentLines mock;

	/**
	* Factory that wraps the given line records, or {@link #mock} when tests have set one.
	* @param recordList Lines to manage. Null is treated as an empty list.
	* @return {@link FulfillmentLines} instance.
	*/
	public static FulfillmentLines newInstance(List<FulfillmentLine__c> recordList) {
		return mock != null ? mock : new FulfillmentLines(recordList);
	}

	/**
	* Creates a domain wrapping the given Fulfillment Line records.
	* @param sObjectList Lines to manage. Null is treated as an empty list.
	*/
	public FulfillmentLines(List<FulfillmentLine__c> sObjectList) {
		super(sObjectList == null ? new List<FulfillmentLine__c>() : sObjectList);
	}

	/**
	* Pending to Assigned for each line, using the robot Id mapped by line Id.
	* @param robotIdByLineId Map of line Id to robot Id. Missing keys throw.
	* @param uow Unit of Work that receives dirty lines. Cannot be null.
	*/
	public virtual void assign(Map<Id, Id> robotIdByLineId, fflib_SObjectUnitOfWork uow) {
		for (FulfillmentLine__c line : (List<FulfillmentLine__c>) getRecords()) {
			if (line.Status__c != STATUS_PENDING) {
				throw new FulfillmentLinesException(
					'Line ' + line.Name + ' must be Pending to assign.'
				);
			}
			Id robotId = robotIdByLineId.get(line.Id);
			if (robotId == null) {
				throw new FulfillmentLinesException(
					'Line ' + line.Name + ' has no robot to assign.'
				);
			}

			// Pending to Assigned with the robot from the map
			line.Status__c = STATUS_ASSIGNED;
			line.AssignedRobot__c = robotId;
			uow.registerDirty(
				new FulfillmentLine__c(
					Id = line.Id,
					Status__c = STATUS_ASSIGNED,
					AssignedRobot__c = robotId
				)
			);
		}
	}

	/**
	* Assigned to Complete.
	* @param uow Unit of Work that receives dirty lines. Cannot be null.
	*/
	public virtual void complete(fflib_SObjectUnitOfWork uow) {
		for (FulfillmentLine__c line : (List<FulfillmentLine__c>) getRecords()) {
			if (line.Status__c != STATUS_ASSIGNED) {
				throw new FulfillmentLinesException(
					'Line ' + line.Name + ' must be Assigned to complete.'
				);
			}
			line.Status__c = STATUS_COMPLETE;
			uow.registerDirty(new FulfillmentLine__c(Id = line.Id, Status__c = STATUS_COMPLETE));
		}
	}

	/**
	* Estimated hours for one line: quantity times weight over 100, minimum 1.
	* @param line Line to estimate. Cannot be null.
	* @return Hours as a Decimal, never below 1 when quantity and weight are present.
	*/
	public static Decimal estimatedHours(FulfillmentLine__c line) {
		Decimal quantity = line.Quantity__c == null ? 0 : line.Quantity__c;
		Decimal weight = line.WeightKg__c == null ? 0 : line.WeightKg__c;
		Decimal hours = (quantity * weight) / 100;
		return hours < 1 ? 1 : hours;
	}

	/**
	* Hours each assigned robot will spend on the lines in this domain.
	* @return Hours keyed by AssignedRobot__c for lines that have a robot.
	*/
	public virtual Map<Id, Decimal> getEstimatedHoursByAssignedRobotId() {
		Map<Id, Decimal> hoursByRobotId = new Map<Id, Decimal>();
		for (FulfillmentLine__c line : (List<FulfillmentLine__c>) getRecords()) {
			if (line.AssignedRobot__c == null) {
				continue;
			}
			Decimal current = hoursByRobotId.containsKey(line.AssignedRobot__c)
				? hoursByRobotId.get(line.AssignedRobot__c)
				: 0;
			hoursByRobotId.put(line.AssignedRobot__c, current + estimatedHours(line));
		}
		return hoursByRobotId;
	}

	/**
	* Parent fulfillment order Ids on the lines in this domain.
	* @return Distinct parent order Ids.
	*/
	public virtual Set<Id> getOrderIds() {
		Set<Id> orderIds = new Set<Id>();
		for (FulfillmentLine__c line : (List<FulfillmentLine__c>) getRecords()) {
			if (line.FulfillmentOrder__c != null) {
				orderIds.add(line.FulfillmentOrder__c);
			}
		}
		return orderIds;
	}

	/**
	* Thrown when a line cannot be assigned or completed.
	*/
	public class FulfillmentLinesException extends Exception {
	}
}
