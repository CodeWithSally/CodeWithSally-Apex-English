/**
 * Invocable action that describes pending work at a warehouse.
 * Delegates to {@link WarehouseService}. Accepts a warehouse name.
 */
public inherited sharing class GetWarehouseDesk {
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
		// Build list of warehouse names
		List<String> warehouseNames = new List<String>();
		for (Request request : requests) {
			warehouseNames.add(request.warehouseName);
		}
		// Call the service for the desk snapshot
		List<WarehouseService.Summary> summaries = WarehouseService.newInstance().summaries(warehouseNames);
		// Build list of results
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
