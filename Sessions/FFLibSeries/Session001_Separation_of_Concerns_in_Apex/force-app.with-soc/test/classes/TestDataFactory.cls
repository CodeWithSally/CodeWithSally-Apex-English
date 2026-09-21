/**
 * Shared test data factory. Creates a Standard User with ApexEnterprisePatternsSampleApp
 * permission set for runAs tests that require field-level access.
 */
@IsTest
public class TestDataFactory {
	private static final String RUN_AS_USER_LASTNAME = 'SampleApp';

	/**
	 * Inserts a Sales User (or Standard User fallback) and assigns ApexEnterprisePatternsSampleApp.
	 * @return The inserted User ready for System.runAs.
	 */
	public static User createUserWithSampleAppPermissions() {
		List<Profile> salesProfiles = [
			SELECT Id
			FROM Profile
			WHERE Name = 'Sales User' AND UserLicense.Name = 'Salesforce'
			LIMIT 1
		];
		Profile p = salesProfiles.isEmpty()
			? [
				SELECT Id
				FROM Profile
				WHERE Name = 'Standard User' AND UserLicense.Name = 'Salesforce'
				LIMIT 1
			]
			: salesProfiles[0];
		String uniqueName = 'sampleapp_' + DateTime.now().getTime() + '@test.org';
		User u = new User(
			Alias = 'sampapp',
			Email = 'sampleapp@test.org',
			EmailEncodingKey = 'UTF-8',
			LastName = RUN_AS_USER_LASTNAME,
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			ProfileId = p.Id,
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = uniqueName
		);
		insert u;

		PermissionSet ps = [
			SELECT Id
			FROM PermissionSet
			WHERE Name = 'ApexEnterprisePatternsSampleApp'
			LIMIT 1
		];
		insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
		return u;
	}

	/**
	 * Returns the runAs user previously created by {@link #createUserWithSampleAppPermissions}.
	 * @return User with LastName SampleApp; query exception if none exists.
	 */
	public static User getRunAsUser() {
		return [SELECT Id FROM User WHERE LastName = :RUN_AS_USER_LASTNAME LIMIT 1];
	}
}
