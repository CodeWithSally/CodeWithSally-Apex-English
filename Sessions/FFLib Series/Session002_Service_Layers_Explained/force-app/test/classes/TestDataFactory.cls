/**
 * Shared warehouse fixtures for integration tests.
 */
@IsTest
public class TestDataFactory {
	private static final String RUN_AS_USER_LASTNAME = 'WarehouseOps';

	/** Warehouse inserted by {@link #createDraftOrder}. */
	public Warehouse__c warehouse;
	/** Robot model inserted by {@link #createDraftOrder}. */
	public RobotModel__c model;
	/** Idle robot inserted by {@link #createDraftOrder}. */
	public Robot__c robot;
	/** Draft fulfillment order inserted by {@link #createDraftOrder}. */
	public FulfillmentOrder__c order;
	/** Pending fulfillment line inserted by {@link #createDraftOrder}. */
	public FulfillmentLine__c line;

	/**
	 * Inserts a warehouse, model, idle robot, draft order, and one pending line.
	 * @return Populated factory.
	 */
	public static TestDataFactory createDraftOrder() {
		return createDraftOrder(0, 8);
	}

	/**
	 * Inserts a warehouse, model, idle robot, draft order, and one pending line.
	 * @param hoursSinceService Starting hours on the robot.
	 * @param serviceIntervalHours Model service interval.
	 * @return Populated factory.
	 */
	public static TestDataFactory createDraftOrder(Decimal hoursSinceService, Decimal serviceIntervalHours) {
		TestDataFactory data = new TestDataFactory();
		data.warehouse = new Warehouse__c(
			Name = 'North Hub',
			Status__c = Warehouses.STATUS_ACTIVE,
			Location__c = 'North'
		);
		insert data.warehouse;

		data.model = new RobotModel__c(
			Name = 'Picker 100',
			MaxLoadKg__c = 50,
			ServiceIntervalHours__c = serviceIntervalHours,
			PerformanceFactor__c = 1
		);
		insert data.model;

		data.robot = new Robot__c(
			Name = 'Atlas',
			Warehouse__c = data.warehouse.Id,
			Model__c = data.model.Id,
			Status__c = Robots.STATUS_IDLE,
			Health__c = Robots.HEALTH_HEALTHY,
			WearPercent__c = 0,
			HoursSinceService__c = hoursSinceService,
			BatteryLevel__c = 100
		);
		insert data.robot;

		data.order = new FulfillmentOrder__c(
			Warehouse__c = data.warehouse.Id,
			Status__c = FulfillmentOrders.STATUS_DRAFT,
			Priority__c = 'Normal',
			DueDate__c = Date.today().addDays(2)
		);
		insert data.order;

		data.line = new FulfillmentLine__c(
			FulfillmentOrder__c = data.order.Id,
			Status__c = FulfillmentLines.STATUS_PENDING,
			ProductSku__c = 'SKU-1',
			Quantity__c = 10,
			WeightKg__c = 10
		);
		insert data.line;
		return data;
	}

	/**
	 * Inserts a Standard User and assigns Warehouse Operations.
	 * @return The inserted User ready for System.runAs.
	 */
	public static User createUserWithWarehousePermissions() {
		Profile p = [
			SELECT Id
			FROM Profile
			WHERE Name = 'Standard User' AND UserLicense.Name = 'Salesforce'
			LIMIT 1
		];
		String uniqueName = 'whops_' + DateTime.now().getTime() + '@test.org';
		User u = new User(
			Alias = 'whops',
			Email = 'whops@test.org',
			EmailEncodingKey = 'UTF-8',
			LastName = RUN_AS_USER_LASTNAME,
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			ProfileId = p.Id,
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = uniqueName
		);
		insert u;
		PermissionSet ps = [
			SELECT Id
			FROM PermissionSet
			WHERE Name = 'WarehouseOperations'
			LIMIT 1
		];
		insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
		return u;
	}

	/**
	 * @return User previously created by {@link #createUserWithWarehousePermissions}.
	 */
	public static User getRunAsUser() {
		return [SELECT Id FROM User WHERE LastName = :RUN_AS_USER_LASTNAME LIMIT 1];
	}
}
