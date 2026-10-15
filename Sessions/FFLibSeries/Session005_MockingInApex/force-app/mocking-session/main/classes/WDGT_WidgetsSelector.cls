/**
 * Selector for Widget queries. Session 005 mocking example.
 */
public virtual inherited sharing class WDGT_WidgetsSelector extends fflib_SObjectSelector {
	/**
	* Factory that returns this selector.
	* @return {@link WDGT_WidgetsSelector} instance.
	*/
	public static WDGT_WidgetsSelector newInstance() {
		return new WDGT_WidgetsSelector();
	}

	/**
	* Constructs a user-mode widget selector.
	*/
	public WDGT_WidgetsSelector() {
		super(false, fflib_SObjectSelector.DataAccess.USER_MODE);
	}

	/**
	* Common widget fields used by this selector.
	* @return Field list for the query factory.
	*/
	public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField>{
			WDGT_Widget__c.Id,
			WDGT_Widget__c.Name,
			WDGT_Widget__c.WDGT_Guid__c
		};
	}

	/**
	* SObject type this selector queries.
	* @return {@link WDGT_Widget__c} SObject type.
	*/
	public Schema.SObjectType getSObjectType() {
		return WDGT_Widget__c.SObjectType;
	}

	/**
	* Widgets by Id.
	* @param idSet Widget Ids to query. Null is treated as an empty set; an empty set returns an empty list.
	* @return Matching widgets.
	*/
	public virtual List<WDGT_Widget__c> selectById(Set<Id> idSet) {
		idSet = (idSet != null) ? idSet : new Set<Id>();
		return (List<WDGT_Widget__c>) selectSObjectsById(idSet);
	}
}
