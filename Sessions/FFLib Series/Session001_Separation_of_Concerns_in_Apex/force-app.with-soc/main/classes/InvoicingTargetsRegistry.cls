/**
 * Registry for polymorphic invoicing. Resolves selectors and domains by SObject type
 * for types registered in InvoiceTargets__mdt.
 */
public inherited sharing class InvoicingTargetsRegistry {
	private static Set<SObjectType> supportedTypes;

	@TestVisible
	private static Map<SObjectType, List<SObject>> mockSelectByIdResults;
	@TestVisible
	private static Map<SObjectType, Object> mockDomains;

	/**
	 * Constructs a domain for the given records using the type registered for invoicing.
	 * @param records Homogeneous SObject list whose type is registered for invoicing. Cannot be null.
	 * @return Domain instance for the records' SObject type (for example {@link Opportunities}).
	 * @throws InvoicingTargetsRegistryException When the type is unsupported or cannot be determined.
	 */
	public static Object newDomain(List<SObject> records) {
		SObjectType t = records.getSObjectType();
		if (t == null) {
			throw new InvoicingTargetsRegistryException('Unable to determine SObjectType');
		}
		if (mockDomains != null && mockDomains.containsKey(t)) {
			return mockDomains.get(t);
		}
		ensureInitialized();
		if (!supportedTypes.contains(t)) {
			throw new InvoicingTargetsRegistryException('No domain configured for ' + String.valueOf(t));
		}
		if (t == Opportunity.SObjectType) {
			return Opportunities.newInstance((List<Opportunity>) records);
		}
		if (t == DeveloperWorkItem__c.SObjectType) {
			return DeveloperWorkItems.newInstance((List<DeveloperWorkItem__c>) records);
		}
		if (t == TrainingWorkItem__c.SObjectType) {
			return TrainingWorkItems.newInstance((List<TrainingWorkItem__c>) records);
		}
		throw new InvoicingTargetsRegistryException('No domain configured for ' + String.valueOf(t));
	}

	/**
	 * Selects records by Id using the selector for that SObject type.
	 * @param recordIds Homogeneous set of Ids. Cannot be null or empty.
	 * @return Matching SObjects queried with fields needed for invoicing.
	 * @throws InvoicingTargetsRegistryException When Ids are invalid, mixed, or the type is unsupported.
	 */
	public static List<SObject> selectById(Set<Id> recordIds) {
		if (recordIds == null || recordIds.isEmpty()) {
			throw new InvoicingTargetsRegistryException('Invalid record Ids');
		}
		SObjectType t = new List<Id>(recordIds)[0].getSObjectType();
		for (Id recordId : recordIds) {
			if (recordId.getSObjectType() != t) {
				throw new InvoicingTargetsRegistryException('Mixed SObject types');
			}
		}
		if (mockSelectByIdResults != null && mockSelectByIdResults.containsKey(t)) {
			return mockSelectByIdResults.get(t);
		}
		ensureInitialized();
		if (!supportedTypes.contains(t)) {
			throw new InvoicingTargetsRegistryException('No selector configured for ' + String.valueOf(t));
		}
		if (t == Opportunity.SObjectType) {
			return OpportunitiesSelector.newInstance().selectByIdWithProducts(recordIds);
		}
		if (t == DeveloperWorkItem__c.SObjectType) {
			return DeveloperWorkItemsSelector.newInstance().selectById(recordIds);
		}
		if (t == TrainingWorkItem__c.SObjectType) {
			return TrainingWorkItemsSelector.newInstance().selectById(recordIds);
		}
		throw new InvoicingTargetsRegistryException('No selector configured for ' + String.valueOf(t));
	}

	private static void ensureInitialized() {
		if (supportedTypes != null) {
			return;
		}
		supportedTypes = new Set<SObjectType>();
		Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
		for (InvoiceTargets__mdt c : [
			SELECT SObjectType__r.QualifiedApiName
			FROM InvoiceTargets__mdt
			WHERE SObjectType__c != null
		]) {
			SObjectType sot = gd.get(c.SObjectType__r.QualifiedApiName);
			if (sot != null) {
				supportedTypes.add(sot);
			}
		}
	}

	/**
	 * Thrown when registry lookup or domain/selector construction fails.
	 */
	public class InvoicingTargetsRegistryException extends Exception {
	}
}
