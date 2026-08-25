/**
 * Integration test for DeveloperWorkItems cost calculation.
 */
@IsTest
private class DeveloperWorkItemsTest {
	@TestSetup
	static void setup() {
		// Given a run-as user with sample app permissions
		TestDataFactory.createUserWithSampleAppPermissions();
	}

	@IsTest
	static void insertWorkItemsCalculatesCost() {
		System.runAs(TestDataFactory.getRunAsUser()) {
			// Given a work order and developer work item with hours
			WorkOrder__c wo = new WorkOrder__c();
			insert wo;
			DeveloperWorkItem__c wi = new DeveloperWorkItem__c(
				WorkOrder__c = wo.Id,
				CodingHours__c = 20,
				CodeReviewingHours__c = 1,
				TechnicalDesignHours__c = 10
			);

			// When the work item is inserted
			Test.startTest();
			insert wi;
			Test.stopTest();

			// Then the developer cost is calculated from hours worked
			System.assertEquals(
				3100,
				[SELECT DeveloperCost__c FROM DeveloperWorkItem__c WHERE Id = :wi.Id].DeveloperCost__c,
				'Developer cost should be 3100'
			);
		}
	}
}
