/**
 * DML-inert {@link fflib_SObjectUnitOfWork.IDML} for unit tests. Keeps the records a Unit of Work
 * would have saved, instead of saving them, so tests can check what our logic registered without DML.
 *
 * Inject it where the code under test builds its Unit of Work, then commit as usual:
 * {@code new fflib_SObjectUnitOfWork(types, inertDml)}.
 */
@IsTest
public class InertDml implements fflib_SObjectUnitOfWork.IDML {
	/** Records the Unit of Work would have inserted, in commit order. */
	public List<SObject> inserted = new List<SObject>();
	/** Records the Unit of Work would have updated, in commit order. */
	public List<SObject> updated = new List<SObject>();
	/** Records the Unit of Work would have deleted, in commit order. */
	public List<SObject> deleted = new List<SObject>();
	/** Platform events the Unit of Work would have published, in commit order. */
	public List<SObject> published = new List<SObject>();
	/** Records the Unit of Work would have removed from the Recycle Bin, in commit order. */
	public List<SObject> emptied = new List<SObject>();

	/**
	* Keeps records instead of inserting them.
	* @param objList Records to insert.
	*/
	public void dmlInsert(List<SObject> objList) {
		inserted.addAll(objList);
	}

	/**
	* Keeps records instead of updating them.
	* @param objList Records to update.
	*/
	public void dmlUpdate(List<SObject> objList) {
		updated.addAll(objList);
	}

	/**
	* Keeps records instead of deleting them.
	* @param objList Records to delete.
	*/
	public void dmlDelete(List<SObject> objList) {
		deleted.addAll(objList);
	}

	/**
	* Keeps platform events instead of publishing them.
	* @param objList Platform events to publish.
	*/
	public void eventPublish(List<SObject> objList) {
		published.addAll(objList);
	}

	/**
	* Keeps records instead of removing them from the Recycle Bin.
	* @param objList Records to remove.
	*/
	public void emptyRecycleBin(List<SObject> objList) {
		emptied.addAll(objList);
	}
}
