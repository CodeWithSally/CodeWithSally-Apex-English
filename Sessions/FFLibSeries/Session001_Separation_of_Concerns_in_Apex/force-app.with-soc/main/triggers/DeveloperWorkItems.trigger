trigger DeveloperWorkItems on DeveloperWorkItem__c (before insert, before update) {
	DeveloperWorkItems domain = DeveloperWorkItems.newInstance(Trigger.new);
	if (Trigger.isBefore && Trigger.isInsert) {
		domain.onBeforeInsert();
	} else if (Trigger.isBefore && Trigger.isUpdate) {
		domain.onBeforeUpdate(Trigger.oldMap);
	}
}
