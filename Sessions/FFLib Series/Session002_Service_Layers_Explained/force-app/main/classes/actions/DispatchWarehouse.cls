/**
 * Invocable action that dispatches idle robots onto pending lines at warehouses.
 * Delegates to {@link DispatchService}. Accepts a warehouse name or Id.
 */
public inherited sharing class DispatchWarehouse {
	/**
	 * Dispatches idle robots at the given warehouses through {@link DispatchService}.
	 * @param requests Invocable requests, each with a warehouse name or Id.
	 * @return One result per request, echoing the warehouse that was dispatched.
	 */
	@InvocableMethod(
		label='Dispatch Warehouse'
		description='Assigns idle healthy robots to pending fulfillment lines at the given warehouses. Pass a warehouse name such as North Hub.'
		category='Warehouse Operations'
	)
	public static List<Result> execute(List<Request> requests) {
		// Resolve names to Ids when the caller did not pass Ids
		Map<String, Warehouse__c> warehouseByName = warehousesByName(requests);
		List<Id> resolvedIds = new List<Id>();
		for (Request request : requests) {
			resolvedIds.add(resolveWarehouseId(request, warehouseByName));
		}

		DispatchService.newInstance().dispatchWarehouses(new Set<Id>(resolvedIds));

		List<Result> results = new List<Result>();
		for (Integer i = 0; i < requests.size(); i++) {
			Result result = new Result();
			result.warehouseId = resolvedIds[i];
			result.warehouseName = requests[i].warehouseName;
			if (String.isNotBlank(requests[i].warehouseName)) {
				Warehouse__c warehouse = warehouseByName.get(requests[i].warehouseName.trim());
				if (warehouse != null) {
					result.warehouseName = warehouse.Name;
				}
			}
			results.add(result);
		}
		return results;
	}

	private static Map<String, Warehouse__c> warehousesByName(List<Request> requests) {
		Set<String> names = new Set<String>();
		for (Request request : requests) {
			if (request.warehouseId == null && String.isNotBlank(request.warehouseName)) {
				names.add(request.warehouseName.trim());
			}
		}
		return WarehousesSelector.newInstance().selectByName(names);
	}

	private static Id resolveWarehouseId(Request request, Map<String, Warehouse__c> warehouseByName) {
		if (request.warehouseId != null) {
			return request.warehouseId;
		}
		if (String.isBlank(request.warehouseName)) {
			throw new DispatchWarehouseException('Give a warehouse name, for example North Hub.');
		}
		Warehouse__c warehouse = warehouseByName.get(request.warehouseName.trim());
		if (warehouse == null) {
			throw new DispatchWarehouseException('No warehouse named ' + request.warehouseName.trim() + '.');
		}
		return warehouse.Id;
	}

	/**
	 * Invocable request for {@link DispatchWarehouse#execute}.
	 */
	public class Request {
		/**
		 * Warehouse name, for example North Hub.
		 */
		@InvocableVariable(label='Warehouse Name')
		public String warehouseName;

		/**
		 * Id of the warehouse to dispatch when the name is not used.
		 */
		@InvocableVariable(label='Warehouse Id')
		public Id warehouseId;
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
