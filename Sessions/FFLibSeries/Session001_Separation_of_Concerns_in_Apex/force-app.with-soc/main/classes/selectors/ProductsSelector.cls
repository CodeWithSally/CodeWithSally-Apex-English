/**
 * Selector for Product2 queries, optionally including OpportunityDiscount field set members.
 */
public virtual inherited sharing class ProductsSelector {
	@TestVisible
	private static ProductsSelector mock;

	/**
	 * Factory that returns a selector without field set fields, or {@link #mock} when tests have set one.
	 * @return {@link ProductsSelector} instance.
	 */
	public static ProductsSelector newInstance() {
		return newInstance(false);
	}

	/**
	 * Factory that returns a selector with optional field set fields, or {@link #mock} when tests have set one.
	 * @param includeFieldSetFields When true, OpportunityDiscount field set fields are included.
	 * @return {@link ProductsSelector} instance.
	 */
	public static ProductsSelector newInstance(Boolean includeFieldSetFields) {
		return mock != null ? mock : new ProductsSelector(includeFieldSetFields);
	}

	private Boolean includeFieldSetFields;

	/**
	 * Creates a selector that queries only the default product field list.
	 */
	public ProductsSelector() {
		this(false);
	}

	/**
	 * Creates a selector that optionally includes OpportunityDiscount field set fields.
	 * @param includeFieldSetFields When true, fields from Product2.FieldSets.OpportunityDiscount are added to the SELECT list.
	 */
	public ProductsSelector(Boolean includeFieldSetFields) {
		this.includeFieldSetFields = includeFieldSetFields == true;
	}

	/**
	 * Selects Products by Id as a generic SObject list.
	 * @param ids Product2 Ids to query. Empty set returns an empty list.
	 * @return Matching products cast as SObject.
	 */
	public List<SObject> selectSObjectsById(Set<Id> ids) {
		return selectById(ids);
	}

	/**
	 * Selects Products by Id using the configured field list.
	 * @param idSet Product2 Ids to query. Empty set returns an empty list.
	 * @return Matching Product2 records; empty list when none match.
	 */
	public List<Product2> selectById(Set<Id> idSet) {
		String soql = 'SELECT ' + fieldList() + ' FROM Product2 WHERE Id IN :idSet ORDER BY Name';
		return (List<Product2>) Database.query(soql);
	}

	/**
	 * Returns a QueryLocator for Products by Id using the configured field list.
	 * @param idSet Product2 Ids to include in the locator.
	 * @return QueryLocator suitable for Batch Apex or large result sets.
	 */
	public Database.QueryLocator queryLocatorById(Set<Id> idSet) {
		String soql = 'SELECT ' + fieldList() + ' FROM Product2 WHERE Id IN :idSet ORDER BY Name';
		return Database.getQueryLocator(soql);
	}

	private String fieldList() {
		List<String> fields = new List<String>{
			'Description',
			'Id',
			'IsActive',
			'Name',
			'ProductCode',
			'DiscountingApproved__c'
		};
		if (includeFieldSetFields) {
			for (Schema.FieldSetMember member : SObjectType.Product2.FieldSets.OpportunityDiscount.getFields()) {
				String path = member.getFieldPath();
				if (!fields.contains(path)) {
					fields.add(path);
				}
			}
		}
		return String.join(fields, ',');
	}
}
