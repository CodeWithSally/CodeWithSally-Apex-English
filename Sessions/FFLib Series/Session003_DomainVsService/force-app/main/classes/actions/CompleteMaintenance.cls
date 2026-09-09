/**
 * Invocable action that completes maintenance jobs and restores robots.
 * Delegates to {@link MaintenanceService}.
 *
 * Prefer the no-arg constructor / {@link #execute} for the default service.
 * Use the service constructor when composing deliberately (including tests).
 */
public inherited sharing class CompleteMaintenance {
	private final MaintenanceService maintenanceSvc;

	/**
	* Default composition: {@link MaintenanceService#newInstance}.
	*/
	public CompleteMaintenance() {
		this(MaintenanceService.newInstance());
	}

	/**
	* Creates an action with the given service.
	* @param maintenanceSvc Maintenance service. Cannot be null.
	*/
	public CompleteMaintenance(MaintenanceService maintenanceSvc) {
		this.maintenanceSvc = maintenanceSvc;
	}

	/**
	* Completes in-progress maintenance jobs through {@link MaintenanceService}.
	* @param requests Invocable requests, each with a maintenance job Id.
	* @return One result per request, echoing the job Id.
	*/
	@InvocableMethod(
		label='Complete Maintenance'
		description='Completes in-progress maintenance jobs and returns robots to idle.'
		category='Warehouse Operations'
	)
	public static List<Result> execute(List<Request> requests) {
		return new CompleteMaintenance().handleExecute(requests);
	}

	/**
	* Instance entry used by {@link #execute} and by callers that inject a service.
	* @param requests Invocable requests, each with a maintenance job Id.
	* @return One result per request, echoing the job Id.
	*/
	public List<Result> handleExecute(List<Request> requests) {

		// Collect the job Ids
		Set<Id> jobIds = new Set<Id>();
		for (Request request : requests) {
			jobIds.add(request.jobId);
		}

		// Complete the jobs
		maintenanceSvc.completeJobs(jobIds);

		// Build the results
		List<Result> results = new List<Result>();
		for (Request request : requests) {
			Result result = new Result();
			result.jobId = request.jobId;
			results.add(result);
		}
		return results;
	}

	/**
	* Invocable request for {@link CompleteMaintenance#execute}.
	*/
	public class Request {
		/**
		* Id of the maintenance job to complete.
		*/
		@InvocableVariable(label='Maintenance Job Id' required=true)
		public Id jobId;
	}

	/**
	* Invocable result for {@link CompleteMaintenance#execute}.
	*/
	public class Result {
		/**
		* Id of the maintenance job that was completed.
		*/
		@InvocableVariable(label='Maintenance Job Id')
		public Id jobId;
	}
}
