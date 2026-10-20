/**
 * Widget trigger handler. Converts trigger specifics to general Apex and calls other logic; holds no logic itself.
 */
public inherited sharing class WDGT_WidgetsTriggerHandler extends fflib_SObjectDomain {
	/**
	* Creates a trigger handler wrapping the given Widget records.
	* @param sObjectList Widgets in the trigger context.
	*/
	public WDGT_WidgetsTriggerHandler(List<WDGT_Widget__c> sObjectList) {
		super(sObjectList);
	}

	/**
	* fflib constructable used by {@code fflib_SObjectDomain.triggerHandler}.
	*/
	public class Constructor implements fflib_SObjectDomain.IConstructable {
		/**
		* Builds a {@link WDGT_WidgetsTriggerHandler} for the given records.
		* @param sObjectList Widgets in the trigger context.
		* @return Trigger handler instance.
		*/
		public fflib_SObjectDomain construct(List<SObject> sObjectList) {
			return new WDGT_WidgetsTriggerHandler((List<WDGT_Widget__c>) sObjectList);
		}
	}
}
