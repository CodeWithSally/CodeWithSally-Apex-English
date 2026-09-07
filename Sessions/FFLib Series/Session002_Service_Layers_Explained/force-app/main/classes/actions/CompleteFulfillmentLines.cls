/**
 * Invocable action that completes assigned fulfillment lines.
 * Delegates to {@link FulfillmentService}.
 */
public inherited sharing class CompleteFulfillmentLines {
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
		// Build list of line ids
		Set<Id> lineIds = new Set<Id>();
		for (Request request : requests) {
			lineIds.add(request.lineId);
		}
		// Call the service to complete the lines
		FulfillmentService.newInstance().completeLines(lineIds);
		// Build list of results
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
