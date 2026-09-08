/**
 * Controller for the Dispatch Warehouse Lightning action.
 * Delegates to {@link DispatchService}.
 *
 * Prefer the no-arg constructor / {@link #dispatchWarehouse} for the default service.
 * Use the service constructor when composing deliberately (including tests).
 */
public inherited sharing class WarehouseDispatchController {
	private final DispatchService dispatchSvc;

	/**
	* Default composition: {@link DispatchService#newInstance}.
	*/
	public WarehouseDispatchController() {
		this(DispatchService.newInstance());
	}

	/**
	* Creates a controller with the given service.
	* @param dispatchSvc Dispatch service. Cannot be null.
	*/
	public WarehouseDispatchController(DispatchService dispatchSvc) {
		this.dispatchSvc = dispatchSvc;
	}

	/**
	* Dispatches idle robots at a warehouse through {@link DispatchService}.
	* @param warehouseId Warehouse Id. Cannot be null.
	* @throws AuraHandledException when the service throws.
	*/
	@AuraEnabled(cacheable=false)
	public static void dispatchWarehouse(Id warehouseId) {
		new WarehouseDispatchController().handleDispatchWarehouse(warehouseId);
	}

	/**
	* Instance entry used by {@link #dispatchWarehouse} and by callers that inject a service.
	* @param warehouseId Warehouse Id. Cannot be null.
	* @throws AuraHandledException when the service throws.
	*/
	public void handleDispatchWarehouse(Id warehouseId) {
		try {
			dispatchSvc.dispatchWarehouses(new Set<Id>{ warehouseId });
		} catch (Exception e) {
			throw toAura(e);
		}
	}

	private static AuraHandledException toAura(Exception e) {
		AuraHandledException auraException = new AuraHandledException(e.getMessage());
		auraException.setMessage(e.getMessage());
		return auraException;
	}
}
