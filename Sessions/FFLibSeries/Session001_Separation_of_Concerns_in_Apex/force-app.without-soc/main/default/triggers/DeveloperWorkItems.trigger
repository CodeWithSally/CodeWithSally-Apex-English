trigger DeveloperWorkItems on DeveloperWorkItem__c (before insert, before update) {
	for (DeveloperWorkItem__c workItem : Trigger.new) {
		workItem.DeveloperCost__c =
			(workItem.CodingHours__c + workItem.CodeReviewingHours__c + workItem.TechnicalDesignHours__c) * 100;
	}
}
