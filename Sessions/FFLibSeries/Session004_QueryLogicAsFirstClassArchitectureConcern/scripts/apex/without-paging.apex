// Without paging: one list query loads every robot at the warehouse into memory at once.
// Fine for the sample's three robots. At tens of thousands, one request holds them all,
// and the 50,000-row query limit is the ceiling. Compare with with-paging.apex.
// The query is inline here only for the comparison.

Id warehouseId = WarehousesSelector.newInstance()
	.selectByName(new Set<String>{ 'North Hub' })
	.get('North Hub')
	.Id;

List<Robot__c> robots = [
	SELECT Id, Name
	FROM Robot__c
	WHERE Warehouse__c = :warehouseId
	WITH USER_MODE
	ORDER BY Name, Id
];

List<String> names = new List<String>();
for (Robot__c robot : robots) {
	names.add(robot.Name);
}
System.debug('All robots at North Hub in one go: ' + String.join(names, ', '));
System.debug('Rows held at once: ' + robots.size()
	+ ' | query rows used: ' + Limits.getQueryRows() + ' of ' + Limits.getLimitQueryRows());
