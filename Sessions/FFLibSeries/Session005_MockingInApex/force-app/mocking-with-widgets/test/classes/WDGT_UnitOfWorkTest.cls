/**
 * Unit of Work tests. Session 005 mocking examples: the same behavior tested with a mock Unit of Work,
 * with an inert Unit of Work, then with DML and SOQL.
 * Each test logs its elapsed time, CPU time, SOQL queries, and DML statements for comparison.
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs') // the mocked and inert tests do no DML; the DML test runs as a Widgets user
private class WDGT_UnitOfWorkTest {
	@IsTest
	private static void tagWidgetsWithGuid_WHEN_twoWidgetsMocked_EXPECT_eachRegisteredDirtyAndCommitted() {
		Long startMs = System.currentTimeMillis();

		// Given two widgets, a stubbed selector, a stubbed GUID generator, and a mock Unit of Work
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		WDGT_WidgetsSelector selectorMock = (WDGT_WidgetsSelector) mocks.mock(WDGT_WidgetsSelector.class);
		WDGT_WidgetsUtility utilityMock = (WDGT_WidgetsUtility) mocks.mock(WDGT_WidgetsUtility.class);
		fflib_SObjectUnitOfWork uowMock = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);

		WDGT_Widget__c first = new WDGT_Widget__c(Id = fflib_IDGenerator.generate(WDGT_Widget__c.SObjectType));
		WDGT_Widget__c second = new WDGT_Widget__c(Id = fflib_IDGenerator.generate(WDGT_Widget__c.SObjectType));
		Set<Id> widgetIds = new Set<Id>{ first.Id, second.Id };
		String firstGuid = '11111111111111111111111111111111';
		String secondGuid = '22222222222222222222222222222222';

		mocks.startStubbing();
		mocks.when(selectorMock.selectById(widgetIds)).thenReturn(new List<WDGT_Widget__c>{ first, second });
		mocks.when(utilityMock.generateGuid()).thenReturnMulti(new List<Object>{ firstGuid, secondGuid });
		mocks.stopStubbing();

		WDGT_UnitOfWork.mock = uowMock;

		// When the widgets are tagged
		new WDGT_WidgetsService(selectorMock, utilityMock).tagWidgetsWithGuid(widgetIds);

		// Then each widget gets its own GUID, is registered dirty with only Id and GUID, and the UoW commits once
		Assert.areEqual(firstGuid, first.WDGT_Guid__c, 'First widget should get the first GUID');
		Assert.areEqual(secondGuid, second.WDGT_Guid__c, 'Second widget should get the second GUID');
		((fflib_SObjectUnitOfWork) mocks.verify(uowMock)).registerDirty(new WDGT_Widget__c(Id = first.Id, WDGT_Guid__c = firstGuid));
		((fflib_SObjectUnitOfWork) mocks.verify(uowMock)).registerDirty(new WDGT_Widget__c(Id = second.Id, WDGT_Guid__c = secondGuid));
		((fflib_SObjectUnitOfWork) mocks.verify(uowMock, 1)).commitWork();

		logTiming('Mocked', startMs);
	}

	@IsTest
	private static void tagWidgetsWithGuid_WHEN_twoWidgetsMocked_EXPECT_matchedAndCaptured() {
		// Given two widgets, a stubbed selector, a stubbed GUID generator, and a mock Unit of Work
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		WDGT_WidgetsSelector selectorMock = (WDGT_WidgetsSelector) mocks.mock(WDGT_WidgetsSelector.class);
		WDGT_WidgetsUtility utilityMock = (WDGT_WidgetsUtility) mocks.mock(WDGT_WidgetsUtility.class);
		fflib_SObjectUnitOfWork uowMock = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);

		WDGT_Widget__c first = new WDGT_Widget__c(Id = fflib_IDGenerator.generate(WDGT_Widget__c.SObjectType));
		WDGT_Widget__c second = new WDGT_Widget__c(Id = fflib_IDGenerator.generate(WDGT_Widget__c.SObjectType));
		Set<Id> widgetIds = new Set<Id>{ first.Id, second.Id };
		String firstGuid = '11111111111111111111111111111111';
		String secondGuid = '22222222222222222222222222222222';

		mocks.startStubbing();
		mocks.when(selectorMock.selectById(widgetIds)).thenReturn(new List<WDGT_Widget__c>{ first, second });
		mocks.when(utilityMock.generateGuid()).thenReturnMulti(new List<Object>{ firstGuid, secondGuid });
		mocks.stopStubbing();

		WDGT_UnitOfWork.mock = uowMock;

		// When the widgets are tagged
		new WDGT_WidgetsService(selectorMock, utilityMock).tagWidgetsWithGuid(widgetIds);

		// Then, with matchers: two registrations, one of them carrying the first widget's Id and GUID
		((fflib_SObjectUnitOfWork) mocks.verify(uowMock, 2)).registerDirty(fflib_Match.anySObject());
		((fflib_SObjectUnitOfWork) mocks.verify(uowMock)).registerDirty(
			fflib_Match.sObjectWith(new Map<SObjectField, Object>{
				WDGT_Widget__c.Id => first.Id,
				WDGT_Widget__c.WDGT_Guid__c => firstGuid
			})
		);

		// And, with a captor: the registered records themselves, in the order they were registered
		fflib_ArgumentCaptor captor = fflib_ArgumentCaptor.forClass(WDGT_Widget__c.class);
		((fflib_SObjectUnitOfWork) mocks.verify(uowMock, 2)).registerDirty((SObject) captor.capture());
		List<Object> registered = captor.getAllValues();
		Assert.areEqual(new WDGT_Widget__c(Id = first.Id, WDGT_Guid__c = firstGuid), registered[0], 'First widget registration');
		Assert.areEqual(new WDGT_Widget__c(Id = second.Id, WDGT_Guid__c = secondGuid), registered[1], 'Second widget registration');
	}

	@IsTest
	private static void tagWidgetsWithGuid_WHEN_twoWidgetsMocked_EXPECT_registeredBeforeCommit() {
		// Given two widgets, a stubbed selector, a stubbed GUID generator, and a mock Unit of Work
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		WDGT_WidgetsSelector selectorMock = (WDGT_WidgetsSelector) mocks.mock(WDGT_WidgetsSelector.class);
		WDGT_WidgetsUtility utilityMock = (WDGT_WidgetsUtility) mocks.mock(WDGT_WidgetsUtility.class);
		fflib_SObjectUnitOfWork uowMock = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);

		WDGT_Widget__c first = new WDGT_Widget__c(Id = fflib_IDGenerator.generate(WDGT_Widget__c.SObjectType));
		WDGT_Widget__c second = new WDGT_Widget__c(Id = fflib_IDGenerator.generate(WDGT_Widget__c.SObjectType));
		Set<Id> widgetIds = new Set<Id>{ first.Id, second.Id };

		mocks.startStubbing();
		mocks.when(selectorMock.selectById(widgetIds)).thenReturn(new List<WDGT_Widget__c>{ first, second });
		mocks.when(utilityMock.generateGuid()).thenReturnMulti(new List<Object>{
			'11111111111111111111111111111111',
			'22222222222222222222222222222222'
		});
		mocks.stopStubbing();

		WDGT_UnitOfWork.mock = uowMock;

		// When the widgets are tagged
		new WDGT_WidgetsService(selectorMock, utilityMock).tagWidgetsWithGuid(widgetIds);

		// Then both widgets are registered before the Unit of Work commits
		fflib_InOrder inOrder = mocks.inOrder(new List<Object>{ uowMock });
		((fflib_SObjectUnitOfWork) inOrder.verify(uowMock, mocks.calls(2))).registerDirty(fflib_Match.anySObject());
		((fflib_SObjectUnitOfWork) inOrder.verify(uowMock, mocks.calls(1))).commitWork();
	}

	@IsTest
	private static void tagWidgetsWithGuid_WHEN_twoWidgetsInert_EXPECT_eachUpdatedWithStubbedGuid() {
		Long startMs = System.currentTimeMillis();

		// Given two widgets, a stubbed selector, a stubbed GUID generator, and an inert Unit of Work
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		WDGT_WidgetsSelector selectorMock = (WDGT_WidgetsSelector) mocks.mock(WDGT_WidgetsSelector.class);
		WDGT_WidgetsUtility utilityMock = (WDGT_WidgetsUtility) mocks.mock(WDGT_WidgetsUtility.class);
		WDGT_InertDml inertDml = new WDGT_InertDml();

		WDGT_Widget__c first = new WDGT_Widget__c(Id = fflib_IDGenerator.generate(WDGT_Widget__c.SObjectType));
		WDGT_Widget__c second = new WDGT_Widget__c(Id = fflib_IDGenerator.generate(WDGT_Widget__c.SObjectType));
		Set<Id> widgetIds = new Set<Id>{ first.Id, second.Id };
		String firstGuid = '11111111111111111111111111111111';
		String secondGuid = '22222222222222222222222222222222';

		mocks.startStubbing();
		mocks.when(selectorMock.selectById(widgetIds)).thenReturn(new List<WDGT_Widget__c>{ first, second });
		mocks.when(utilityMock.generateGuid()).thenReturnMulti(new List<Object>{ firstGuid, secondGuid });
		mocks.stopStubbing();

		WDGT_UnitOfWork.mock = new fflib_SObjectUnitOfWork(new List<SObjectType>{ WDGT_Widget__c.SObjectType }, inertDml);

		// When the widgets are tagged
		new WDGT_WidgetsService(selectorMock, utilityMock).tagWidgetsWithGuid(widgetIds);

		// Then the records that would have been updated are exactly Id and GUID for each widget, and nothing else was saved
		WDGT_Widget__c firstUpdated = (WDGT_Widget__c) inertDml.updated[0];
		WDGT_Widget__c secondUpdated = (WDGT_Widget__c) inertDml.updated[1];
		Assert.areEqual(new WDGT_Widget__c(Id = first.Id, WDGT_Guid__c = firstGuid), firstUpdated, 'First widget update');
		Assert.areEqual(new WDGT_Widget__c(Id = second.Id, WDGT_Guid__c = secondGuid), secondUpdated, 'Second widget update');
		Assert.areEqual(firstGuid, firstUpdated.WDGT_Guid__c, 'First widget should be saved with the first GUID');
		Assert.areEqual(secondGuid, secondUpdated.WDGT_Guid__c, 'Second widget should be saved with the second GUID');
		Assert.isTrue(inertDml.inserted.isEmpty(), 'Nothing should be inserted');
		Assert.isTrue(inertDml.deleted.isEmpty(), 'Nothing should be deleted');

		logTiming('Inert', startMs);
	}

	@IsTest
	private static void tagWidgetsWithGuid_WHEN_twoWidgetsSaved_EXPECT_eachSavedWithUniqueGuid() {
		Long startMs = System.currentTimeMillis();

		// Given a user who can edit Widgets, and two saved widgets
		User widgetUser = newWidgetUser();
		System.runAs(widgetUser) {
			List<WDGT_Widget__c> widgets = new List<WDGT_Widget__c>{ new WDGT_Widget__c(), new WDGT_Widget__c() };
			insert widgets;
			Set<Id> widgetIds = new Map<Id, WDGT_Widget__c>(widgets).keySet();

			// When the widgets are tagged through the live selector, utility, and Unit of Work
			WDGT_WidgetsService.newInstance().tagWidgetsWithGuid(widgetIds);

			// Then each saved widget has a 32-character GUID, and they differ (the values themselves are unknowable)
			List<WDGT_Widget__c> saved = [SELECT Id, WDGT_Guid__c FROM WDGT_Widget__c WHERE Id IN :widgetIds];
			Assert.areEqual(2, saved.size(), 'Both widgets should be saved');
			Assert.areEqual(32, saved[0].WDGT_Guid__c?.length(), 'First widget should have a 32-character GUID');
			Assert.areEqual(32, saved[1].WDGT_Guid__c?.length(), 'Second widget should have a 32-character GUID');
			Assert.areNotEqual(saved[0].WDGT_Guid__c, saved[1].WDGT_Guid__c, 'Each widget should get its own GUID');
		}

		logTiming('DML and SOQL', startMs);
	}

	/**
	* Inserts a Standard User with the WDGT_Widgets permission set, since the Unit of Work saves in user mode.
	* @return The inserted User ready for System.runAs.
	*/
	private static User newWidgetUser() {
		Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' AND UserLicense.Name = 'Salesforce' LIMIT 1];
		User u = new User(
			Alias = 'wdgt',
			Email = 'wdgt@test.org',
			EmailEncodingKey = 'UTF-8',
			LastName = 'WDGT Test User',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			ProfileId = p.Id,
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = 'wdgt_' + Datetime.now().getTime() + '@test.org'
		);
		insert u;
		PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'WDGT_Widgets' LIMIT 1];
		insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
		return u;
	}

	private static void logTiming(String label, Long startMs) {
		System.debug(
			LoggingLevel.INFO,
			'TIMING ' + label + ': ' + (System.currentTimeMillis() - startMs) + ' ms elapsed, '
				+ Limits.getCpuTime() + ' ms CPU, '
				+ Limits.getQueries() + ' SOQL, '
				+ Limits.getDmlStatements() + ' DML'
		);
	}
}
