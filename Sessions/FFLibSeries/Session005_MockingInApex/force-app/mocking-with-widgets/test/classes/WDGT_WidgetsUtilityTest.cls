/**
 * Unit tests for {@link WDGT_WidgetsUtility}. No DML.
 * GUIDs are random, so these assert structure and, weakly, randomness.
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs') // unit test: no DML
private class WDGT_WidgetsUtilityTest {
	private static final Integer GUID_COUNT = 100;

	@IsTest
	private static void generateGuid_WHEN_calledRepeatedly_EXPECT_distinctVersion4HexGuids() {
		// Given a utility
		WDGT_WidgetsUtility utility = WDGT_WidgetsUtility.newInstance();

		// When many GUIDs are generated
		List<String> guids = new List<String>();
		Test.startTest();
		for (Integer i = 0; i < GUID_COUNT; i++) {
			guids.add(utility.generateGuid());
		}
		Test.stopTest();

		// Then each is 32 lowercase hex characters with the version 4 and RFC variant digits,
		// and none repeats (a weak check of randomness)
		for (String guid : guids) {
			Assert.isTrue(Pattern.matches('[0-9a-f]{32}', guid), 'Should be 32 lowercase hex characters: ' + guid);
			Assert.areEqual('4', guid.substring(12, 13), 'Version digit should be 4: ' + guid);
			Assert.isTrue('89ab'.contains(guid.substring(16, 17)), 'Variant digit should be 8, 9, a or b: ' + guid);
		}
		Assert.areEqual(GUID_COUNT, new Set<String>(guids).size(), 'Every GUID should be different');
	}
}
