/**
 * Abstract chargeable work-item domain that derives cost as hours worked times 100.
 * Concrete subclasses supply the cost field and hour calculation for their SObject type.
 */
public abstract inherited sharing class AbstractChargeable {
	/**
	 * Work-item records managed by this domain instance; never null after construction.
	 */
	protected List<SObject> records;

	/**
	 * Creates a domain wrapping the given records.
	 * @param records Work-item records to manage. Null is treated as an empty list.
	 */
	public AbstractChargeable(List<SObject> records) {
		this.records = records == null ? new List<SObject>() : records;
	}

	/**
	 * Returns the records held by this domain instance.
	 * @return The in-memory SObject list; never null.
	 */
	public List<SObject> getRecords() {
		return records;
	}

	/**
	 * Returns the SObject field that stores the calculated cost of hours worked.
	 * @return Schema field token for the cost field on the concrete work-item type.
	 */
	public abstract Schema.SObjectField getCostOfHoursWorkedField();

	/**
	 * Calculates hours worked for each record in domain order.
	 * @return Hours worked per record; size matches {@link #getRecords()}.
	 */
	public abstract List<Integer> calculateHoursWorked();

	/**
	 * Before-insert hook that recalculates cost of hours worked on all records.
	 */
	public virtual void onBeforeInsert() {
		updateCostOfHoursWorked();
	}

	/**
	 * Before-update hook that recalculates cost of hours worked on all records.
	 * @param existingRecords Prior versions of the records keyed by Id. May be unused by the base implementation.
	 */
	public virtual void onBeforeUpdate(Map<Id, SObject> existingRecords) {
		updateCostOfHoursWorked();
	}

	/**
	 * Sets each record's cost field to hours worked times 100 using
	 * {@link #calculateHoursWorked()} and {@link #getCostOfHoursWorkedField()}.
	 */
	public virtual void updateCostOfHoursWorked() {
		List<Integer> hoursWorked = calculateHoursWorked();
		Schema.SObjectField costOfHoursWorkedField = getCostOfHoursWorkedField();
		Integer hoursWorkedRecordIdx = 0;
		for (SObject record : records) {
			record.put(costOfHoursWorkedField, hoursWorked[hoursWorkedRecordIdx++] * 100);
		}
	}
}
