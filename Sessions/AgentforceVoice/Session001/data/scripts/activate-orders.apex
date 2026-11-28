// Activates the Draft orders loaded by 01-core-data-plan.json.
// Order.Status can't be set to Activated on insert (the SObject Tree Save API
// rejects it: "FAILED_ACTIVATION ... choose Draft"), so orders load as Draft
// and get flipped here in a follow-up update, after their OrderItems already
// exist. Scoped to accounts with Preferred_Language__c set, since that field
// is unique to this project's Person Accounts — this must never touch Draft
// orders belonging to unrelated org data.
List<Order> draftOrders = [
    SELECT Id
    FROM Order
    WHERE Status = 'Draft' AND Account.Preferred_Language__c != null
];

for (Order o : draftOrders) {
    o.Status = 'Activated';
}
update draftOrders;

System.debug('Activated ' + draftOrders.size() + ' order(s).');
