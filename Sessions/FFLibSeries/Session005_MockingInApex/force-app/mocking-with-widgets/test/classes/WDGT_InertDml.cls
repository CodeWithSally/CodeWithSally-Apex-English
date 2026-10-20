/**
 * DML-inert {@link fflib_SObjectUnitOfWork.IDML} for unit tests. Keeps the records a Unit of Work
 * would have saved, instead of saving them, so tests can check what our logic registered without DML.
 *
 * Inject it where the code under test gets its Unit of Work, then commit as usual:
 * {@code WDGT_UnitOfWork.mock = new fflib_SObjectUnitOfWork(types, inertDml);}
 *
 * Inserted records get fake Ids, as a real insert would give real ones, so relationships registered with
 * {@code registerRelationship} resolve: the Unit of Work copies each parent's Id onto its children just before
 * inserting them. The lists keep commit order across SObject types; the {@code get*} methods filter one type.
 */
@IsTest
public class WDGT_InertDml implements fflib_SObjectUnitOfWork.IDML, fflib_SObjectUnitOfWork.IDMLUpsertable {
	/** Records the Unit of Work would have inserted, in commit order. */
	public List<SObject> inserted = new List<SObject>();
	/** Records the Unit of Work would have updated, in commit order. */
	public List<SObject> updated = new List<SObject>();
	/** Records the Unit of Work would have upserted, in commit order. */
	public List<SObject> upserted = new List<SObject>();
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
		assignFakeIds(objList);
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
	* Keeps records instead of upserting them.
	* @param objList Records to upsert.
	* @param externalId External Id field the upsert would match on.
	*/
	public void dmlUpsert(List<SObject> objList, Schema.SObjectField externalId) {
		assignFakeIds(objList);
		upserted.addAll(objList);
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

	/**
	* Records the Unit of Work would have inserted, of one SObject type.
	* @param sObjectType Type to keep.
	* @return Matching records, in commit order.
	*/
	public List<SObject> getInserted(Schema.SObjectType sObjectType) {
		return ofType(inserted, sObjectType);
	}

	/**
	* Records the Unit of Work would have updated, of one SObject type.
	* @param sObjectType Type to keep.
	* @return Matching records, in commit order.
	*/
	public List<SObject> getUpdated(Schema.SObjectType sObjectType) {
		return ofType(updated, sObjectType);
	}

	/**
	* Records the Unit of Work would have upserted, of one SObject type.
	* @param sObjectType Type to keep.
	* @return Matching records, in commit order.
	*/
	public List<SObject> getUpserted(Schema.SObjectType sObjectType) {
		return ofType(upserted, sObjectType);
	}

	/**
	* Records the Unit of Work would have deleted, of one SObject type.
	* @param sObjectType Type to keep.
	* @return Matching records, in commit order.
	*/
	public List<SObject> getDeleted(Schema.SObjectType sObjectType) {
		return ofType(deleted, sObjectType);
	}

	private static void assignFakeIds(List<SObject> objList) {
		for (SObject record : objList) {
			if (record != null && record.Id == null) {
				record.Id = fflib_IDGenerator.generate(record.getSObjectType());
			}
		}
	}

	private static List<SObject> ofType(List<SObject> records, Schema.SObjectType sObjectType) {
		List<SObject> matching = new List<SObject>();
		for (SObject record : records) {
			if (record.getSObjectType() == sObjectType) {
				matching.add(record);
			}
		}
		return matching;
	}
}
