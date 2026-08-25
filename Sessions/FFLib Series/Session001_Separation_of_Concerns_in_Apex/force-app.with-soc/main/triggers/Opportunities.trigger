trigger Opportunities on Opportunity (before insert, before update, after insert) {
	OpportunitiesTriggerHandler domain = new OpportunitiesTriggerHandler();
	if (Trigger.isBefore && Trigger.isInsert) {
		domain.onBeforeInsert();
	} else if (Trigger.isBefore && Trigger.isUpdate) {
		domain.onBeforeUpdate(Trigger.oldMap);
	} else if (Trigger.isAfter && Trigger.isInsert) {
		domain.onAfterInsert();
	}
}
