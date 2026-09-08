/**
 * Invocable action that describes pending work at a warehouse.
 * Delegates to {@link WarehouseService}. Accepts a warehouse name.
 *
 * Prefer the no-arg constructor / {@link #execute} for the default service.
 * Use the service constructor when composing deliberately (including tests).
 */
public inherited sharing class GetWarehouseDesk {
	private final WarehouseService warehouseSvc;

	/**
	* Default composition: {@link WarehouseService#newInstance}.
	*/
	public GetWarehouseDesk() {
		this(WarehouseService.newInstance());
	}

	/**
	* Creates an action with the given service.
	* @param warehouseSvc Warehouse desk service. Cannot be null.
	*/
	public GetWarehouseDesk(WarehouseService warehouseSvc) {
		this.warehouseSvc = warehouseSvc;
	}

	/**
	* Describes pending work at a warehouse through {@link WarehouseService}.
	* @param requests Invocable requests, each with a warehouse name.
	* @return One result per request.
	*/
	@InvocableMethod(
		label='Get Warehouse Desk'
		description='Looks up a warehouse by name and returns pending line count, idle robots, and draft order names.'
		category='Warehouse Operations'
	)
	public static List<Result> execute(List<Request> requests) {
		return new GetWarehouseDesk().handleExecute(requests);
	}

	/**
	* Instance entry used by {@link #execute} and by callers that inject a service.
	* @param requests Invocable requests, each with a warehouse name.
	* @return One result per request.
	*/
	public List<Result> handleExecute(List<Request> requests) {

		// Collect the warehouse names
		List<String> warehouseNames = new List<String>();
		for (Request request : requests) {
			warehouseNames.add(request.warehouseName.trim());
		}

		// Get the desk summaries
		List<WarehouseService.Summary> summaries = warehouseSvc.summaries(warehouseNames);

		// Build the results
		List<Result> results = new List<Result>();
		for (WarehouseService.Summary summary : summaries) {
			Result result = new Result();
			result.warehouseName = summary.warehouseName;
			result.warehouseId = summary.warehouseId;
			result.pendingUnassignedLines = summary.pendingUnassignedLines;
			result.idleAvailableRobots = summary.idleAvailableRobots;
			result.robotShortfall = summary.robotShortfall;
			result.draftOrderNames = summary.draftOrderNames;
			results.add(result);
		}
		return results;
	}

	/**
	* Invocable request for {@link GetWarehouseDesk#execute}.
	*/
	public class Request {
		@InvocableVariable(label='Warehouse Name')
		public String warehouseName;
	}

	/**
	* Invocable result for {@link GetWarehouseDesk#execute}.
	*/
	public class Result {
		@InvocableVariable(label='Warehouse Name')
		public String warehouseName;
		@InvocableVariable(label='Warehouse Id')
		public Id warehouseId;
		@InvocableVariable(label='Pending Unassigned Lines')
		public Integer pendingUnassignedLines;
		@InvocableVariable(label='Idle Available Robots')
		public Integer idleAvailableRobots;
		@InvocableVariable(label='Robot Shortfall')
		public Integer robotShortfall;
		@InvocableVariable(label='Draft Order Names')
		public String draftOrderNames;
	}
}
