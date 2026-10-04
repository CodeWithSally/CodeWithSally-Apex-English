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
	* Robot selector for {@link #handleGetRobotPage}. Tests may replace it with a stub.
	*/
	@TestVisible
	private RobotsSelector robotSelector = RobotsSelector.newInstance();

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

	/**
	* One page of the robots at a warehouse, for the desk's robot list.
	* @param warehouseId Warehouse Id. Cannot be null.
	* @param startIndex Zero-based position of the first robot on the page.
	* @param pageSize Number of robots per page.
	* @return The page, with the total robot count and the next page's start index.
	* @throws AuraHandledException when the query throws.
	*/
	@AuraEnabled(cacheable=false)
	public static RobotPage getRobotPage(Id warehouseId, Integer startIndex, Integer pageSize) {
		return new WarehouseDispatchController().handleGetRobotPage(warehouseId, startIndex, pageSize);
	}

	/**
	* Instance entry used by {@link #getRobotPage} and by tests that stub the selector.
	* @param warehouseId Warehouse Id. Cannot be null.
	* @param startIndex Zero-based position of the first robot on the page.
	* @param pageSize Number of robots per page.
	* @return The page, with the total robot count and the next page's start index.
	* @throws AuraHandledException when the query throws.
	*/
	public RobotPage handleGetRobotPage(Id warehouseId, Integer startIndex, Integer pageSize) {
		try {
			Database.PaginationCursor cursor = robotSelector.selectByWarehouseAsPaginationCursor(
				new Set<Id>{ warehouseId }
			);
			RobotPage page = new RobotPage();
			page.totalRobots = cursor.getNumRecords();
			page.robots = new List<Robot__c>();
			// fetchPage throws when the page runs past the last record, so trim the last page
			Integer robotsOnPage = Math.min(pageSize, page.totalRobots - startIndex);
			if (robotsOnPage > 0) {
				page.robots = (List<Robot__c>) cursor.fetchPage(startIndex, robotsOnPage).getRecords();
			}
			// getNextIndex() returns 0 after the last page, so count from the start index instead
			page.nextIndex = Math.max(startIndex, 0) + page.robots.size();
			return page;
		} catch (Exception e) {
			throw toAura(e);
		}
	}

	/**
	* One page of robots for {@link #getRobotPage}.
	*/
	public class RobotPage {
		/** Robots on this page. */
		@AuraEnabled
		public List<Robot__c> robots;
		/** Robots at the warehouse across all pages. */
		@AuraEnabled
		public Integer totalRobots;
		/** Start index of the next page; equals totalRobots after the last page. */
		@AuraEnabled
		public Integer nextIndex;
	}

	private static AuraHandledException toAura(Exception e) {
		AuraHandledException auraException = new AuraHandledException(e.getMessage());
		auraException.setMessage(e.getMessage());
		return auraException;
	}
}
