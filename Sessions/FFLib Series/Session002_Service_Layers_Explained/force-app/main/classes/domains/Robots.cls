/**
 * Domain for Robot records. Owns health, wear, and legal status transitions.
 */
public virtual inherited sharing class Robots extends fflib_SObjects {
	/** Robot is available for assignment. */
	public static final String STATUS_IDLE = 'Idle';
	/** Robot is assigned to a pick. */
	public static final String STATUS_WORKING = 'Working';
	/** Robot is charging and not dispatchable. */
	public static final String STATUS_CHARGING = 'Charging';
	/** Robot is in maintenance. */
	public static final String STATUS_IN_SERVICE = 'InService';
	/** Robot is offline. */
	public static final String STATUS_OFFLINE = 'Offline';

	/** Wear is below the warning threshold. */
	public static final String HEALTH_HEALTHY = 'Healthy';
	/** Wear is at or above {@link #WEAR_WARNING}. */
	public static final String HEALTH_WARNING = 'Warning';
	/** Wear is above {@link #WEAR_CRITICAL}. */
	public static final String HEALTH_CRITICAL = 'Critical';

	/** Wear percent at which health becomes Warning. */
	public static final Decimal WEAR_WARNING = 50;
	/** Wear percent above which health becomes Critical. */
	public static final Decimal WEAR_CRITICAL = 80;
	/** Wear percent at which the robot cannot accept work and is due for service. */
	public static final Decimal WEAR_CANNOT_WORK = 90;
	/** Battery percent that must be exceeded to accept work. */
	public static final Decimal MIN_BATTERY_TO_WORK = 20;
	/** Service interval used when the model does not supply one. */
	public static final Decimal DEFAULT_SERVICE_INTERVAL_HOURS = 40;

	@TestVisible
	private static Robots mock;

	/**
	 * Factory that wraps the given Robot records, or {@link #mock} when tests have set one.
	 * @param recordList Robots to manage. Null is treated as an empty list.
	 * @return {@link Robots} instance.
	 */
	public static Robots newInstance(List<Robot__c> recordList) {
		return mock != null ? mock : new Robots(recordList);
	}

	/**
	 * Creates a domain wrapping the given Robot records.
	 * @param sObjectList Robots to manage. Null is treated as an empty list.
	 */
	public Robots(List<Robot__c> sObjectList) {
		super(sObjectList == null ? new List<Robot__c>() : sObjectList);
	}

	/**
	 * Health from a wear percent: under 50 Healthy, 50–80 Warning, over 80 Critical.
	 * @param wearPercent Wear percent. Null is treated as zero.
	 * @return Health picklist value.
	 */
	public static String healthFromWear(Decimal wearPercent) {
		Decimal wear = wearPercent == null ? 0 : wearPercent;
		if (wear > WEAR_CRITICAL) {
			return HEALTH_CRITICAL;
		}
		if (wear >= WEAR_WARNING) {
			return HEALTH_WARNING;
		}
		return HEALTH_HEALTHY;
	}

	/**
	 * @return True when the robot is idle, not critical, under 90% wear, and above 20% battery.
	 */
	public static Boolean canAcceptWork(Robot__c robot) {
		Decimal wear = robot.WearPercent__c == null ? 0 : robot.WearPercent__c;
		Decimal battery = robot.BatteryLevel__c == null ? 0 : robot.BatteryLevel__c;
		return robot.Status__c == STATUS_IDLE
			&& robot.Health__c != HEALTH_CRITICAL
			&& wear < WEAR_CANNOT_WORK
			&& battery > MIN_BATTERY_TO_WORK;
	}

	/**
	 * @return Robots in this domain that {@link #canAcceptWork} would accept.
	 */
	public virtual List<Robot__c> getAvailableForWork() {
		List<Robot__c> available = new List<Robot__c>();
		for (Robot__c robot : (List<Robot__c>) getRecords()) {
			if (canAcceptWork(robot)) {
				available.add(robot);
			}
		}
		return available;
	}

	/**
	 * Idle to Working. Registers a minimal dirty record.
	 * @param uow Unit of Work that receives dirty robots. Cannot be null.
	 */
	public virtual void startWork(fflib_SObjectUnitOfWork uow) {
		for (Robot__c robot : (List<Robot__c>) getRecords()) {
			if (!canAcceptWork(robot)) {
				throw new RobotsException(
					'Robot ' + robot.Name + ' cannot accept work.'
				);
			}
			robot.Status__c = STATUS_WORKING;
			registerStatusDirty(uow, robot);
		}
	}

	/**
	 * Working to Idle. Registers a minimal dirty record.
	 * @param uow Unit of Work that receives dirty robots. Cannot be null.
	 */
	public virtual void goIdle(fflib_SObjectUnitOfWork uow) {
		for (Robot__c robot : (List<Robot__c>) getRecords()) {
			if (robot.Status__c != STATUS_WORKING) {
				throw new RobotsException(
					'Robot ' + robot.Name + ' is not working and cannot go idle.'
				);
			}
			robot.Status__c = STATUS_IDLE;
			registerStatusDirty(uow, robot);
		}
	}

	/**
	 * Adds hours since service, recalculates wear from the model interval, and stamps health.
	 * @param hoursByRobotId Hours to apply per robot Id. Missing keys are skipped.
	 * @param uow Unit of Work that receives dirty robots. Cannot be null.
	 */
	public virtual void applyWear(Map<Id, Decimal> hoursByRobotId, fflib_SObjectUnitOfWork uow) {
		if (hoursByRobotId == null || hoursByRobotId.isEmpty()) {
			return;
		}
		for (Robot__c robot : (List<Robot__c>) getRecords()) {
			Decimal hours = hoursByRobotId.get(robot.Id);
			if (hours == null || hours <= 0) {
				continue;
			}

			// Add the hours just worked
			Decimal currentHours = robot.HoursSinceService__c == null ? 0 : robot.HoursSinceService__c;
			robot.HoursSinceService__c = currentHours + hours;

			// Wear is hours since service over the model interval, capped at 100
			Decimal interval = serviceIntervalHours(robot);
			Decimal wear = (robot.HoursSinceService__c / interval) * 100;
			if (wear > 100) {
				wear = 100;
			}
			robot.WearPercent__c = wear;
			robot.Health__c = healthFromWear(wear);

			uow.registerDirty(
				new Robot__c(
					Id = robot.Id,
					HoursSinceService__c = robot.HoursSinceService__c,
					WearPercent__c = robot.WearPercent__c,
					Health__c = robot.Health__c,
					Status__c = robot.Status__c
				)
			);
		}
	}

	/**
	 * Idle to InService. Working robots must be returned to idle first.
	 * @param uow Unit of Work that receives dirty robots. Cannot be null.
	 */
	public virtual void takeOfflineForService(fflib_SObjectUnitOfWork uow) {
		for (Robot__c robot : (List<Robot__c>) getRecords()) {
			if (robot.Status__c == STATUS_IN_SERVICE) {
				continue;
			}
			if (robot.Status__c != STATUS_IDLE) {
				throw new RobotsException(
					'Robot ' + robot.Name + ' must be idle before it can go into service.'
				);
			}
			robot.Status__c = STATUS_IN_SERVICE;
			uow.registerDirty(
				new Robot__c(
					Id = robot.Id,
					Status__c = STATUS_IN_SERVICE,
					WearPercent__c = robot.WearPercent__c,
					HoursSinceService__c = robot.HoursSinceService__c,
					Health__c = robot.Health__c
				)
			);
		}
	}

	/**
	 * Clears wear and hours, sets health Healthy, status Idle.
	 * @param uow Unit of Work that receives dirty robots. Cannot be null.
	 */
	public virtual void restoreFromService(fflib_SObjectUnitOfWork uow) {
		for (Robot__c robot : (List<Robot__c>) getRecords()) {
			if (robot.Status__c != STATUS_IN_SERVICE) {
				throw new RobotsException(
					'Robot ' + robot.Name + ' is not in service.'
				);
			}

			// Fresh robot: no wear, no hours, Healthy, Idle
			robot.WearPercent__c = 0;
			robot.HoursSinceService__c = 0;
			robot.Health__c = HEALTH_HEALTHY;
			robot.Status__c = STATUS_IDLE;
			uow.registerDirty(
				new Robot__c(
					Id = robot.Id,
					WearPercent__c = 0,
					HoursSinceService__c = 0,
					Health__c = HEALTH_HEALTHY,
					Status__c = STATUS_IDLE
				)
			);
		}
	}

	/**
	 * @return In-memory robots that are due for service (interval reached, critical, or wear at 90+).
	 */
	public virtual Set<Robot__c> getDueForService() {
		Set<Robot__c> dueRobots = new Set<Robot__c>();
		for (Robot__c robot : (List<Robot__c>) getRecords()) {
			if (isDueForService(robot)) {
				dueRobots.add(robot);
			}
		}
		return dueRobots;
	}

	/**
	 * @return True when hours since service meet the model interval, health is Critical, or wear is 90+.
	 */
	public static Boolean isDueForService(Robot__c robot) {
		if (robot.Status__c == STATUS_IN_SERVICE) {
			return false;
		}
		Decimal hours = robot.HoursSinceService__c == null ? 0 : robot.HoursSinceService__c;
		Decimal wear = robot.WearPercent__c == null ? 0 : robot.WearPercent__c;
		return hours >= serviceIntervalHours(robot)
			|| robot.Health__c == HEALTH_CRITICAL
			|| wear >= WEAR_CANNOT_WORK;
	}

	/**
	 * @return True when the status move is legal for a record-page edit.
	 */
	public static Boolean isLegalStatusTransition(String fromStatus, String toStatus) {
		if (fromStatus == toStatus) {
			return true;
		}
		if (fromStatus == STATUS_IDLE) {
			return toStatus == STATUS_WORKING
				|| toStatus == STATUS_IN_SERVICE
				|| toStatus == STATUS_CHARGING
				|| toStatus == STATUS_OFFLINE;
		}
		if (fromStatus == STATUS_WORKING) {
			return toStatus == STATUS_IDLE
				|| toStatus == STATUS_IN_SERVICE
				|| toStatus == STATUS_OFFLINE;
		}
		if (fromStatus == STATUS_IN_SERVICE) {
			return toStatus == STATUS_IDLE || toStatus == STATUS_OFFLINE;
		}
		if (fromStatus == STATUS_CHARGING) {
			return toStatus == STATUS_IDLE || toStatus == STATUS_OFFLINE;
		}
		if (fromStatus == STATUS_OFFLINE) {
			return toStatus == STATUS_IDLE;
		}
		return false;
	}

	private static Decimal serviceIntervalHours(Robot__c robot) {
		if (robot.Model__r != null && robot.Model__r.ServiceIntervalHours__c != null
			&& robot.Model__r.ServiceIntervalHours__c > 0) {
			return robot.Model__r.ServiceIntervalHours__c;
		}
		return DEFAULT_SERVICE_INTERVAL_HOURS;
	}

	private static void registerStatusDirty(fflib_SObjectUnitOfWork uow, Robot__c robot) {
		uow.registerDirty(new Robot__c(Id = robot.Id, Status__c = robot.Status__c));
	}

	/**
	 * Thrown when a robot status or work request is illegal.
	 */
	public class RobotsException extends Exception {
	}
}
