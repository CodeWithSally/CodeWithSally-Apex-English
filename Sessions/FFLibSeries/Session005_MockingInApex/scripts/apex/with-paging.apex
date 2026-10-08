// With paging: RobotsSelector.selectByWarehouseAsPaginationCursor is the only query.
// This script is the consumer: it pages through North Hub's robots two at a time, as a UI would,
// and works around three PaginationCursor quirks. Compare with without-paging.apex.

final Integer PAGE_SIZE = 2;
Set<Id> warehouseIds = new Set<Id>{
	WarehousesSelector.newInstance().selectByName(new Set<String>{ 'North Hub' }).get('North Hub').Id
};

// Request 1: open the cursor and walk every page
Database.PaginationCursor cursor = RobotsSelector.newInstance().selectByWarehouseAsPaginationCursor(warehouseIds);
Integer total = cursor.getNumRecords();
System.debug('Robots at North Hub: ' + total + ', in pages of ' + PAGE_SIZE);

Integer startIndex = 0;
Integer pageNumber = 1;
while (startIndex < total) {
	// Quirk 1: fetchPage throws "Fetch beyond bound" past the last record, so trim the last page
	Integer size = Math.min(PAGE_SIZE, total - startIndex);
	Database.CursorFetchResult page = cursor.fetchPage(startIndex, size);
	List<String> names = new List<String>();
	for (Robot__c robot : (List<Robot__c>) page.getRecords()) {
		names.add(robot.Name);
	}
	// Quirk 2: getNextIndex() returns 0 after the last page. Quirk 3: isDone() is true after every page.
	// So count the next start from this page's records instead.
	Integer nextStart = startIndex + names.size();
	System.debug('Page ' + pageNumber + ' (rows ' + startIndex + '–' + (nextStart - 1) + '): ' + String.join(names, ', ')
		+ ' | getNextIndex() = ' + page.getNextIndex() + ', isDone() = ' + page.isDone()
		+ ', next start = ' + nextStart);
	startIndex = nextStart;
	pageNumber++;
}

// Request 2: later, the UI asks for page 2 again. Each request opens a fresh cursor, so the query runs again.
// The Name, Id order makes the pages line up across cursors, even when two robots share a name.
Database.PaginationCursor later = RobotsSelector.newInstance().selectByWarehouseAsPaginationCursor(warehouseIds);
Integer laterStart = Math.min(PAGE_SIZE, later.getNumRecords());
Integer laterSize = Math.min(PAGE_SIZE, later.getNumRecords() - laterStart);
if (laterSize > 0) {
	List<String> names = new List<String>();
	for (Robot__c robot : (List<Robot__c>) later.fetchPage(laterStart, laterSize).getRecords()) {
		names.add(robot.Name);
	}
	System.debug('Page 2 again, on a fresh cursor: ' + String.join(names, ', '));
}

System.debug('Rows held per page: at most ' + PAGE_SIZE + ', however many robots the warehouse has');
