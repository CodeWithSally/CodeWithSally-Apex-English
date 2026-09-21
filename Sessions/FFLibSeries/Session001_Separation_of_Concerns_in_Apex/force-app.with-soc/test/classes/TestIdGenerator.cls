/**
 * Generates fake Salesforce Ids for unit tests without inserting records.
 */
@IsTest
public class TestIdGenerator {
	private static Integer sequence = 1;

	/**
	 * Builds a unique 15-character Id for the given SObject type using an incrementing sequence.
	 * @param sObjectType Type whose key prefix is used. Cannot be null.
	 * @return Synthetic Id suitable for unit tests; not persisted in the database.
	 */
	public static Id generate(Schema.SObjectType sObjectType) {
		String keyPrefix = sObjectType.getDescribe().getKeyPrefix();
		String suffix = String.valueOf(sequence++).leftPad(12, '0');
		return Id.valueOf(keyPrefix + suffix);
	}
}
