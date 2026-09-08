/**
 * Controller for the Schedule Service Lightning action.
 * Delegates to {@link MaintenanceService}.
 *
 * Prefer the no-arg constructor / {@link #scheduleService} for the default service.
 * Use the service constructor when composing deliberately (including tests).
 */
public inherited sharing class RobotMaintenanceController {
	private final MaintenanceService maintenanceSvc;

	/**
	* Default composition: {@link MaintenanceService#newInstance}.
	*/
	public RobotMaintenanceController() {
		this(MaintenanceService.newInstance());
	}

	/**
	* Creates a controller with the given service.
	* @param maintenanceSvc Maintenance service. Cannot be null.
	*/
	public RobotMaintenanceController(MaintenanceService maintenanceSvc) {
		this.maintenanceSvc = maintenanceSvc;
	}

	/**
	* Schedules maintenance for a robot through {@link MaintenanceService}.
	* @param robotId Robot Id. Cannot be null.
	* @throws AuraHandledException when the service throws.
	*/
	@AuraEnabled(cacheable=false)
	public static void scheduleService(Id robotId) {
		new RobotMaintenanceController().handleScheduleService(robotId);
	}

	/**
	* Instance entry used by {@link #scheduleService} and by callers that inject a service.
	* @param robotId Robot Id. Cannot be null.
	* @throws AuraHandledException when the service throws.
	*/
	public void handleScheduleService(Id robotId) {
		try {
			maintenanceSvc.scheduleService(new Set<Id>{ robotId });
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
