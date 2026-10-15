/**
 * Widget trigger. Delegates to {@link WDGT_WidgetsTriggerHandler} through fflib.
 */
trigger WDGT_Widgets on WDGT_Widget__c (before insert, before update, after insert, after update) {
	fflib_SObjectDomain.triggerHandler(WDGT_WidgetsTriggerHandler.class);
}
