/**
 * Robot trigger handler. Object invariants only: defaults, health from wear, legal status edits.
 * Does not dispatch work or create maintenance jobs.
 */
public inherited sharing class RobotsTriggerHandler extends fflib_SObjectDomain {
	/**
	* Creates a trigger handler wrapping the given Robot records.
	* @param sObjectList Robots in the trigger context.
	*/
	public RobotsTriggerHandler(List<Robot__c> sObjectList) {
		super(sObjectList);
	}

	/**
	* Applies Idle, zero wear, zero hours, full battery, and health from wear when fields are blank.
	*/
	public override void onApplyDefaults() {
		for (Robot__c robot : (List<Robot__c>) Records) {
			if (String.isBlank(robot.Status__c)) {
				robot.Status__c = Robots.STATUS_IDLE;
			}
			if (robot.WearPercent__c == null) {
				robot.WearPercent__c = 0;
			}
			if (robot.HoursSinceService__c == null) {
				robot.HoursSinceService__c = 0;
			}
			if (robot.BatteryLevel__c == null) {
				robot.BatteryLevel__c = 100;
			}
			robot.Health__c = Robots.healthFromWear(robot.WearPercent__c);
		}
	}

	/**
	* Blocks illegal status edits on update.
	* @param existingRecords Prior Robot versions keyed by Id.
	*/
	public override void onValidate(Map<Id, SObject> existingRecords) {
		for (Robot__c robot : (List<Robot__c>) Records) {
			Robot__c existing = (Robot__c) existingRecords.get(robot.Id);
			if (robot.Status__c != existing.Status__c
				&& !Robots.isLegalStatusTransition(existing.Status__c, robot.Status__c)) {
				robot.Status__c.addError(
					error(
						'Illegal status change from ' + existing.Status__c + ' to ' + robot.Status__c + '.',
						robot,
						Robot__c.Status__c
					)
				);
			}
		}
	}

	/**
	* Recalculates health when wear changes.
	* @param existingRecords Prior Robot versions keyed by Id.
	*/
	public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
		for (Robot__c robot : (List<Robot__c>) Records) {
			Robot__c existing = (Robot__c) existingRecords.get(robot.Id);
			if (robot.WearPercent__c != existing.WearPercent__c) {
				robot.Health__c = Robots.healthFromWear(robot.WearPercent__c);
			}
		}
	}

	/**
	* fflib constructable used by {@code fflib_SObjectDomain.triggerHandler}.
	*/
	public class Constructor implements fflib_SObjectDomain.IConstructable {
		/**
		* Builds a {@link RobotsTriggerHandler} for the given records.
		* @param sObjectList Robots in the trigger context.
		* @return Trigger handler instance.
		*/
		public fflib_SObjectDomain construct(List<SObject> sObjectList) {
			return new RobotsTriggerHandler((List<Robot__c>) sObjectList);
		}
	}
}
