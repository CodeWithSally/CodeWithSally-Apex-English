/**
 * Invocable action that schedules service for robots.
 * Delegates to {@link MaintenanceService}.
 *
 * Prefer the no-arg constructor / {@link #execute} for the default service.
 * Use the service constructor when composing deliberately (including tests).
 */
public inherited sharing class ScheduleMaintenance {
	private final MaintenanceService maintenanceSvc;

	/**
	* Default composition: {@link MaintenanceService#newInstance}.
	*/
	public ScheduleMaintenance() {
		this(MaintenanceService.newInstance());
	}

	/**
	* Creates an action with the given service.
	* @param maintenanceSvc Maintenance service. Cannot be null.
	*/
	public ScheduleMaintenance(MaintenanceService maintenanceSvc) {
		this.maintenanceSvc = maintenanceSvc;
	}

	/**
	* Schedules maintenance for the given robots through {@link MaintenanceService}.
	* @param requests Invocable requests, each with a robot Id.
	* @return One result per request, echoing the robot Id.
	*/
	@InvocableMethod(
		label='Schedule Maintenance'
		description='Takes idle robots offline and creates scheduled maintenance jobs.'
		category='Warehouse Operations'
	)
	public static List<Result> execute(List<Request> requests) {
		return new ScheduleMaintenance().handleExecute(requests);
	}

	/**
	* Instance entry used by {@link #execute} and by callers that inject a service.
	* @param requests Invocable requests, each with a robot Id.
	* @return One result per request, echoing the robot Id.
	*/
	public List<Result> handleExecute(List<Request> requests) {

		// Collect the robot Ids
		Set<Id> robotIds = new Set<Id>();
		for (Request request : requests) {
			robotIds.add(request.robotId);
		}

		// Schedule the service
		maintenanceSvc.scheduleService(robotIds);

		// Build the results
		List<Result> results = new List<Result>();
		for (Request request : requests) {
			Result result = new Result();
			result.robotId = request.robotId;
			results.add(result);
		}
		return results;
	}

	/**
	* Invocable request for {@link ScheduleMaintenance#execute}.
	*/
	public class Request {
		/**
		* Id of the robot to take into service.
		*/
		@InvocableVariable(label='Robot Id' required=true)
		public Id robotId;
	}

	/**
	* Invocable result for {@link ScheduleMaintenance#execute}.
	*/
	public class Result {
		/**
		* Id of the robot that was scheduled for service.
		*/
		@InvocableVariable(label='Robot Id')
		public Id robotId;
	}
}
