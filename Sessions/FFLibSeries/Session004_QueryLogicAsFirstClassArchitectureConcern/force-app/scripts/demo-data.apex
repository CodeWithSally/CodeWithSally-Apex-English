// Warehouse Operations fixtures. Idempotent: keeps North Hub, Picker 100,
// Atlas / Bolt / Ember, and the original High ticket (SKU-LIGHT / SKU-MED / SKU-HEAVY).
// Extra WAVE2 draft orders make one dispatch short of robots (11 pending lines, 3 idle).

class WarehouseDemoSeed {
	final String WAREHOUSE_NAME = 'North Hub';
	final String MODEL_NAME = 'Picker 100';
	final Set<String> TEACHING_ROBOT_NAMES = new Set<String>{ 'Atlas', 'Bolt', 'Ember' };
	final Set<String> TEACHING_SKUS = new Set<String>{ 'SKU-LIGHT', 'SKU-MED', 'SKU-HEAVY' };
	final String EXTRA_SKU_PREFIX = 'SKU-WAVE2-';

	void run() {
		Warehouse__c warehouse = upsertWarehouse();
		RobotModel__c picker = upsertModel();
		resetNorthHubWork(warehouse.Id);
		upsertTeachingRobots(warehouse.Id, picker.Id);
		FulfillmentOrder__c teachingOrder = upsertTeachingOrder(warehouse.Id);
		insertExtraDraftOrders(warehouse.Id);

		Integer pendingLines = [
			SELECT COUNT()
			FROM FulfillmentLine__c
			WHERE FulfillmentOrder__r.Warehouse__c = :warehouse.Id
			AND Status__c = 'Pending'
			AND AssignedRobot__c = null
		];
		Integer idleRobots = [
			SELECT COUNT()
			FROM Robot__c
			WHERE Warehouse__c = :warehouse.Id
			AND Status__c = 'Idle'
		];
		System.debug(
			'North Hub ready. Warehouse Id=' +
				warehouse.Id +
				' teachingOrder=' +
				teachingOrder.Name +
				' pendingLines=' +
				pendingLines +
				' idleRobots=' +
				idleRobots
		);
	}

	Warehouse__c upsertWarehouse() {
		List<Warehouse__c> existing = [
			SELECT Id, Name, Status__c, Location__c
			FROM Warehouse__c
			WHERE Name = :WAREHOUSE_NAME
			LIMIT 1
		];
		Warehouse__c warehouse = existing.isEmpty() ? new Warehouse__c(Name = WAREHOUSE_NAME) : existing[0];
		warehouse.Status__c = 'Active';
		warehouse.Location__c = 'North';
		upsert warehouse;
		return warehouse;
	}

	RobotModel__c upsertModel() {
		List<RobotModel__c> existing = [
			SELECT Id, Name, MaxLoadKg__c, ServiceIntervalHours__c, PerformanceFactor__c
			FROM RobotModel__c
			WHERE Name = :MODEL_NAME
			LIMIT 1
		];
		RobotModel__c model = existing.isEmpty() ? new RobotModel__c(Name = MODEL_NAME) : existing[0];
		model.MaxLoadKg__c = 50;
		model.ServiceIntervalHours__c = 40;
		model.PerformanceFactor__c = 1;
		upsert model;
		return model;
	}

	void resetNorthHubWork(Id warehouseId) {
		Set<Id> teachingOrderIds = new Set<Id>();
		for (FulfillmentLine__c line : [
			SELECT FulfillmentOrder__c
			FROM FulfillmentLine__c
			WHERE ProductSku__c IN :TEACHING_SKUS
			AND FulfillmentOrder__r.Warehouse__c = :warehouseId
		]) {
			teachingOrderIds.add(line.FulfillmentOrder__c);
		}

		List<FulfillmentLine__c> teachingLines = [
			SELECT Id
			FROM FulfillmentLine__c
			WHERE FulfillmentOrder__c IN :teachingOrderIds
		];
		for (FulfillmentLine__c line : teachingLines) {
			line.AssignedRobot__c = null;
			line.Status__c = 'Pending';
		}
		if (!teachingLines.isEmpty()) {
			update teachingLines;
		}

		List<FulfillmentLine__c> extraLines = [
			SELECT Id, FulfillmentOrder__c
			FROM FulfillmentLine__c
			WHERE FulfillmentOrder__r.Warehouse__c = :warehouseId
			AND FulfillmentOrder__c NOT IN :teachingOrderIds
		];
		Set<Id> extraOrderIds = new Set<Id>();
		for (FulfillmentLine__c line : extraLines) {
			extraOrderIds.add(line.FulfillmentOrder__c);
		}
		for (FulfillmentOrder__c order : [
			SELECT Id
			FROM FulfillmentOrder__c
			WHERE Warehouse__c = :warehouseId
			AND Id NOT IN :teachingOrderIds
		]) {
			extraOrderIds.add(order.Id);
		}
		if (!extraLines.isEmpty()) {
			delete extraLines;
		}
		if (!extraOrderIds.isEmpty()) {
			delete [SELECT Id FROM FulfillmentOrder__c WHERE Id IN :extraOrderIds];
		}

		delete [SELECT Id FROM MaintenanceJob__c WHERE Robot__r.Warehouse__c = :warehouseId];

		List<Robot__c> extras = [
			SELECT Id
			FROM Robot__c
			WHERE Warehouse__c = :warehouseId
			AND Name NOT IN :TEACHING_ROBOT_NAMES
		];
		if (!extras.isEmpty()) {
			delete extras;
		}
	}

	void upsertTeachingRobots(Id warehouseId, Id modelId) {
		Map<String, Robot__c> byName = new Map<String, Robot__c>();
		for (Robot__c robot : [
			SELECT Id, Name
			FROM Robot__c
			WHERE Name IN :TEACHING_ROBOT_NAMES
		]) {
			byName.put(robot.Name, robot);
		}

		List<Robot__c> robots = new List<Robot__c>{
			teachingRobot(byName.get('Atlas'), 'Atlas', warehouseId, modelId, 'Healthy', 10, 4, 92),
			teachingRobot(byName.get('Bolt'), 'Bolt', warehouseId, modelId, 'Warning', 62, 25, 70),
			teachingRobot(byName.get('Ember'), 'Ember', warehouseId, modelId, 'Warning', 79, 39, 55)
		};
		upsert robots;
	}

	Robot__c teachingRobot(
		Robot__c existing,
		String name,
		Id warehouseId,
		Id modelId,
		String health,
		Decimal wear,
		Decimal hours,
		Decimal battery
	) {
		Robot__c robot = existing == null ? new Robot__c(Name = name) : existing;
		robot.Name = name;
		robot.Warehouse__c = warehouseId;
		robot.Model__c = modelId;
		robot.Status__c = 'Idle';
		robot.Health__c = health;
		robot.WearPercent__c = wear;
		robot.HoursSinceService__c = hours;
		robot.BatteryLevel__c = battery;
		return robot;
	}

	FulfillmentOrder__c upsertTeachingOrder(Id warehouseId) {
		List<FulfillmentLine__c> teachingLines = [
			SELECT Id, ProductSku__c, FulfillmentOrder__c
			FROM FulfillmentLine__c
			WHERE ProductSku__c IN :TEACHING_SKUS
			AND FulfillmentOrder__r.Warehouse__c = :warehouseId
		];

		FulfillmentOrder__c order;
		if (teachingLines.isEmpty()) {
			order = new FulfillmentOrder__c(
				Warehouse__c = warehouseId,
				Status__c = 'Draft',
				Priority__c = 'High',
				DueDate__c = Date.today().addDays(1)
			);
			insert order;
			insert new List<FulfillmentLine__c>{
				teachingLine(order.Id, 'SKU-LIGHT', 10, 8),
				teachingLine(order.Id, 'SKU-MED', 20, 18),
				teachingLine(order.Id, 'SKU-HEAVY', 6, 40)
			};
		} else {
			order = new FulfillmentOrder__c(Id = teachingLines[0].FulfillmentOrder__c);
			order.Status__c = 'Draft';
			order.Priority__c = 'High';
			order.DueDate__c = Date.today().addDays(1);
			update order;

			Map<String, FulfillmentLine__c> bySku = new Map<String, FulfillmentLine__c>();
			for (FulfillmentLine__c line : teachingLines) {
				bySku.put(line.ProductSku__c, line);
			}
			upsert new List<FulfillmentLine__c>{
				applyTeachingLine(bySku.get('SKU-LIGHT'), order.Id, 'SKU-LIGHT', 10, 8),
				applyTeachingLine(bySku.get('SKU-MED'), order.Id, 'SKU-MED', 20, 18),
				applyTeachingLine(bySku.get('SKU-HEAVY'), order.Id, 'SKU-HEAVY', 6, 40)
			};
		}

		return [SELECT Id, Name FROM FulfillmentOrder__c WHERE Id = :order.Id];
	}

	FulfillmentLine__c teachingLine(Id orderId, String sku, Decimal quantity, Decimal weightKg) {
		return applyTeachingLine(null, orderId, sku, quantity, weightKg);
	}

	FulfillmentLine__c applyTeachingLine(
		FulfillmentLine__c existing,
		Id orderId,
		String sku,
		Decimal quantity,
		Decimal weightKg
	) {
		FulfillmentLine__c line = existing == null ? new FulfillmentLine__c() : existing;
		if (existing == null) {
			line.FulfillmentOrder__c = orderId;
		}
		line.Status__c = 'Pending';
		line.AssignedRobot__c = null;
		line.ProductSku__c = sku;
		line.Quantity__c = quantity;
		line.WeightKg__c = weightKg;
		return line;
	}

	void insertExtraDraftOrders(Id warehouseId) {
		FulfillmentOrder__c waveA = new FulfillmentOrder__c(
			Warehouse__c = warehouseId,
			Status__c = 'Draft',
			Priority__c = 'Normal',
			DueDate__c = Date.today().addDays(2)
		);
		FulfillmentOrder__c waveB = new FulfillmentOrder__c(
			Warehouse__c = warehouseId,
			Status__c = 'Draft',
			Priority__c = 'Normal',
			DueDate__c = Date.today().addDays(3)
		);
		FulfillmentOrder__c waveC = new FulfillmentOrder__c(
			Warehouse__c = warehouseId,
			Status__c = 'Draft',
			Priority__c = 'High',
			DueDate__c = Date.today().addDays(1)
		);
		insert new List<FulfillmentOrder__c>{ waveA, waveB, waveC };

		insert new List<FulfillmentLine__c>{
			extraLine(waveA.Id, 'SKU-WAVE2-A', 12, 12),
			extraLine(waveA.Id, 'SKU-WAVE2-B', 8, 22),
			extraLine(waveA.Id, 'SKU-WAVE2-C', 4, 35),
			extraLine(waveB.Id, 'SKU-WAVE2-D', 16, 10),
			extraLine(waveB.Id, 'SKU-WAVE2-E', 14, 16),
			extraLine(waveB.Id, 'SKU-WAVE2-F', 5, 30),
			extraLine(waveC.Id, 'SKU-WAVE2-G', 9, 9),
			extraLine(waveC.Id, 'SKU-WAVE2-H', 7, 24)
		};
	}

	FulfillmentLine__c extraLine(Id orderId, String sku, Decimal quantity, Decimal weightKg) {
		return new FulfillmentLine__c(
			FulfillmentOrder__c = orderId,
			Status__c = 'Pending',
			ProductSku__c = sku,
			Quantity__c = quantity,
			WeightKg__c = weightKg
		);
	}
}

new WarehouseDemoSeed().run();
