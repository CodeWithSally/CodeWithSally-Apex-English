// Org defaults and backfill for sample app demos (run via bin/data.sh).
OpportunitySettings__c settings = OpportunitySettings__c.getOrgDefaults();
if (settings.Id == null) {
	settings = new OpportunitySettings__c(SetupOwnerId = UserInfo.getOrganizationId());
}
settings.DiscountType__c = 'Approved Products';
upsert settings;

List<Opportunity> opps = [
	SELECT Id, DiscountType__c
	FROM Opportunity
	WHERE DiscountType__c = NULL
];
for (Opportunity opp : opps) {
	opp.DiscountType__c = settings.DiscountType__c;
}
if (!opps.isEmpty()) {
	update opps;
}
