/**
 * Invocable action that dispatches idle robots onto pending lines at warehouses.
 * Delegates to {@link DispatchService}. Accepts a warehouse name.
 *
 * Prefer the no-arg constructor / {@link #execute} for the default service.
 * Use the service constructor when composing deliberately (including tests).
 */
public inherited sharing class DispatchWarehouse {
	private final DispatchService dispatchSvc;
	private final WarehousesSelector warehouseSelector;

	/**
	* Default composition: {@link DispatchService#newInstance} and {@link WarehousesSelector#newInstance}.
	*/
	public DispatchWarehouse() {
		this(DispatchService.newInstance(), WarehousesSelector.newInstance());
	}

	/**
	* Creates an action with the given service and selector.
	* @param dispatchSvc Dispatch service. Cannot be null.
	* @param warehouseSelector Warehouse selector used to resolve names. Cannot be null.
	*/
	public DispatchWarehouse(DispatchService dispatchSvc, WarehousesSelector warehouseSelector) {
		this.dispatchSvc = dispatchSvc;
		this.warehouseSelector = warehouseSelector;
	}

	/**
	* Dispatches idle robots at the given warehouses through {@link DispatchService}.
	* @param requests Invocable requests, each with a warehouse name.
	* @return One result per request, with the warehouse name and resolved Id.
	*/
	@InvocableMethod(
		label='Dispatch Warehouse'
		description='Assigns idle healthy robots to pending fulfillment lines at the given warehouses. Pass a warehouse name such as North Hub.'
		category='Warehouse Operations'
	)
	public static List<Result> execute(List<Request> requests) {
		return new DispatchWarehouse().handleExecute(requests);
	}

	/**
	* Instance entry used by {@link #execute} and by callers that inject collaborators.
	* @param requests Invocable requests, each with a warehouse name.
	* @return One result per request, with the warehouse name and resolved Id.
	*/
	public List<Result> handleExecute(List<Request> requests) {

		// Resolve the warehouse names to Ids
		Set<String> names = new Set<String>();
		for (Request request : requests) {
			names.add(request.warehouseName.trim());
		}
		Map<String, Warehouse__c> warehouses = warehouseSelector.selectByName(names);
		for (String name : names) {
			if (!warehouses.containsKey(name)) {
				throw new DispatchWarehouseException('No warehouse named ' + name + '.');
			}
		}

		// Dispatch the warehouses
		dispatchSvc.dispatchWarehouses(new Map<Id, Warehouse__c>(warehouses.values()).keySet());

		// Build the results
		List<Result> results = new List<Result>();
		for (Request request : requests) {
			Result result = new Result();
			result.warehouseName = request.warehouseName.trim();
			result.warehouseId = warehouses.get(result.warehouseName).Id;
			results.add(result);
		}
		return results;
	}

	/**
	* Invocable request for {@link DispatchWarehouse#execute}.
	*/
	public class Request {
		/**
		* Warehouse name, for example North Hub.
		*/
		@InvocableVariable(label='Warehouse Name' required=true)
		public String warehouseName;
	}

	/**
	* Invocable result for {@link DispatchWarehouse#execute}.
	*/
	public class Result {
		@InvocableVariable(label='Warehouse Name')
		public String warehouseName;
		@InvocableVariable(label='Warehouse Id')
		public Id warehouseId;
	}

	/**
	* Thrown when the warehouse cannot be resolved.
	*/
	public class DispatchWarehouseException extends Exception {
	}
}
