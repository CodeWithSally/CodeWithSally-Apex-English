/**
 * Selector for Maintenance Job queries used by start and complete.
 */
public virtual inherited sharing class MaintenanceJobsSelector extends fflib_SObjectSelector {
	/**
	* Factory that returns this selector.
	* @return {@link MaintenanceJobsSelector} instance.
	*/
	public static MaintenanceJobsSelector newInstance() {
		return new MaintenanceJobsSelector();
	}

	/**
	* Constructs a user-mode maintenance job selector.
	*/
	public MaintenanceJobsSelector() {
		super(false, fflib_SObjectSelector.DataAccess.USER_MODE);
	}

	/**
	* Common maintenance job fields used by this selector.
	* @return Field list for the query factory.
	*/
	public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField>{
			MaintenanceJob__c.Id,
			MaintenanceJob__c.Name,
			MaintenanceJob__c.Robot__c,
			MaintenanceJob__c.Type__c,
			MaintenanceJob__c.Status__c,
			MaintenanceJob__c.Hours__c,
			MaintenanceJob__c.Cost__c,
			MaintenanceJob__c.Reason__c,
			MaintenanceJob__c.HealthAtStart__c
		};
	}

	/**
	* SObject type this selector queries.
	* @return {@link MaintenanceJob__c} SObject type.
	*/
	public Schema.SObjectType getSObjectType() {
		return MaintenanceJob__c.SObjectType;
	}

	/**
	* Jobs by Id.
	* @param idSet Job Ids to query. Empty set returns an empty list.
	* @return Matching jobs.
	*/
	public virtual List<MaintenanceJob__c> selectById(Set<Id> idSet) {
		return (List<MaintenanceJob__c>) selectSObjectsById(idSet);
	}

	/**
	* Jobs by Id including the related robot, used when completing service.
	* @param idSet Job Ids to query. Empty set returns an empty list.
	* @return Matching jobs with Robot__r fields.
	*/
	public virtual List<MaintenanceJob__c> selectByIdWithRobot(Set<Id> idSet) {
		if (idSet == null || idSet.isEmpty()) {
			return new List<MaintenanceJob__c>();
		}
		fflib_QueryFactory query = newQueryFactory();
		RobotsSelector.newInstance().configureQueryFactoryFields(query, 'Robot__r');
		return (List<MaintenanceJob__c>) Database.query(query.setCondition('Id IN :idSet').toSOQL());
	}

	/**
	* Open (not Completed) jobs for the given robots.
	* @param robotIds Robot Ids. Empty set returns an empty list.
	* @return Matching open jobs.
	*/
	public virtual List<MaintenanceJob__c> selectOpenByRobot(Set<Id> robotIds) {
		if (robotIds == null || robotIds.isEmpty()) {
			return new List<MaintenanceJob__c>();
		}
		return (List<MaintenanceJob__c>) Database.query(
			newQueryFactory()
				.setCondition(
					'Robot__c IN :robotIds AND Status__c != \'' + MaintenanceJobs.STATUS_COMPLETED + '\''
				)
				.toSOQL()
		);
	}
}
