/**
 * Invocable action that schedules service for robots.
 * Delegates to {@link MaintenanceService}.
 */
public inherited sharing class ScheduleMaintenance {
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
		// Build list of robot ids
		Set<Id> robotIds = new Set<Id>();
		for (Request request : requests) {
			robotIds.add(request.robotId);
		}
		// Call the service to schedule the maintenance
		MaintenanceService.newInstance().scheduleService(robotIds);
		// Build list of results
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
