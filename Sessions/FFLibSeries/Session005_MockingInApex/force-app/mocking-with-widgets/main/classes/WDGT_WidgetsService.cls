/**
 * Widgets process. Session 005 mocking example.
 * Each method that persists creates a fresh {@link WDGT_UnitOfWork#newInstance}.
 */
public virtual inherited sharing class WDGT_WidgetsService {
	private final WDGT_WidgetsSelector widgetSelector;
	private final WDGT_WidgetsUtility widgetsUtility;

	/**
	* Default composition: live {@link WDGT_WidgetsSelector} and {@link WDGT_WidgetsUtility}.
	* @return {@link WDGT_WidgetsService} instance.
	*/
	public static WDGT_WidgetsService newInstance() {
		return new WDGT_WidgetsService(
			WDGT_WidgetsSelector.newInstance(),
			WDGT_WidgetsUtility.newInstance()
		);
	}

	/**
	* Creates a service with the given collaborators.
	* @param widgetSelector Widget selector. Cannot be null.
	* @param widgetsUtility Widgets helper logic. Cannot be null.
	*/
	public WDGT_WidgetsService(WDGT_WidgetsSelector widgetSelector, WDGT_WidgetsUtility widgetsUtility) {
		this.widgetSelector = widgetSelector;
		this.widgetsUtility = widgetsUtility;
	}

	/**
	* Tag process: give each Widget a new GUID and save.
	* @param widgetsIdSet Widget Ids to tag. Empty set performs no DML.
	* @throws WidgetsServiceException if DML fails.
	*/
	public virtual void tagWidgetsWithGuid(Set<Id> widgetsIdSet) {
		if (widgetsIdSet == null || widgetsIdSet.isEmpty()) {
			return;
		}
		try {
			fflib_SObjectUnitOfWork uow = WDGT_UnitOfWork.newInstance();
			for (WDGT_Widget__c widget : widgetSelector.selectById(widgetsIdSet)) {
				widget.WDGT_Guid__c = widgetsUtility.generateGuid();
				uow.registerDirty(new WDGT_Widget__c(Id = widget.Id, WDGT_Guid__c = widget.WDGT_Guid__c));
			}
			uow.commitWork();
		} catch (Exception e) {
			throw wrap(e);
		}
	}

	private static WidgetsServiceException wrap(Exception e) {
		if (e instanceof WidgetsServiceException) {
			return (WidgetsServiceException) e;
		}
		if (e instanceof DmlException) {
			return new WidgetsServiceException(
				'Error tagging widgets: ' + ((DmlException) e).getDmlMessage(0),
				e
			);
		}
		return new WidgetsServiceException(e.getMessage(), e);
	}

	/**
	* Client-agnostic exception thrown by widgets service methods.
	*/
	public class WidgetsServiceException extends Exception {
	}
}
