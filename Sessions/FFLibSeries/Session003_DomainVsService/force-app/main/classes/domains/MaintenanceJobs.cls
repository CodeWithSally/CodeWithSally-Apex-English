/**
 * Domain for Maintenance Job records. Owns job lifecycle and cost from health at start.
 */
public virtual inherited sharing class MaintenanceJobs extends fflib_SObjects {
	/** Planned service, not a breakdown. */
	public static final String TYPE_SCHEDULED = 'Scheduled';
	/** Unplanned failure service. */
	public static final String TYPE_FAILURE = 'Failure';
	/** Job is booked but not started. */
	public static final String STATUS_SCHEDULED = 'Scheduled';
	/** Job is underway; the robot is offline. */
	public static final String STATUS_IN_PROGRESS = 'In Progress';
	/** Job is finished and cost is set. */
	public static final String STATUS_COMPLETED = 'Completed';

	/** Service cost when health at start is Healthy. */
	public static final Decimal COST_HEALTHY = 100;
	/** Service cost when health at start is Warning. */
	public static final Decimal COST_WARNING = 250;
	/** Service cost when health at start is Critical. */
	public static final Decimal COST_CRITICAL = 500;

	@TestVisible
	private static MaintenanceJobs mock;

	/**
	* Factory that wraps the given job records, or {@link #mock} when tests have set one.
	* @param recordList Jobs to manage. Null is treated as an empty list.
	* @return {@link MaintenanceJobs} instance.
	*/
	public static MaintenanceJobs newInstance(List<MaintenanceJob__c> recordList) {
		return mock != null ? mock : new MaintenanceJobs(recordList);
	}

	/**
	* Creates a domain wrapping the given Maintenance Job records.
	* @param sObjectList Jobs to manage. Null is treated as an empty list.
	*/
	public MaintenanceJobs(List<MaintenanceJob__c> sObjectList) {
		super(sObjectList == null ? new List<MaintenanceJob__c>() : sObjectList);
	}

	/**
	* Builds a job for a robot that is going offline now. Type is Scheduled; status is In Progress
	* because the robot has already been taken out of the pool.
	* @param robotId Robot the job is for. Cannot be null.
	* @param healthAtStart Health captured when the robot is taken offline.
	* @return New MaintenanceJob__c in memory.
	*/
	public static MaintenanceJob__c newScheduledJob(Id robotId, String healthAtStart) {
		return new MaintenanceJob__c(
			Robot__c = robotId,
			Type__c = TYPE_SCHEDULED,
			Status__c = STATUS_IN_PROGRESS,
			Reason__c = 'Due for service',
			HealthAtStart__c = healthAtStart
		);
	}

	/**
	* Scheduled to In Progress. Stamps HealthAtStart when missing.
	* @param healthByRobotId Fallback health by robot Id when HealthAtStart is blank.
	* @param uow Unit of Work that receives dirty jobs. Cannot be null.
	*/
	public virtual void start(Map<Id, String> healthByRobotId, fflib_SObjectUnitOfWork uow) {
		for (MaintenanceJob__c job : (List<MaintenanceJob__c>) getRecords()) {
			if (job.Status__c != STATUS_SCHEDULED) {
				throw new MaintenanceJobsException(
					'Job ' + job.Name + ' must be Scheduled to start.'
				);
			}

			// Stamp health now so later cost uses the condition at start
			job.Status__c = STATUS_IN_PROGRESS;
			if (String.isBlank(job.HealthAtStart__c) && healthByRobotId != null) {
				job.HealthAtStart__c = healthByRobotId.get(job.Robot__c);
			}
			uow.registerDirty(
				new MaintenanceJob__c(
					Id = job.Id,
					Status__c = STATUS_IN_PROGRESS,
					HealthAtStart__c = job.HealthAtStart__c
				)
			);
		}
	}

	/**
	* In Progress to Completed. Sets cost from health at start.
	* @param uow Unit of Work that receives dirty jobs. Cannot be null.
	*/
	public virtual void complete(fflib_SObjectUnitOfWork uow) {
		for (MaintenanceJob__c job : (List<MaintenanceJob__c>) getRecords()) {
			if (job.Status__c != STATUS_IN_PROGRESS) {
				throw new MaintenanceJobsException(
					'Job ' + job.Name + ' must be In Progress to complete.'
				);
			}

			// Cost comes from health captured when the job started
			job.Status__c = STATUS_COMPLETED;
			job.Cost__c = costFromHealth(job.HealthAtStart__c);
			uow.registerDirty(
				new MaintenanceJob__c(
					Id = job.Id,
					Status__c = STATUS_COMPLETED,
					Cost__c = job.Cost__c
				)
			);
		}
	}

	/**
	* Service cost for a robot health value captured at job start.
	* @param health Health picklist value captured at service start.
	* @return Cost for that health. Unknown health uses the Healthy cost.
	*/
	public static Decimal costFromHealth(String health) {
		if (health == Robots.HEALTH_CRITICAL) {
			return COST_CRITICAL;
		}
		if (health == Robots.HEALTH_WARNING) {
			return COST_WARNING;
		}
		return COST_HEALTHY;
	}

	/**
	* Robot Ids on the jobs in this domain.
	* @return Distinct robot Ids on the jobs in this domain.
	*/
	public virtual Set<Id> getRobotIds() {
		Set<Id> robotIds = new Set<Id>();
		for (MaintenanceJob__c job : (List<MaintenanceJob__c>) getRecords()) {
			if (job.Robot__c != null) {
				robotIds.add(job.Robot__c);
			}
		}
		return robotIds;
	}

	/**
	* Thrown when a job cannot start or complete.
	*/
	public class MaintenanceJobsException extends Exception {
	}
}
