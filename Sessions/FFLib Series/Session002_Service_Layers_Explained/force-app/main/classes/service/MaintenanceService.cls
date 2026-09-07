/**
 * Maintenance process: take robots offline for service and restore them afterward.
 * Spans Robot and Maintenance Job, and Warehouse when scanning for robots that are due.
 */
public virtual inherited sharing class MaintenanceService {
	@TestVisible
	private static MaintenanceService mock;

	/**
	 * Factory that returns this service, or {@link #mock} when tests have set one.
	 * @return {@link MaintenanceService} instance.
	 */
	public static MaintenanceService newInstance() {
		return mock != null ? mock : new MaintenanceService();
	}

	private RobotsSelector robotSelector;
	private MaintenanceJobsSelector jobSelector;

	/**
	 * Constructs a service wired to the live selectors.
	 */
	public MaintenanceService() {
		this.robotSelector = RobotsSelector.newInstance();
		this.jobSelector = MaintenanceJobsSelector.newInstance();
	}

	/**
	 * Scan Warehouses for Robots that are due, then take them offline and book Maintenance Jobs.
	 * @param warehouseIds Warehouses to scan. Empty set performs no DML.
	 * @throws MaintenanceServiceException if a domain rule fails or DML fails.
	 */
	public virtual void scheduleDueService(Set<Id> warehouseIds) {
		if (warehouseIds == null || warehouseIds.isEmpty()) {
			return;
		}
		try {
			// Scan Robots at these Warehouses; Robot domain decides who is due
			List<Robot__c> candidates = robotSelector.selectNotInServiceByWarehouseWithModel(warehouseIds);
			Set<Robot__c> dueRobots = Robots.newInstance(candidates).getDueForService();
			if (dueRobots.isEmpty()) {
				return;
			}

			fflib_SObjectUnitOfWork uow = UnitOfWork.newInstance();
			scheduleService(dueRobots, uow);
			uow.commitWork();
		} catch (Exception e) {
			throw wrap(e);
		}
	}

	/**
	 * Schedules service for the given robots and commits.
	 * @param robotIds Robot Ids to take offline. Empty set performs no DML.
	 * @throws MaintenanceServiceException if a domain rule fails or DML fails.
	 */
	public virtual void scheduleService(Set<Id> robotIds) {
		if (robotIds == null || robotIds.isEmpty()) {
			return;
		}
		try {
			fflib_SObjectUnitOfWork uow = UnitOfWork.newInstance();
			scheduleService(robotIds, uow);
			uow.commitWork();
		} catch (Exception e) {
			throw wrap(e);
		}
	}

	/**
	 * Takes idle robots offline and registers Scheduled jobs on the given Unit of Work.
	 * Does not commit. Callers such as {@link FulfillmentService} share one transaction.
	 * Skips robots that already have an open job or are already InService.
	 * @param robotIds Robot Ids to schedule. Empty set is a no-op.
	 * @param uow Unit of Work that receives dirty robots and new jobs. Cannot be null.
	 */
	public virtual void scheduleService(Set<Id> robotIds, fflib_SObjectUnitOfWork uow) {
		if (robotIds == null || robotIds.isEmpty()) {
			return;
		}
		scheduleService(robotSelector.selectByIdWithModel(robotIds), uow);
	}

	/**
	 * Takes the given in-memory robots offline and registers Scheduled jobs.
	 * Use this when the caller already applied wear or status in the same transaction.
	 * Does not commit.
	 * @param robotsToService Robot records to schedule. Empty set is a no-op.
	 * @param uow Unit of Work that receives dirty robots and new jobs. Cannot be null.
	 */
	public virtual void scheduleService(Set<Robot__c> robotsToService, fflib_SObjectUnitOfWork uow) {
		if (robotsToService == null || robotsToService.isEmpty()) {
			return;
		}
		scheduleService(new List<Robot__c>(robotsToService), uow);
	}

	/**
	 * Maintenance booking: Robot to InService and a new Maintenance Job on the same Unit of Work.
	 * Use this when the caller already applied wear or status in the same transaction.
	 * Does not commit.
	 * @param robotsToService Robot records to schedule. Empty list is a no-op.
	 * @param uow Unit of Work that receives dirty robots and new jobs. Cannot be null.
	 */
	public virtual void scheduleService(List<Robot__c> robotsToService, fflib_SObjectUnitOfWork uow) {
		if (robotsToService == null || robotsToService.isEmpty()) {
			return;
		}
		// Skip Robots that already have an open Maintenance Job or are already InService
		Set<Id> robotIds = new Map<Id, Robot__c>(robotsToService).keySet();
		Set<Id> alreadyScheduled = new Set<Id>();
		for (MaintenanceJob__c job : jobSelector.selectOpenByRobot(robotIds)) {
			alreadyScheduled.add(job.Robot__c);
		}
		List<Robot__c> eligible = new List<Robot__c>();
		for (Robot__c robot : robotsToService) {
			if (alreadyScheduled.contains(robot.Id) || robot.Status__c == Robots.STATUS_IN_SERVICE) {
				continue;
			}
			eligible.add(robot);
		}
		if (eligible.isEmpty()) {
			return;
		}

		// Robot to InService; register a new In Progress Maintenance Job
		Robots.newInstance(eligible).takeOfflineForService(uow);
		for (Robot__c robot : eligible) {
			uow.registerNew(MaintenanceJobs.newScheduledJob(robot.Id, robot.Health__c));
		}
	}

	/**
	 * Start process: Maintenance Job Scheduled to In Progress, stamping health from the Robot.
	 * @param jobIds Job Ids to start. Empty set performs no DML.
	 * @throws MaintenanceServiceException if a domain rule fails or DML fails.
	 */
	public virtual void startJobs(Set<Id> jobIds) {
		if (jobIds == null || jobIds.isEmpty()) {
			return;
		}
		try {
			fflib_SObjectUnitOfWork uow = UnitOfWork.newInstance();

			// Read current Robot health so the Maintenance Job can stamp HealthAtStart
			List<MaintenanceJob__c> jobs = jobSelector.selectByIdWithRobot(jobIds);
			Map<Id, String> healthByRobotId = new Map<Id, String>();
			for (MaintenanceJob__c job : jobs) {
				if (job.Robot__r != null) {
					healthByRobotId.put(job.Robot__c, job.Robot__r.Health__c);
				}
			}

			MaintenanceJobs.newInstance(jobs).start(healthByRobotId, uow);
			uow.commitWork();
		} catch (Exception e) {
			throw wrap(e);
		}
	}

	/**
	 * Restore process: complete the Maintenance Job and return the Robot to Idle with wear cleared.
	 * @param jobIds Job Ids to complete. Empty set performs no DML.
	 * @throws MaintenanceServiceException if a domain rule fails or DML fails.
	 */
	public virtual void completeJobs(Set<Id> jobIds) {
		if (jobIds == null || jobIds.isEmpty()) {
			return;
		}
		try {
			fflib_SObjectUnitOfWork uow = UnitOfWork.newInstance();

			// Maintenance Job: In Progress to Completed (cost from health at start)
			List<MaintenanceJob__c> jobs = jobSelector.selectByIdWithRobot(jobIds);
			MaintenanceJobs.newInstance(jobs).complete(uow);

			// Robot: clear wear and return to Idle (already on the job)
			List<Robot__c> robotRecords = new List<Robot__c>();
			for (MaintenanceJob__c job : jobs) {
				if (job.Robot__r != null) {
					robotRecords.add(job.Robot__r);
				}
			}
			Robots.newInstance(robotRecords).restoreFromService(uow);

			uow.commitWork();
		} catch (Exception e) {
			throw wrap(e);
		}
	}

	private static MaintenanceServiceException wrap(Exception e) {
		if (e instanceof MaintenanceServiceException) {
			return (MaintenanceServiceException) e;
		}
		if (e instanceof DmlException) {
			return new MaintenanceServiceException(
				'Error in maintenance: ' + ((DmlException) e).getDmlMessage(0),
				e
			);
		}
		return new MaintenanceServiceException(e.getMessage(), e);
	}

	/**
	 * Client-agnostic exception thrown by maintenance service methods.
	 */
	public class MaintenanceServiceException extends Exception {
	}
}
