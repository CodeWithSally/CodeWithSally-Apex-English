/**
 * Controller for the Dispatch Warehouse Lightning action.
 * Delegates to {@link DispatchService}.
 */
public inherited sharing class WarehouseDispatchController {
	/**
	 * Dispatches idle robots at a warehouse through {@link DispatchService}.
	 * @param warehouseId Warehouse Id. Cannot be null.
	 * @throws AuraHandledException when the service throws.
	 */
	@AuraEnabled(cacheable=false)
	public static void dispatchWarehouse(Id warehouseId) {
		try {
			DispatchService.newInstance().dispatchWarehouses(new Set<Id>{ warehouseId });
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
