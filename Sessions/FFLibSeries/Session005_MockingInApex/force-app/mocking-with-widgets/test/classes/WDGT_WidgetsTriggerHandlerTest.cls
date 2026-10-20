/**
 * Coverage test for the {@code WDGT_Widgets} trigger. The handler is made inert with fflib's own switch,
 * so the save covers the trigger and the handler's construction without running any handler logic.
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs') // coverage test: one insert as the test user
private class WDGT_WidgetsTriggerHandlerTest {
	@IsTest
	private static void insert_WHEN_triggerHandlerDisabled_EXPECT_widgetSaved() {
		// Given every trigger event for the Widgets handler is disabled
		fflib_SObjectDomain.getTriggerEvent(WDGT_WidgetsTriggerHandler.class).disableAll();

		// When a widget is saved
		Test.startTest();
		Database.SaveResult result = Database.insert(new WDGT_Widget__c());
		Test.stopTest();

		// Then the save succeeds (validation rules and flows still run; beware)
		Assert.isTrue(result.isSuccess(), 'Widget should save with the handler disabled');
	}
}
