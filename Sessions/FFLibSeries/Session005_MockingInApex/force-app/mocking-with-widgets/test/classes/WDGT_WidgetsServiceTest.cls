/**
 * Unit tests for {@link WDGT_WidgetsService} error handling. No DML.
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs') // unit test: every collaborator mocked; no DML
private class WDGT_WidgetsServiceTest {
	@IsTest
	private static void tagWidgetsWithGuid_WHEN_selectorThrowsQueryException_EXPECT_serviceExceptionAndNoCommit() {
		// Given a selector that throws a QueryException, a GUID generator, and a mock Unit of Work
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		WDGT_WidgetsSelector selectorMock = (WDGT_WidgetsSelector) mocks.mock(WDGT_WidgetsSelector.class);
		WDGT_WidgetsUtility utilityMock = (WDGT_WidgetsUtility) mocks.mock(WDGT_WidgetsUtility.class);
		fflib_SObjectUnitOfWork uowMock = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);

		Set<Id> widgetIds = new Set<Id>{ fflib_IDGenerator.generate(WDGT_Widget__c.SObjectType) };
		QueryException queryFailure = new QueryException('Selector failed');

		mocks.startStubbing();
		mocks.when(selectorMock.selectById(widgetIds)).thenThrow(queryFailure);
		mocks.stopStubbing();

		WDGT_UnitOfWork.mock = uowMock;

		// When the widgets are tagged
		WDGT_WidgetsService.WidgetsServiceException thrown;
		try {
			new WDGT_WidgetsService(selectorMock, utilityMock).tagWidgetsWithGuid(widgetIds);
		} catch (WDGT_WidgetsService.WidgetsServiceException e) {
			thrown = e;
		}

		// Then the QueryException is wrapped in the service's exception, no GUID is generated, and nothing commits
		Assert.isNotNull(thrown, 'A WidgetsServiceException should be thrown');
		Assert.areEqual(queryFailure, thrown.getCause(), 'The QueryException should be the cause');
		((WDGT_WidgetsUtility) mocks.verify(utilityMock, fflib_ApexMocks.NEVER)).generateGuid();
		((fflib_SObjectUnitOfWork) mocks.verify(uowMock, fflib_ApexMocks.NEVER)).commitWork();
	}
}
