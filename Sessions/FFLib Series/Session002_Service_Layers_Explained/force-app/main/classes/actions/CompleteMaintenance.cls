/**
 * Invocable action that completes maintenance jobs and restores robots.
 * Delegates to {@link MaintenanceService}.
 */
public inherited sharing class CompleteMaintenance {
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
		// Build list of job ids
		Set<Id> jobIds = new Set<Id>();
		for (Request request : requests) {
			jobIds.add(request.jobId);
		}
		// Call the service to complete the jobs
		MaintenanceService.newInstance().completeJobs(jobIds);
		// Build list of results
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
