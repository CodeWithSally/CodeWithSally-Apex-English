/**
 * Controller for the Schedule Service Lightning action.
 * Delegates to {@link MaintenanceService}.
 */
public inherited sharing class RobotMaintenanceController {
	/**
	 * Schedules maintenance for a robot through {@link MaintenanceService}.
	 * @param robotId Robot Id. Cannot be null.
	 * @throws AuraHandledException when the service throws.
	 */
	@AuraEnabled(cacheable=false)
	public static void scheduleService(Id robotId) {
		try {
			MaintenanceService.newInstance().scheduleService(new Set<Id>{ robotId });
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
