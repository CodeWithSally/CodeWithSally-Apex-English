/**
 * Robot trigger. Delegates to {@link RobotsTriggerHandler} through fflib.
 */
trigger Robots on Robot__c (before insert, before update, after insert, after update) {
	fflib_SObjectDomain.triggerHandler(RobotsTriggerHandler.class);
}
