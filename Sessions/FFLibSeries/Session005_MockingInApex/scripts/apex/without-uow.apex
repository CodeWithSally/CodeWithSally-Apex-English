// From AndyInTheCloud, June 2013
// https://andyinthecloud.com/2013/06/09/managing-your-dml-and-transactions-with-a-unit-of-work/
// Generics restored — WordPress stripped <Type> from the published HTML.

List<Opportunity> opps = new List<Opportunity>();
List<List<Product2>> productsByOpp = new List<List<Product2>>();
List<List<PricebookEntry>> pricebookEntriesByOpp = new List<List<PricebookEntry>>();
List<List<OpportunityLineItem>> oppLinesByOpp = new List<List<OpportunityLineItem>>();
for(Integer o=0; o<10; o++)
{
    Opportunity opp = new Opportunity();
    opp.Name = 'NoUoW Test Name ' + o;
    opp.StageName = 'Open';
    opp.CloseDate = System.today();
    opps.add(opp);
    List<Product2> products = new List<Product2>();
    List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
    List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
    for(Integer i=0; i<o+1; i++)
    {
        Product2 product = new Product2();
        product.Name = opp.Name + ' : Product : ' + i;
        products.add(product);
        PricebookEntry pbe = new PricebookEntry();
        pbe.UnitPrice = 10;
        pbe.IsActive = true;
        pbe.UseStandardPrice = false;
        pbe.Pricebook2Id = pb.Id;
        pricebookEntries.add(pbe);
        OpportunityLineItem oppLineItem = new OpportunityLineItem();
        oppLineItem.Quantity = 1;
        oppLineItem.TotalPrice = 10;
        oppLineItems.add(oppLineItem);
    }
    productsByOpp.add(products);
    pricebookEntriesByOpp.add(pricebookEntries);
    oppLinesByOpp.add(oppLineItems);
}
// Insert Opportunities
insert opps;
// Insert Products
List<Product2> allProducts = new List<Product2>();
for(List<Product2> products : productsByOpp)
{
    allProducts.addAll(products);
}
insert allProducts;
// Insert Pricebooks
Integer oppIdx = 0;
List<PricebookEntry> allPricebookEntries = new List<PricebookEntry>();
for(List<PricebookEntry> pricebookEntries : pricebookEntriesByOpp)
{
    List<Product2> products = productsByOpp[oppIdx++];
    Integer lineIdx = 0;
    for(PricebookEntry pricebookEntry : pricebookEntries)
    {
        pricebookEntry.Product2Id = products[lineIdx++].Id;
    }
    allPricebookEntries.addAll(pricebookEntries);
}
insert allPricebookEntries;
// Insert Opportunity Lines
oppIdx = 0;
List<OpportunityLineItem> allOppLineItems = new List<OpportunityLineItem>();
for(List<OpportunityLineItem> oppLines : oppLinesByOpp)
{
    List<PricebookEntry> pricebookEntries = pricebookEntriesByOpp[oppIdx];
    Integer lineIdx = 0;
    for(OpportunityLineItem oppLine : oppLines)
    {
        oppLine.OpportunityId = opps[oppIdx].Id;
        oppLine.PricebookEntryId = pricebookEntries[lineIdx++].Id;
    }
    allOppLineItems.addAll(oppLines);
    oppIdx++;
}
insert allOppLineItems;
