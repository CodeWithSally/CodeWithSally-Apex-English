fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
    new List<Schema.SObjectType> {
        Product2.SObjectType,
        PricebookEntry.SObjectType,
        Opportunity.SObjectType,
        OpportunityLineItem.SObjectType
    });
for (Integer o = 0; o < 10; o++) {
    Opportunity opp = new Opportunity();
    opp.Name = 'UoW Test Name ' + o;
    opp.StageName = 'Open';
    opp.CloseDate = System.today();
    uow.registerNew(opp);
    for (Integer i = 0; i < o + 1; i++) {
        Product2 product = new Product2();
        product.Name = opp.Name + ' : Product : ' + i;
        uow.registerNew(product);
        PricebookEntry pbe = new PricebookEntry();
        pbe.UnitPrice = 10;
        pbe.IsActive = true;
        pbe.UseStandardPrice = false;
        pbe.Pricebook2Id = pb.Id;
        uow.registerNew(pbe, PricebookEntry.Product2Id, product);
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.Quantity = 1;
        oli.TotalPrice = 10;
        uow.registerRelationship(oli, OpportunityLineItem.PricebookEntryId, pbe);
        uow.registerNew(oli, OpportunityLineItem.OpportunityId, opp);
    }
}
uow.commitWork();

// Recast of AndyInTheCloud, June 2013 — MY_SOBJECTS inlined for the slide.
// https://andyinthecloud.com/2013/06/09/managing-your-dml-and-transactions-with-a-unit-of-work/
