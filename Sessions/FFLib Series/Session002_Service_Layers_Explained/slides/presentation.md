---
marp: true
theme: session
paginate: true
lang: en
html: true
---

<!-- _class: title-slide -->

# Service Layers Explained
### Coordinating Business Logic in Apex
#### FFLib Series · Session 002

#### Andrew Fawcett
###### Code With Sally

![Code With Sally](images/codewithsally.png)

---

<!-- _class: detail-slide about-slide -->

<div class="about-split">
<div class="about-copy">

# About me

##### Independent Salesforce Consultant | Former CPO, Salesforce, Heroku | CTO, FinancialForce.com

* **Independent consultant and architect** — Salesforce platform development, PaaS integrations, and agentic AI
* **Open source and guidance** — creator of DLRS, Apex frameworks, and *Salesforce Platform Enterprise Architecture*
* **Salesforce Customers and Partners Advisory** — architecture and scale, AI-enhanced workflows, org health and codebase mentoring, and ISV product advisory

<!-- -->

* Reduce complexity, unblock engineering, and leave architectures — and teams — able to evolve.

</div>
<div class="about-aside">
<div class="about-logo-wrap">
<img src="images/AndyInTheCLoudLogo.png" alt="AndyInTheCloud" />
</div>
<a class="about-book" href="https://www.amazon.com/Salesforce-Platform-Enterprise-Architecture-applications/dp/1804619779">
<img src="images/bookpic.jpg" alt="Salesforce Platform Enterprise Architecture" />
</a>
</div>
</div>

---

<!-- _class: detail-slide series-slide -->

# The series

<table>
<thead>
<tr><th></th><th>Session</th></tr>
</thead>
<tbody>
<tr class="done"><td><span class="check">✅</span></td><td>Session #1 - Separation of Concerns in Apex: Why Your Future Self Will Thank You</td></tr>
<tr class="current"><td><span class="check"></span></td><td>Session #2 - Service Layers Explained: Coordinating Business Logic in Apex</td></tr>
<tr><td><span class="check"></span></td><td>Session #3 - Domain vs Service: Where Should Your Apex Logic Live?</td></tr>
<tr><td><span class="check"></span></td><td>Session #4 - Query Logic as a First-Class Architecture Concern</td></tr>
<tr><td><span class="check"></span></td><td>Session #5 - Mocking in Apex: Why It Changes Everything</td></tr>
<tr><td><span class="check"></span></td><td>Session #6 - Enterprise-Scale Apex Across Multiple Packages</td></tr>
</tbody>
</table>

---

<!-- _class: detail-slide service-layer-def-slide -->

# Coordinating Business Logic in Apex

<div class="service-layer-graphic">
  <img src="images/service-layer-conductor.svg?v=11" alt="Client crowds including LWC, REST, Flow, Agent, Batch, and more stand behind the Warehouse Operations App Services; Fulfillment, Dispatch, and Maintenance stand in front" />
</div>

---

<!-- _class: detail-slide quote-slide service-quote-slide -->

# Service Layer

<blockquote>
Defines an application's boundary with a layer of services that establishes a set of available operations and coordinates the application's response in each operation.
</blockquote>

<p class="quote-source"><a href="https://martinfowler.com/eaaCatalog/serviceLayer.html">Martin Fowler</a> — <em>Patterns of Enterprise Application Architecture</em></p>

<div class="service-layer-band">
  <img src="images/service-layer-band.svg" alt="Fulfillment, Dispatch, and Maintenance stand on the Service layer" />
</div>

---

<!-- _class: detail-slide checklist-slide -->

# Service Layers Explained

<img class="checklist-gears" src="images/pattern-layers-gears.svg" alt="Domain, Selector, and Service layers as interlocking gears" />

<ul class="checklist">
<li>Service Layers Explained</li>
<li class="current">Separation of Concerns Recap<span class="check"></span></li>
<li>The Unit of Work<span class="check"></span></li>
<li>Service Layer Principles<span class="check"></span></li>
<li>Warehouse Operations App Overview<span class="check"></span></li>
<li>Warehouse Operations App Code<span class="check"></span></li>
<li>Warehouse Operations Agent<span class="check"></span></li>
</ul>

---

<!-- _class: detail-slide diagram-slide layers-diagram-slide -->

# Salesforce Platform Layers

![Five Salesforce layers — Presentation, Integration, Business Logic, Data Access, and Database — each with You define and You code tools](images/salesforce-application-layers.svg?v=purple2)

---

<!-- _class: detail-slide diagram-slide color-key-slide -->

# Apex Enterprise Patterns (fflib) - Color Chart

<div class="color-key-split">
<div class="color-key-cogs">
<img class="color-key-gears" src="images/pattern-layers-gears.svg" alt="Domain, Selector, and Service layers as interlocking gears" />
</div>
<div class="color-key-legends">
<div class="color-key-legend-stack">
<div class="color-key-legend"><span class="swatch swatch-client"></span>Client</div>
<div class="color-key-legend"><span class="swatch swatch-service"></span>Service</div>
<div class="color-key-legend"><span class="swatch swatch-domain"></span>Domain</div>
<div class="color-key-legend"><span class="swatch swatch-trigger"></span>Trigger Handler</div>
<div class="color-key-legend"><span class="swatch swatch-selector"></span>Selector</div>
</div>
</div>
</div>

---

<!-- _class: detail-slide diagram-slide layers-diagram-slide layers-classes-slide -->

# Suggested Class Folder Layout

<div class="soc-layers">
<div class="soc-layer soc-layer-presentation">
<div class="soc-layer-header">Presentation</div>
<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-client">FulfillmentReleaseController.cls</span><span class="vscode-tab vscode-tab-alt vscode-tab-client">WarehouseDispatchController.cls</span><span class="vscode-tab vscode-tab-alt vscode-tab-client">MaintenanceCompleteController.cls</span><span class="vscode-tab vscode-tab-alt vscode-tab-more">…</span></div>
<div class="vscode-pane"><span class="vscode-comment">// /classes/controllers</span></div>
</div>
</div>
<div class="soc-layer soc-layer-integration">
<div class="soc-layer-header">Integration</div>
<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-client">ReleaseOrders.cls</span><span class="vscode-tab vscode-tab-alt vscode-tab-client">DispatchWarehouse.cls</span><span class="vscode-tab vscode-tab-alt vscode-tab-client">FulfillmentResource.cls</span></div>
<div class="vscode-pane"><span class="vscode-comment">// /classes/actions · /classes/restapis</span></div>
</div>
</div>
<div class="soc-layer soc-layer-business">
<span class="soc-layer-heart">❤️</span>
<div class="soc-layer-header">Business Logic</div>
<div class="soc-layer-windows">
<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-service">FulfillmentService.cls</span><span class="vscode-tab vscode-tab-alt vscode-tab-service">DispatchService.cls</span><span class="vscode-tab vscode-tab-alt vscode-tab-service">MaintenanceService.cls</span></div>
<div class="vscode-pane"><span class="vscode-comment">// /classes/services — named for the process</span></div>
</div>
<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-domain">Robots.cls</span><span class="vscode-tab vscode-tab-alt vscode-tab-domain">FulfillmentOrders.cls</span><span class="vscode-tab vscode-tab-alt vscode-tab-domain">FulfillmentLines.cls</span><span class="vscode-tab vscode-tab-alt vscode-tab-more">…</span></div>
<div class="vscode-pane"><span class="vscode-comment">// /classes/domains — named for the object</span></div>
</div>
</div>
</div>
<div class="soc-layer soc-layer-data">
<div class="soc-layer-header">Data Access</div>
<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-selector">RobotsSelector.cls</span><span class="vscode-tab vscode-tab-alt vscode-tab-selector">FulfillmentLinesSelector.cls</span><span class="vscode-tab vscode-tab-alt vscode-tab-selector">WarehousesSelector.cls</span></div>
<div class="vscode-pane"><span class="vscode-comment">// /classes/selectors</span></div>
</div>
</div>
<div class="soc-layer soc-layer-database">
<div class="soc-layer-header">Database</div>
<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-handler">RobotsTriggerHandler.cls</span></div>
<div class="vscode-pane"><span class="vscode-comment">// /classes/triggerHandlers</span></div>
</div>
</div>
</div>

---

<!-- _class: detail-slide diagram-slide -->

# Who can call whom

![Clients call Service and Selector; trigger handlers call Service, Domain, and Selector; Service, Domain, and Selector may compose](images/callers-graphic.svg?v=left10)

---

<!-- _class: detail-slide callers-table-slide -->

# Who can call whom

<table>
<thead>
<tr><th>Caller</th><th><span class="layer-pill layer-pill-service">Service</span></th><th><span class="layer-pill layer-pill-domain">Domain</span></th><th><span class="layer-pill layer-pill-selector">Selector</span></th></tr>
</thead>
<tbody>
<tr><td><span class="layer-pill layer-pill-client">Client</span> (LWC, REST, Flow, Agent, Batch, ...)</td><td>●</td><td></td><td>●</td></tr>
<tr><td><span class="layer-pill layer-pill-handler">Trigger Handler</span></td><td>●</td><td>●</td><td>●</td></tr>
<tr><td><span class="layer-pill layer-pill-service">Service</span></td><td>●</td><td>●</td><td>●</td></tr>
<tr><td><span class="layer-pill layer-pill-domain">Domain</span></td><td></td><td>●</td><td>●</td></tr>
<tr><td><span class="layer-pill layer-pill-selector">Selector</span></td><td></td><td></td><td>●</td></tr>
</tbody>
</table>

---

<!-- _class: detail-slide diagram-slide evolve-slide -->

# How durable is your code when change occurs?

<p class="evolve-subtext">How users interact with your application changes a lot — protect against it with SoC</p>

<div class="evolve-layout">
<div class="evolve-spacer" aria-hidden="true"></div>
<div class="evolve-stack">
<div class="timeline timeline-impact">
<div class="timeline-row">
<span class="t-node">VF</span>
<span class="t-bridge"><span class="t-line"></span><span class="t-icon">🤔</span></span>
<span class="t-node">Aura</span>
<span class="t-bridge"><span class="t-line"></span><span class="t-icon">🤔</span></span>
<span class="t-node">LWC</span>
<span class="t-bridge"><span class="t-line"></span><span class="t-icon">🤔</span></span>
<span class="t-node">Agent Action</span>
<span class="t-bridge"><span class="t-line"></span><span class="t-icon">🤔</span></span>
<span class="t-node">React</span>
<span class="t-bridge"><span class="t-line"></span><span class="t-icon">🤔</span></span>
<span class="t-next-anchor"><span class="t-node t-node-next">Next?</span><span class="evolve-callout"><span class="evolve-caret" aria-hidden="true"></span><span class="info-mark">ⓘ</span><strong>Claudeforce.</strong> Salesforce + Anthropic, August 2026 — yet another interaction layer on your application.</span></span>
</div>
<p class="timeline-legend">🤔 Business Logic Impact</p>
</div>
<div class="vscode evolve-copy">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-client">WarehouseDispatchController.cls</span><span class="vscode-tab vscode-tab-alt vscode-tab-client">DispatchWarehouse.cls</span><span class="vscode-tab vscode-tab-alt vscode-tab-client">FulfillmentReleaseController.cls</span><span class="vscode-tab vscode-tab-alt vscode-tab-client">ReleaseOrders.cls</span></div>
<pre><code>// logic copied — every new client type
VF · Aura · LWC · Agent Action · React · Next?
  └─► WarehouseDispatchController.dispatchWarehouse(...)
  └─► DispatchWarehouse.execute(...)
  └─► FulfillmentReleaseController.releaseOrder(...)
  └─► ReleaseOrders.execute(...)</code></pre>
</div>
<div class="timeline timeline-service">
<div class="timeline-row">
<span class="t-node">VF</span>
<span class="t-bridge t-bridge-heart"><span class="t-line"></span><span class="t-icon">❤️</span></span>
<span class="t-node">Aura</span>
<span class="t-bridge t-bridge-heart"><span class="t-line"></span><span class="t-icon">❤️</span></span>
<span class="t-node">LWC</span>
<span class="t-bridge t-bridge-heart"><span class="t-line"></span><span class="t-icon">❤️</span></span>
<span class="t-node">Agent Action</span>
<span class="t-bridge t-bridge-heart"><span class="t-line"></span><span class="t-icon">❤️</span></span>
<span class="t-node">React</span>
<span class="t-bridge t-bridge-heart"><span class="t-line"></span><span class="t-icon">❤️</span></span>
<span class="t-node">Next?</span>
</div>
</div>
<div class="vscode evolve-services">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-service">DispatchService.cls</span><span class="vscode-tab vscode-tab-alt vscode-tab-service">FulfillmentService.cls</span></div>
<pre><code>// same services — every client type
LWC · REST · Batch · Flow · Agent Action · Next?
  └─► DispatchService.dispatchWarehouses(...)
  └─► FulfillmentService.releaseOrders(...)</code></pre>
</div>
</div>
<div class="evolve-footer">
<p class="evolve-tagline">❤️ Your business logic is <strong>the</strong> most important logic in your app — and when it's everywhere, it becomes a <strong>significant investment risk</strong></p>
</div>
</div>

---

<!-- _class: detail-slide checklist-slide -->

# Service Layers Explained

<img class="checklist-gears" src="images/pattern-layers-gears.svg" alt="Domain, Selector, and Service layers as interlocking gears" />

<ul class="checklist">
<li>Service Layers Explained</li>
<li>Separation of Concerns Recap<span class="check">✅</span></li>
<li class="current">The Unit of Work<span class="check"></span></li>
<li>Service Layer Principles<span class="check"></span></li>
<li>Warehouse Operations App Overview<span class="check"></span></li>
<li>Warehouse Operations App Code<span class="check"></span></li>
<li>Warehouse Operations Agent<span class="check"></span></li>
</ul>

---

<!-- _class: detail-slide -->

# Unit of Work

* [Martin Fowler](https://martinfowler.com/eaaCatalog/unitOfWork.html) — *Patterns of Enterprise Application Architecture*
  * *“Maintains a list of objects affected by a business transaction and coordinates the writing out of changes and the resolution of concurrency problems.”*
* One transaction: work completes or is rolled back explicitly
* Best practices: automatically bulkifies, runs in user mode
* Relationships: built in memory without having to insert parent
* `commitWork()` takes a savepoint and rolls back if anything fails
* In Apex that means: register work now, `commitWork()` once — see [AndyInTheCloud, June 2013](https://andyinthecloud.com/2013/06/09/managing-your-dml-and-transactions-with-a-unit-of-work/)

---

<!-- _class: detail-slide code-slide dense-code-slide -->

# Without Unit Of Work — Lines: 73

<div class="dense-code-split">
<div class="vscode dense-code-full">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-service">Opportunity setup — raw DML</span></div>

```apex lines=1,2,3,4,5,7,8,11,12,13,14,15,17,18,19,20,21,25,26,27,29,30,31,32,33,34,36,38,39,41,42,43,45,46,47,49,50,51,53,54,55,56,57,59,60,61,63,64,65,67,68,69,70,71,72,73
List<Opportunity> opps = new List<Opportunity>();
List<List<Product2>> productsByOpp = new List<List<Product2>>();
List<List<PricebookEntry>> pbesByOpp = new List<List<PricebookEntry>>();
List<List<OpportunityLineItem>> linesByOpp = new List<List<OpportunityLineItem>>();
for (Integer o = 0; o < 10; o++) {
  Opportunity opp = new Opportunity();
  // ... set Name, StageName, CloseDate
  opps.add(opp);
  List<Product2> products = new List<Product2>();
  List<PricebookEntry> pbes = new List<PricebookEntry>();
  List<OpportunityLineItem> lines = new List<OpportunityLineItem>();
  for (Integer i = 0; i < o + 1; i++) {
    Product2 product = new Product2();
    // ... set Name
    products.add(product);
    PricebookEntry pbe = new PricebookEntry();
    // ... set UnitPrice, IsActive, Pricebook2Id
    pbes.add(pbe);
    OpportunityLineItem oli = new OpportunityLineItem();
    // ... set Quantity, TotalPrice
    lines.add(oli);
  }
  productsByOpp.add(products);
  pbesByOpp.add(pbes);
  linesByOpp.add(lines);
}
insert opps;
List<Product2> allProducts = new List<Product2>();
for (List<Product2> products : productsByOpp) {
  allProducts.addAll(products);
}
insert allProducts;
Integer oppIdx = 0;
List<PricebookEntry> allPbes = new List<PricebookEntry>();
for (List<PricebookEntry> pbes : pbesByOpp) {
  List<Product2> products = productsByOpp[oppIdx++];
  Integer lineIdx = 0;
  for (PricebookEntry pbe : pbes) {
    pbe.Product2Id = products[lineIdx++].Id;
  }
  allPbes.addAll(pbes);
}
insert allPbes;
oppIdx = 0;
List<OpportunityLineItem> allLines = new List<OpportunityLineItem>();
for (List<OpportunityLineItem> lines : linesByOpp) {
  List<PricebookEntry> pbes = pbesByOpp[oppIdx];
  Integer lineIdx = 0;
  for (OpportunityLineItem oli : lines) {
    oli.OpportunityId = opps[oppIdx].Id;
    oli.PricebookEntryId = pbes[lineIdx++].Id;
  }
  allLines.addAll(lines);
  oppIdx++;
}
insert allLines;
```

</div>
<div class="dense-code-zooms">
<div class="vscode dense-code-zoom dense-code-zoom-lists">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-service">Zoom · lines 1–4</span></div>

```apex
List<Opportunity> opps = new List<Opportunity>();
List<List<Product2>> productsByOpp = new List<List<Product2>>();
List<List<PricebookEntry>> pbesByOpp = new List<List<PricebookEntry>>();
List<List<OpportunityLineItem>> linesByOpp = new List<List<OpportunityLineItem>>();
```

</div>
<div class="vscode dense-code-zoom dense-code-zoom-stitch">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-service">Zoom · lines 47–56</span></div>

```apex lines=47,49,50,51,53,54,55,56
for (List<PricebookEntry> pbes : pbesByOpp) {
  List<Product2> products = productsByOpp[oppIdx++];
  Integer lineIdx = 0;
  for (PricebookEntry pbe : pbes) {
    pbe.Product2Id = products[lineIdx++].Id;
  }
  allPbes.addAll(pbes);
}
```

</div>
<div class="vscode dense-code-zoom dense-code-zoom-dml">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-service">Zoom · lines 36, 43, 57, 73</span></div>

```apex lines=36,43,57,73
insert opps;
insert allProducts;
insert allPbes;
insert allLines;
```

</div>
<div class="vscode dense-code-zoom dense-code-zoom-txn">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-service">Zoom · Transaction control</span></div>

```apex
Savepoint sp = Database.setSavepoint();
try {
  // ... lists, stitch, four inserts
} catch (Exception e) {
  Database.rollback(sp);
  throw new DispatchServiceException(e.getMessage(), e);
}
```

</div>
</div>
</div>

---

<!-- _class: detail-slide code-slide compact-code-slide uow-interact-slide -->

# With Unit of Work — Lines: 31 (58% ↓)

<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-service">Same work — register, then commit</span></div>

```apex lines=1,2,3,4,5,6,7,8,9,10,13,14,15,16,17,18,19,23,24,25,27,28,29,30,31
fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
  new List<Schema.SObjectType> {
    Product2.SObjectType,
    PricebookEntry.SObjectType,
    Opportunity.SObjectType,
    OpportunityLineItem.SObjectType
  });
for (Integer o = 0; o < 10; o++) {
  Opportunity opp = new Opportunity();
  // ... set Name, StageName, CloseDate
  uow.registerNew(opp);
  for (Integer i = 0; i < o + 1; i++) {
    Product2 product = new Product2();
    product.Name = opp.Name + ' : Product : ' + i;
    uow.registerNew(product);
    PricebookEntry pbe = new PricebookEntry();
    // ... set UnitPrice, IsActive, Pricebook2Id
    uow.registerNew(pbe, PricebookEntry.Product2Id, product);
    OpportunityLineItem oli = new OpportunityLineItem();
    // ... set Quantity, TotalPrice
    uow.registerRelationship(oli, OpportunityLineItem.PricebookEntryId, pbe);
    uow.registerNew(oli, OpportunityLineItem.OpportunityId, opp);
  }
}
uow.commitWork();
```

</div>

---

<!-- _class: detail-slide -->

# fflib_SObjectUnitOfWork Methods

* `fflib_SObjectUnitOfWork(List<SObjectType> types)` — dependency order
* `registerNew(record)` · `registerNew(record, field, parent)`
* `registerRelationship(record, field, related)` — stitch before Ids exist
* `registerDirty(record)` · `registerDeleted(record)`
* `commitWork()` — savepoint, bulk DML, rollback, rethrow
* Other methods: `registerWork`, `registerUpsert`, `registerEmail` …

---

<!-- _class: detail-slide checklist-slide -->

# Service Layers Explained

<img class="checklist-gears" src="images/pattern-layers-gears.svg" alt="Domain, Selector, and Service layers as interlocking gears" />

<ul class="checklist">
<li>Service Layers Explained</li>
<li>Separation of Concerns Recap<span class="check">✅</span></li>
<li>The Unit of Work<span class="check">✅</span></li>
<li class="current">Service Layer Principles<span class="check"></span></li>
<li>Warehouse Operations App Overview<span class="check"></span></li>
<li>Warehouse Operations App Code<span class="check"></span></li>
<li>Warehouse Operations Agent<span class="check"></span></li>
</ul>

---

<!-- _class: detail-slide service-conductor-slide -->

# Service ➡️ Task Orientated Logic

* A Service represents a **feature** of the application
  * Fulfillment — `FulfillmentService.cls`
  * Dispatch — `DispatchService.cls`
  * Maintenance — `MaintenanceService.cls`
* Each method is a **task** within that feature — `releaseOrders`, `dispatchWarehouses`, `completeLines`
* Think of it as the **conductor** — the band handles querying and object-specific logic; the Service sets the tempo and the rules of the orchestration

<div class="conductor-graphic">
  <img src="images/service-conductor-band.png" alt="A conductor in front of a band — the Service sets the tempo; querying and object-specific logic play behind" />
  <p class="conductor-caption"><span>Tasks in front</span><span>Service — the conductor</span><span>The band — querying and object-specific logic</span></p>
</div>

---

<!-- _class: detail-slide diagram-slide -->

# Services have many Consumers

![Hub and spoke: UI controllers, web and REST services, invocable methods, agent actions, email, batch, scheduled, and queueable all call one Apex Service](images/apex-service-entry-points.svg)

---

<!-- _class: detail-slide promises-slide -->

# Service ☑️ Checklist

* Client-agnostic inputs and outputs
  * ✅ `dispatchWarehouses(Set<Id> warehouseIds)`
  * ❌ `dispatch(DispatchForm form)`
* Client-agnostic exceptions
  * ✅ `throw DispatchServiceException`
  * ❌ `throw AuraHandledException`
* **Bulkification** — collections in and out; don't force callers to loop
  * ✅ `dispatchWarehouses(Set<Id> warehouseIds)`
  * ❌ `dispatchWarehouse(Id warehouseId)` only
* **Transactions** — one UOW; rollback; Service→Service passes the outer uow
* **Security** — enforce user-mode in DML (UOW) and SOQL (Selector)

---

<!-- _class: detail-slide promises-slide service-evolution-slide -->

# Service 🔁 Evolution

* **Services** — now prefer instance methods over static
  * ✅ `DispatchService.newInstance().dispatchWarehouses(...)` — reduces boilerplate to support mocking, better alignment with Apex Stubs requirements
  * ❌ `public static void dispatchWarehouses(...)`
* **Apex interfaces** — now recommended only for dependency injection
  * ✅ `IDispatchService` use when decoupling implementation e.g. packaging *
  * ❌ `IFulfillmentService` / `IMaintenanceService` on every service by default
* **Application class** — optional; mocking can be done without it — <a href="https://andyinthecloud.com/2026/04/13/apex-enterprise-patterns-recent-updates-and-thoughts-on-the-application-class/">blog</a>
  * Demonstrated in this sample code via constructor and property injection

<p class="session-callout"><span class="info-mark">ⓘ</span> * <strong>Session #6</strong> — Enterprise-Scale Apex Across Multiple Packages.<span class="session-callout-sub">Metadata driven Dependency Injection (DI) and Apex Interfaces for resolving Services implementations will be covered in this session.</span></p>

---

<!-- _class: detail-slide diagram-slide -->

# Service - Consumers and Dependencies

![Controller, REST, Invocable, Queueable, and other callers call the Service; the Service reuses Domain and Selector](images/service-consumers-dependencies.svg)

---

<!-- _class: detail-slide diagram-slide uow-service-slide -->

# Service - Leveraging Unit of Work

![Service method creates a Unit of Work, registers work, commits once; services share the outer instance](images/uow-in-service.svg?v=align1)

<div class="uow-callout">
<span class="info-mark">ⓘ</span><strong>If calling between services.</strong>
Pass the outer Unit of Work as a parameter. Do not create a new one. Aim for one Unit of Work per request.
</div>

---

<!-- _class: detail-slide checklist-slide -->

# Service Layers Explained

<img class="checklist-gears" src="images/pattern-layers-gears.svg" alt="Domain, Selector, and Service layers as interlocking gears" />

<ul class="checklist">
<li>Service Layers Explained</li>
<li>Separation of Concerns Recap<span class="check">✅</span></li>
<li>The Unit of Work<span class="check">✅</span></li>
<li>Service Layer Principles<span class="check">✅</span></li>
<li class="current">Warehouse Operations App Overview<span class="check"></span></li>
<li>Warehouse Operations App Code<span class="check"></span></li>
<li>Warehouse Operations Agent<span class="check"></span></li>
</ul>

---

<!-- _class: detail-slide warehouse-ops-slide -->

# Warehouse Operations App

* The operations app for a warehouse that uses robots
* Release pick work, dispatch idle robots, take a worn one into maintenance
* The sample is the **desk**, not the robot brain
* Improve sample clarity between service vs domain
  * `DispatchService` — a process
  * `Robots` — an object
* Leverages multiple clients, LWC, REST API, Batch and AI

<img class="ops-loop" src="images/warehouse-ops-loop.svg?v=loop3" alt="Boxes in, robots pick, truck ships, then the next order" />

---

<!-- _class: detail-slide sample-code-slide desk-slide -->

# Warehouse App Tabs

<div class="sample-code-layout desk-grid">
<img src="images/demo-north-hub-clip.png" alt="North Hub warehouse record with Dispatch actions" />
<img src="images/demo-ember-clip.png" alt="Ember robot — Idle, Warning, 79 percent wear, 39 hours" />
<img src="images/demo-fo-00000-clip.png" alt="FO-00001 details — Draft, ready to release" />
<img src="images/demo-fo-00001-clip.png" alt="FO-00001 related — three pending pick lines" />
</div>

---

<!-- _class: detail-slide diagram-slide -->

# Warehouse App Objects

![Warehouse, Robot Model, Robot, Fulfillment Order, Fulfillment Line, Maintenance Job](images/manufacturing-erd.svg)

---

<!-- _class: detail-slide diagram-slide app-process-slide -->

# Warehouse App Processes
## North Hub Warehouse Fulfillment

![Put work on the floor, put robots on that work, finish the picks, put Ember back](images/north-hub-journey.svg?v=ends4)

---

<!-- _class: detail-slide checklist-slide -->

# Service Layers Explained

<img class="checklist-gears" src="images/pattern-layers-gears.svg" alt="Domain, Selector, and Service layers as interlocking gears" />

<ul class="checklist">
<li>Service Layers Explained</li>
<li>Separation of Concerns Recap<span class="check">✅</span></li>
<li>The Unit of Work<span class="check">✅</span></li>
<li>Service Layer Principles<span class="check">✅</span></li>
<li>Warehouse Operations App Overview<span class="check">✅</span></li>
<li class="current">Warehouse Operations App Code<span class="check"></span></li>
<li>Warehouse Operations Agent<span class="check"></span></li>
</ul>

---

<!-- _class: detail-slide diagram-slide app-class-model-slide -->

# Warehouse App Classes

<img class="layer-key" src="images/layer-key.svg?v=h2" alt="Client, Service, Domain, Trigger Handler, Selector" />

![Clients call services; services call domains and selectors](images/warehouse-class-model.svg?v=9)

---

<!-- _class: detail-slide diagram-slide -->

# North Hub Warehouse Fulfillment

![Release, Dispatch, Complete Lines, and Complete Maintenance with the classes behind each click](images/north-hub-journey-classes.svg?v=feet11)

<img class="layer-key" src="images/layer-key.svg?v=h1" alt="Client, Service, Domain, Trigger Handler, Selector" />

---

<!-- _class: detail-slide code-slide pair-code-slide lwc-service-call-slide -->

# LWC calling the service

<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-client">WarehouseDispatchController.cls</span></div>

```apex
public inherited sharing class WarehouseDispatchController {

  private DispatchService dispatchSvc = /* constructor initialized */;

  @AuraEnabled(cacheable=false)
  public static void dispatchWarehouse(Id warehouseId) {
    new WarehouseDispatchController().handleDispatchWarehouse(warehouseId);
  }

  public void handleDispatchWarehouse(Id warehouseId) {
    try {
      dispatchSvc.dispatchWarehouses(new Set<Id>{ warehouseId });
    } catch (Exception e) {
      throw toAura(e);
    }
  }

  private static AuraHandledException toAura(Exception e) {
    AuraHandledException auraException = new AuraHandledException(e.getMessage());
    auraException.setMessage(e.getMessage());
    return auraException;
  }
}
```

</div>

---

<!-- _class: detail-slide code-slide pair-code-slide batch-service-call-slide -->

# Batch calling the service

<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-client">DispatchPendingJob.cls</span></div>

```apex
public inherited sharing class DispatchPendingJob
    implements System.Schedulable, Database.Batchable<SObject>, Database.Stateful {

  private WarehousesSelector warehouseSelector = /* constructor initialized */;
  private DispatchService dispatchSvc = /* constructor initialized */;

  public Database.QueryLocator start(Database.BatchableContext context) {
    return warehouseSelector.selectActiveAsQueryLocator();
  }

  public void execute(Database.BatchableContext context, List<Warehouse__c> warehouses) {
    try {
      dispatchSvc
          .dispatchWarehouses(new Map<Id, Warehouse__c>(warehouses).keySet());
    } catch (Exception e) {
      jobErrors.add(/* JobError */);
    }
  }

  public void finish(Database.BatchableContext context) { /* email JobErrors */ }
}
```

</div>

---

<!-- _class: detail-slide code-slide pair-code-slide rest-service-calls-slide -->

# REST calling the service

<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-client">FulfillmentResource.cls</span></div>

```apex
@HttpPost
global static void post() {
  new FulfillmentResource().handlePost();
}

public void handlePost() {
  Request body = (Request) JSON.deserialize(
      RestContext.request.requestBody.toString(), Request.class);
  String action = /* last URI segment */;
  switch on action {
    when 'release' {
      fulfillmentSvc
          .releaseOrders(new Set<Id>(body.orderIds));
    }
    when 'dispatch' {
      dispatchSvc
          .dispatchWarehouses(new Set<Id>(body.warehouseIds));
    }
    when 'complete' {
      fulfillmentSvc
          .completeLines(new Set<Id>(body.lineIds));
    }
  }
}
```

</div>

---

<!-- _class: detail-slide code-slide pair-code-slide action-service-call-slide -->

# Actions calling the service

<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-client">DispatchWarehouse.cls</span></div>

```apex
@InvocableMethod(
  label='Dispatch Warehouse'
  category='Warehouse Operations')
public static List<Result> execute(List<Request> requests) {
  return new DispatchWarehouse().handleExecute(requests);
}

public List<Result> handleExecute(List<Request> requests) {
  Set<Id> warehouseIds = new Set<Id>();
  for (Request request : requests) {
    warehouseIds.add(/* resolve request.warehouseName */);
  }
  dispatchSvc.dispatchWarehouses(warehouseIds);
  List<Result> results = new List<Result>();
  for (Request request : requests) {
    Result result = new Result();
    result.warehouseName = request.warehouseName;
    result.warehouseId = /* resolved Id */;
    results.add(result);
  }
  return results;
}
```

</div>

---

<!-- _class: detail-slide diagram-slide walkthrough-consumers-slide -->

# DispatchService - Consumers and Dependencies

![WarehouseDispatchController, FulfillmentResource, DispatchWarehouse, and DispatchPendingJob call DispatchService; DispatchService reuses Robots, FulfillmentLines, FulfillmentOrders, and their selectors](images/service-consumers-dependencies-walkthrough.svg?v=reuses1)

<img class="layer-key" src="images/layer-key.svg?v=h1" alt="Client, Service, Domain, Trigger Handler, Selector" />

---

<!-- _class: detail-slide pair-code-slide service-ide-slide -->

# DispatchService.dispatchWarehouses

<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-service">DispatchService.dispatchWarehouses</span></div>
<div class="vscode-prose">
<p class="walk-sig walk-sig-start"><span class="walk-kw">public virtual void</span> dispatchWarehouses(Set&lt;Id&gt; warehouseIds) {</p>

1. <span class="walk-layer walk-layer-service">Service</span> — `UnitOfWork.newInstance()`
2. <span class="walk-layer walk-layer-selector">Selector</span> — pending unassigned lines at the warehouses
3. <span class="walk-layer walk-layer-selector">Selector</span> — idle robots at the warehouses
4. <span class="walk-layer walk-layer-domain">Domain</span> — `Robots.getAvailableForWork()` (not Critical, wear &lt; 90, batt &gt; 20)
5. <span class="walk-layer walk-layer-service">Service</span> — `match` (per warehouse, line weight vs robot max load)
6. <span class="walk-layer walk-layer-domain">Domain</span> — `Robots.startWork(uow)` &gt; `FulfillmentLines.assign(robotIdByLineId, uow)` &gt; `FulfillmentOrders.markInProgress(uow)`
7. <span class="walk-layer walk-layer-service">Service</span> — `uow.commitWork()`

<p class="walk-sig walk-sig-end">}</p>
</div>
</div>

---

<!-- _class: detail-slide code-slide pair-code-slide service-ide-slide dispatch-gutter-slide -->

# DispatchService.dispatchWarehouses

<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-service">DispatchService.dispatchWarehouses</span></div>

```apex
public virtual inherited sharing class DispatchService {

  private FulfillmentLinesSelector lineSelector = /* constructor initialized */;
  private RobotsSelector robotSelector = /* constructor initialized */;
  private FulfillmentOrdersSelector orderSelector = /* constructor initialized */;

  public virtual void dispatchWarehouses(Set<Id> warehouseIds) {
    fflib_SObjectUnitOfWork uow = UnitOfWork.newInstance();

    List<FulfillmentLine__c> pending =
        lineSelector.selectPendingUnassignedByWarehouseWithOrder(warehouseIds);
    List<Robot__c> idle =
        robotSelector.selectIdleByWarehouseWithModel(warehouseIds);

    List<Robot__c> available = Robots.newInstance(idle).getAvailableForWork();
    Map<Id, Id> robotIdByLineId = match(pending, available);
    Robots.newInstance(robotsToStart).startWork(uow);
    FulfillmentLines.newInstance(linesToAssign).assign(robotIdByLineId, uow);
    FulfillmentOrders.newInstance(released).markInProgress(uow);

    uow.commitWork();
  }
}
```

</div>

---

<!-- _class: detail-slide code-slide pair-code-slide service-ide-slide uow-wrapper-slide -->

# The app wrapper — UnitOfWork.cls

<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-service">UnitOfWork.cls</span></div>

```apex
@TestVisible
private static fflib_SObjectUnitOfWork mock;

public static fflib_SObjectUnitOfWork newInstance() {
  if (mock != null) {
    return mock;
  }
  return new fflib_SObjectUnitOfWork(
    new List<SObjectType>{
      Warehouse__c.SObjectType,
      RobotModel__c.SObjectType,
      Robot__c.SObjectType,
      FulfillmentOrder__c.SObjectType,
      FulfillmentLine__c.SObjectType,
      MaintenanceJob__c.SObjectType
    },
    new fflib_SObjectUnitOfWork.UserModeDML()
  );
}
```

</div>

---

<!-- _class: detail-slide pair-code-slide complete-lines-walk-slide service-ide-slide -->

# FulfillmentService.completeLines

<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-service">FulfillmentService.completeLines</span></div>
<div class="vscode-prose">
<p class="walk-sig walk-sig-start"><span class="walk-kw">public virtual void</span> completeLines(Set&lt;Id&gt; lineIds) {</p>

1. <span class="walk-layer walk-layer-service">Service</span> — `UnitOfWork.newInstance()`
2. <span class="walk-layer walk-layer-selector">Selector</span> — lines by Id (`lineIds`)
3. <span class="walk-layer walk-layer-domain">Domain</span> — `FulfillmentLines.complete(uow)` · hours by assigned robot
4. <span class="walk-layer walk-layer-selector">Selector</span> — robots with model (`hoursByRobotId`)
5. <span class="walk-layer walk-layer-domain">Domain</span> — `Robots.goIdle(uow)` · `applyWear(uow)`
6. <span class="walk-layer walk-layer-selector">Selector</span> — parent orders with every sibling line
7. <span class="walk-layer walk-layer-domain">Domain</span> — `FulfillmentOrders.complete(uow, lineIds)` · `Robots.getDueForService()`
8. <span class="walk-layer walk-layer-service">Service</span> — `MaintenanceService.scheduleService(dueRobots, uow)`
9. <span class="walk-layer walk-layer-service">Service</span> — `uow.commitWork()`

<p class="walk-sig walk-sig-end">}</p>
</div>
</div>

---

<!-- _class: detail-slide code-slide pair-code-slide service-hop-slide service-ide-slide -->

# Service calling service — one outer UoW

<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-service">FulfillmentService.completeLines</span></div>

```apex
public virtual void completeLines(List<FulfillmentLine__c> lines) {
  fflib_SObjectUnitOfWork uow = UnitOfWork.newInstance();

  FulfillmentLines fulfillmentLines = FulfillmentLines.newInstance(lines);
  fulfillmentLines.complete(uow);
  Map<Id, Decimal> hoursByRobotId =
      fulfillmentLines.getEstimatedHoursByAssignedRobotId();
  List<Robot__c> robotRecords =
      robotSelector.selectByIdWithModel(hoursByRobotId.keySet());
  Robots robots = Robots.newInstance(robotRecords);
  robots.goIdle(uow); robots.applyWear(hoursByRobotId, uow);

  List<FulfillmentOrder__c> orders = orderSelector.selectByIdWithLines(orderIds);
  FulfillmentOrders.newInstance(orders).complete(uow, lineIds);

  Set<Robot__c> dueRobots = robots.getDueForService();
  if (!dueRobots.isEmpty()) {
    maintenanceSvc.scheduleService(dueRobots, uow); // same uow
  }

  uow.commitWork();
}
```

</div>

---

<!-- _class: detail-slide checklist-slide -->

# Service Layers Explained

<img class="checklist-gears" src="images/pattern-layers-gears.svg" alt="Domain, Selector, and Service layers as interlocking gears" />

<ul class="checklist">
<li>Service Layers Explained</li>
<li>Separation of Concerns Recap<span class="check">✅</span></li>
<li>The Unit of Work<span class="check">✅</span></li>
<li>Service Layer Principles<span class="check">✅</span></li>
<li>Warehouse Operations App Overview<span class="check">✅</span></li>
<li>Warehouse Operations App Code<span class="check">✅</span></li>
<li class="current">Warehouse Operations Agent<span class="check"></span></li>
</ul>

---

<!-- _class: detail-slide diagram-slide agent-actions-slide -->

# Warehouse Agent Actions

<div class="agent-call-row">
  <div class="agent-call-agent">
    <span class="agent-call-emoji">🤖</span>
    <span class="agent-call-name">Warehouse Fulfillment</span>
  </div>
  <div class="agent-call-pairs">
    <div class="agent-call-pair agent-call-headings">
      <div class="agent-call-heading">Actions</div>
      <div></div>
      <div class="agent-call-heading">Services</div>
    </div>
    <div class="agent-call-pair is-mapped">
      <div class="vscode-tabs"><span class="vscode-tab vscode-tab-client">GetWarehouseDesk.cls</span></div>
      <div class="agent-call-link" aria-hidden="true"></div>
      <div class="vscode-tabs"><span class="vscode-tab vscode-tab-service">WarehouseService.cls</span></div>
    </div>
    <div class="agent-call-pair">
      <div class="vscode-tabs"><span class="vscode-tab vscode-tab-client">CreateRobot (Flow)</span></div>
      <div class="agent-call-link" aria-hidden="true"></div>
      <div></div>
    </div>
    <div class="agent-call-pair is-mapped">
      <div class="vscode-tabs"><span class="vscode-tab vscode-tab-client">ReleaseOrders.cls</span></div>
      <div class="agent-call-link" aria-hidden="true"></div>
      <div class="vscode-tabs"><span class="vscode-tab vscode-tab-service">FulfillmentService.cls</span></div>
    </div>
    <div class="agent-call-pair is-mapped">
      <div class="vscode-tabs"><span class="vscode-tab vscode-tab-client">DispatchWarehouse.cls</span></div>
      <div class="agent-call-link" aria-hidden="true"></div>
      <div class="vscode-tabs"><span class="vscode-tab vscode-tab-service">DispatchService.cls</span></div>
    </div>
    <div class="agent-call-pair is-mapped">
      <div class="vscode-tabs"><span class="vscode-tab vscode-tab-client">CompleteFulfillmentLines.cls</span></div>
      <div class="agent-call-link" aria-hidden="true"></div>
      <div class="vscode-tabs"><span class="vscode-tab vscode-tab-service">FulfillmentService.cls</span></div>
    </div>
    <div class="agent-call-pair is-mapped">
      <div class="vscode-tabs"><span class="vscode-tab vscode-tab-client">CompleteMaintenance.cls</span></div>
      <div class="agent-call-link" aria-hidden="true"></div>
      <div class="vscode-tabs"><span class="vscode-tab vscode-tab-service">MaintenanceService.cls</span></div>
    </div>
  </div>
</div>

---

<!-- _class: detail-slide diagram-slide agent-shot-slide -->

# Warehouse Agent

![Warehouse Fulfillment agent on the Robots list — Atlas, Bolt, and Ember idle at North Hub](images/agentstart.png)

---

<!-- _class: detail-slide diagram-slide agent-shot-slide -->

# Warehouse Agent deploying Robots!

![Warehouse Fulfillment after one North Hub run — eight North Spare robots created, drafts released, one dispatch](images/agentcomplete.png)

---

<!-- _class: detail-slide checklist-slide -->

# Service Layers Explained

<img class="checklist-gears" src="images/pattern-layers-gears.svg" alt="Domain, Selector, and Service layers as interlocking gears" />

<ul class="checklist">
<li>Service Layers Explained</li>
<li>Separation of Concerns Recap<span class="check">✅</span></li>
<li>The Unit of Work<span class="check">✅</span></li>
<li>Service Layer Principles<span class="check">✅</span></li>
<li>Warehouse Operations App Overview<span class="check">✅</span></li>
<li>Warehouse Operations App Code<span class="check">✅</span></li>
<li>Warehouse Operations Agent<span class="check">✅</span></li>
</ul>

---

<!-- _class: detail-slide series-slide -->

# What's next in the series

<table>
<thead>
<tr><th></th><th>Session</th></tr>
</thead>
<tbody>
<tr class="done"><td><span class="check">✅</span></td><td>Session #1 - Separation of Concerns in Apex: Why Your Future Self Will Thank You</td></tr>
<tr class="done"><td><span class="check">✅</span></td><td>Session #2 - Service Layers Explained: Coordinating Business Logic in Apex</td></tr>
<tr class="current"><td><span class="check"></span></td><td>Session #3 - Domain vs Service: Where Should Your Apex Logic Live?</td></tr>
<tr><td><span class="check"></span></td><td>Session #4 - Query Logic as a First-Class Architecture Concern</td></tr>
<tr><td><span class="check"></span></td><td>Session #5 - Mocking in Apex: Why It Changes Everything</td></tr>
<tr><td><span class="check"></span></td><td>Session #6 - Enterprise-Scale Apex Across Multiple Packages</td></tr>
</tbody>
</table>

---

<!-- _class: title-slide -->

# Thank you!

#### Andrew Fawcett · Code With Sally
### FFLib Series · Session 002

![Code With Sally](images/codewithsally.png)

