/**
 * Invocable action that completes assigned fulfillment lines.
 * Delegates to {@link FulfillmentService}.
 *
 * Prefer the no-arg constructor / {@link #execute} for the default service.
 * Use the service constructor when composing deliberately (including tests).
 */
public inherited sharing class CompleteFulfillmentLines {
	private final FulfillmentService fulfillmentSvc;

	/**
	* Default composition: {@link FulfillmentService#newInstance}.
	*/
	public CompleteFulfillmentLines() {
		this(FulfillmentService.newInstance());
	}

	/**
	* Creates an action with the given service.
	* @param fulfillmentSvc Fulfillment service. Cannot be null.
	*/
	public CompleteFulfillmentLines(FulfillmentService fulfillmentSvc) {
		this.fulfillmentSvc = fulfillmentSvc;
	}

	/**
	* Completes assigned fulfillment lines through {@link FulfillmentService}.
	* @param requests Invocable requests, each with a fulfillment line Id.
	* @return One result per request, echoing the line Id.
	*/
	@InvocableMethod(
		label='Complete Fulfillment Lines'
		description='Completes assigned lines, returns robots, applies wear, and may schedule maintenance.'
		category='Warehouse Operations'
	)
	public static List<Result> execute(List<Request> requests) {
		return new CompleteFulfillmentLines().handleExecute(requests);
	}

	/**
	* Instance entry used by {@link #execute} and by callers that inject a service.
	* @param requests Invocable requests, each with a fulfillment line Id.
	* @return One result per request, echoing the line Id.
	*/
	public List<Result> handleExecute(List<Request> requests) {

		// Collect the line Ids
		Set<Id> lineIds = new Set<Id>();
		for (Request request : requests) {
			lineIds.add(request.lineId);
		}

		// Complete the lines
		fulfillmentSvc.completeLines(lineIds);

		// Build the results
		List<Result> results = new List<Result>();
		for (Request request : requests) {
			Result result = new Result();
			result.lineId = request.lineId;
			results.add(result);
		}
		return results;
	}

	/**
	* Invocable request for {@link CompleteFulfillmentLines#execute}.
	*/
	public class Request {
		/**
		* Id of the fulfillment line to complete.
		*/
		@InvocableVariable(label='Fulfillment Line Id' required=true)
		public Id lineId;
	}

	/**
	* Invocable result for {@link CompleteFulfillmentLines#execute}.
	*/
	public class Result {
		/**
		* Id of the fulfillment line that was completed.
		*/
		@InvocableVariable(label='Fulfillment Line Id')
		public Id lineId;
	}
}
