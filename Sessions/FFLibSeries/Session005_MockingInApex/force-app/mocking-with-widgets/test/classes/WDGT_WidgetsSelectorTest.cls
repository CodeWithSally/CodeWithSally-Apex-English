/**
 * Unit tests for {@link WDGT_WidgetsSelector}.
 * Queries get empty conditions only: these test our logic, not Salesforce's SOQL execution.
 * The exceptions are two marked demonstrations, which need saved rows: the field-misalignment gotcha, and the
 * hazard of tests that depend on DML.
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs') // unit tests use empty conditions; the demonstrations insert one widget each as the test user
private class WDGT_WidgetsSelectorTest {
	@IsTest
	private static void selectById_WHEN_emptyOrNullIds_EXPECT_noWidgets() {
		// Given a selector
		WDGT_WidgetsSelector selector = WDGT_WidgetsSelector.newInstance();

		// When it is asked for an empty Id set and a null one
		Test.startTest();
		Integer fromEmpty = selector.selectById(new Set<Id>()).size();
		Integer fromNull = selector.selectById(null).size();
		Test.stopTest();

		// Then each runs the query and returns nothing
		Assert.areEqual(0, fromEmpty, 'Empty Ids should return no widgets');
		Assert.areEqual(0, fromNull, 'Null Ids should return no widgets');
	}

	@IsTest
	private static void getSObjectType_WHEN_called_EXPECT_widgetType() {
		// When the selector reports what it queries
		Test.startTest();
		Schema.SObjectType queried = WDGT_WidgetsSelector.newInstance().getSObjectType();
		Test.stopTest();

		// Then it is the Widget object
		Assert.areEqual(WDGT_Widget__c.SObjectType, queried, 'Selector should query Widgets');
	}

	// Demonstration, not a pattern: this test breaks the empty-conditions rule on purpose, because Apex only
	// reports an unqueried field on a row SOQL actually returned. It reads a field the Selector never queries.
	// A test that builds the record in memory and mocks the Selector would never see this; real logic would,
	// at run time. The widget sets WDGT_MightBeRequired__c, so the validation rule doesn't affect this test.
	@IsTest
	private static void selectById_WHEN_savedWidgetReadsUnqueriedField_EXPECT_sObjectException() {
		// Given a saved widget (system mode: the test user has no access to the new field, and setup isn't under test)
		WDGT_Widget__c widget = new WDGT_Widget__c(WDGT_MightBeRequired__c = 'Present');
		Database.insert(widget, AccessLevel.SYSTEM_MODE);

		// When it is selected and logic reads a field the Selector doesn't query
		Test.startTest();
		WDGT_Widget__c selected = WDGT_WidgetsSelector.newInstance().selectById(new Set<Id>{ widget.Id })[0];
		SObjectException thrown;
		try {
			String mightBeRequired = selected.WDGT_MightBeRequired__c;
		} catch (SObjectException e) {
			thrown = e;
		}
		Test.stopTest();

		// Then reading it throws, naming the missing field
		Assert.isNotNull(thrown, 'Reading an unqueried field should throw');
		Assert.isTrue(
			thrown.getMessage().contains('WDGT_MightBeRequired__c'),
			'The exception should name the missing field: ' + thrown.getMessage()
		);

		// Contrast: a mocked Selector returns whatever the test built, so the same read works and the
		// misalignment hides. (Calling the mock directly is only acceptable in this demonstration.)
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		WDGT_WidgetsSelector selectorMock = (WDGT_WidgetsSelector) mocks.mock(WDGT_WidgetsSelector.class);
		WDGT_Widget__c inMemory = new WDGT_Widget__c(
			Id = fflib_IDGenerator.generate(WDGT_Widget__c.SObjectType),
			WDGT_MightBeRequired__c = 'Present'
		);
		mocks.startStubbing();
		mocks.when(selectorMock.selectById(new Set<Id>{ inMemory.Id })).thenReturn(new List<WDGT_Widget__c>{ inMemory });
		mocks.stopStubbing();

		String fromMock = selectorMock.selectById(new Set<Id>{ inMemory.Id })[0].WDGT_MightBeRequired__c;
		Assert.areEqual('Present', fromMock, 'A mocked Selector hides the missing field');
	}

	// Demonstration, not a pattern: the hazard of tests that depend on DML. This test saves a widget and nothing
	// else. Activate the WDGT_MightBeRequired validation rule in Setup and it fails, though no Apex changed:
	// the org's configuration is now part of the test. Unit tests that mock the database are unaffected.
	@IsTest
	private static void insert_WHEN_widgetSaved_EXPECT_success() {
		// Given a widget that leaves Might Be Required blank
		WDGT_Widget__c widget = new WDGT_Widget__c();

		// When it is saved
		Test.startTest();
		Database.SaveResult result = Database.insert(widget, false);
		Test.stopTest();

		// Then the save succeeds, until the WDGT_MightBeRequired validation rule is activated
		Assert.isTrue(result.isSuccess(), 'Widget should save: ' + result.getErrors());
	}
}
