/**
 * Selector for Robot Model catalog queries. No domain class; this is reference data.
 */
public virtual inherited sharing class RobotModelsSelector extends fflib_SObjectSelector {
	@TestVisible
	private static RobotModelsSelector mock;

	/**
	 * Factory that returns this selector, or {@link #mock} when tests have set one.
	 * @return {@link RobotModelsSelector} instance.
	 */
	public static RobotModelsSelector newInstance() {
		return mock != null ? mock : new RobotModelsSelector();
	}

	/**
	 * Constructs a user-mode robot model selector.
	 */
	public RobotModelsSelector() {
		super(false, fflib_SObjectSelector.DataAccess.USER_MODE);
	}

	/**
	 * Common robot model fields used by this selector.
	 * @return Field list for the query factory.
	 */
	public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField>{
			RobotModel__c.Id,
			RobotModel__c.Name,
			RobotModel__c.MaxLoadKg__c,
			RobotModel__c.ServiceIntervalHours__c,
			RobotModel__c.PerformanceFactor__c
		};
	}

	/**
	 * SObject type this selector queries.
	 * @return {@link RobotModel__c} SObject type.
	 */
	public Schema.SObjectType getSObjectType() {
		return RobotModel__c.SObjectType;
	}

	/**
	 * Robot models by Id.
	 * @param idSet Robot Model Ids to query. Empty set returns an empty list.
	 * @return Matching models.
	 */
	public virtual List<RobotModel__c> selectById(Set<Id> idSet) {
		return (List<RobotModel__c>) selectSObjectsById(idSet);
	}

	/**
	 * Robot models by Name, for creating robots from the desk.
	 * @param names Model names. Empty set returns an empty list.
	 * @return Matching models.
	 */
	public virtual List<RobotModel__c> selectByName(Set<String> names) {
		if (names == null || names.isEmpty()) {
			return new List<RobotModel__c>();
		}
		return (List<RobotModel__c>) Database.query(
			newQueryFactory().setCondition('Name IN :names').toSOQL()
		);
	}
}
