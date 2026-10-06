---
marp: true
theme: session
paginate: true
lang: en
html: true
---

<!-- _class: title-slide -->

# Query Logic as a First-Class Architecture Concern
### The Selector Pattern in Apex
#### FFLib Series · Session 004

#### John Storey
###### Staff Software Engineer · Thrivent

![Code With Sally](images/codewithsally.png)

<!--
- Sally reads the bio
- Thank Sally, Andy, JD
- Straight to the problem
-->

---

<!-- _class: detail-slide about-slide -->

<div class="about-split">
<div class="about-copy">

# About me

##### Staff Software Engineer | Thrivent | Apex Enterprise Patterns maintainer

* **Apex Enterprise Patterns** — a maintainer of fflib, the library this series is built on
* **FinancialForce roots** — helped build fflib in the mid-2010s, alongside Andy Fawcett, John Daniel ("JD") and others

<!-- -->

* When I'm not working in the IT cloud, I'm flying above the real ones as a general aviation pilot.

</div>
<div class="about-aside">
<div class="about-logo-wrap">
<img src="images/thrivent-logo.jpg" alt="Thrivent" />
</div>
<a class="about-book">
<img src="images/john-storey-headshot.png" alt="John Storey" />
</a>
</div>
</div>

<!--
- Brief: bio just read
-->

---

<!-- _class: detail-slide series-slide -->

# FFLib Series

<table>
<thead>
<tr><th></th><th>Session</th></tr>
</thead>
<tbody>
<tr class="done"><td><span class="check">✅</span></td><td>Session #1 — Separation of Concerns in Apex: Why Your Future Self Will Thank You</td></tr>
<tr class="done"><td><span class="check">✅</span></td><td>Session #2 — Service Layers Explained: Coordinating Business Logic in Apex</td></tr>
<tr class="done"><td><span class="check">✅</span></td><td>Session #3 — Domain vs Service: Where Should Your Apex Logic Live?</td></tr>
<tr class="current"><td><span class="check"></span></td><td>Session #4 — Query Logic as a First-Class Architecture Concern</td></tr>
<tr><td><span class="check"></span></td><td>Session #5 — Mocking in Apex: Why It Changes Everything · Oct 20</td></tr>
<tr><td><span class="check"></span></td><td>Session #6 — Enterprise-Scale Apex Across Multiple Packages · Nov 3</td></tr>
</tbody>
</table>

<!--
- Session 4 of 6
- #5 Mocking, Oct 20
- #6 AT4DX, Nov 3
-->

---

<!-- _class: detail-slide checklist-slide -->

# Agenda

<img class="checklist-gears" src="images/pattern-layers-gears.svg" alt="Domain, Selector, and Service layers as interlocking gears" />

<ul class="checklist">
<li>Query Logic</li>
<li class="current">Recap<span class="check"></span></li>
<li>Why Query Logic Matters<span class="check"></span></li>
<li>Selector Principles<span class="check"></span></li>
<li>The fflib Selector<span class="check"></span></li>
<li>Warehouse App Selectors<span class="check"></span></li>
<li>Selector Evolution<span class="check"></span></li>
</ul>

<!--
- Pattern → fflib → Warehouse
- Two question pauses
-->

---

<!-- _class: detail-slide callers-table-slide -->

# Recap: bricks, a conductor, and who calls whom

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

<!--
- Service = conductor, owns UoW
- Domain = Lego brick
- Selector: dot on every row
-->

---

<!-- _class: detail-slide promises-slide compact-code-slide tabs-slide deploy-slide -->

# Demo: deploy fflib and the app

* **① Apex Mocks, ② Apex Common, ③ the Warehouse app (`force-app`)** — the app needs both
* **A source deploy, not a package install** — each `sf project deploy start` runs from inside its own repo
* **Everything is in the session README** — github.com/CodeWithSally/CodeWithSally-Apex-English → Sessions/FFLibSeries/Session004…

<div class="vscode terminal">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-selector">① Apex Mocks</span><span class="vscode-tab vscode-tab-selector">② Apex Common</span><span class="vscode-tab vscode-tab-selector">③ Warehouse app</span></div>
<div class="tab-panes">
<div class="tab-pane" data-marpit-fragment="1">
<p class="pane-caption">① Apex Mocks</p>

```bash
cd /tmp/fflib-apex-mocks
sf project deploy start --source-dir sfdx-source/apex-mocks \
  --target-org session004-mfg --wait 15
```

</div>
<div class="tab-pane" data-marpit-fragment="2">
<p class="pane-caption">② Apex Common</p>

```bash
cd /tmp/fflib-apex-common
sf project deploy start --source-dir sfdx-source/apex-common \
  --target-org session004-mfg --wait 20 --ignore-warnings
```

</div>
<div class="tab-pane" data-marpit-fragment="3">
<p class="pane-caption">③ The Warehouse app</p>

```bash
cd Sessions/FFLibSeries/Session004_QueryLogicAsFirstClassArchitectureConcern
sf project deploy start --source-dir force-app \
  --target-org session004-mfg --wait 15 --ignore-errors
```

</div>
</div>
</div>

<!--
- README beside terminal
- Click: ① ② ③
- --ignore-warnings: compile noise
- --ignore-errors: agent, move on
- Common = base library
-->

---

<!-- _class: detail-slide promises-slide -->

# Good SOQL habits

* **No SOQL (or DML) inside loops**
  * ❌ `for (Id lineId : lineIds) { [SELECT … WHERE Id = :lineId]; }`
  * ✅ One query with `WHERE Id IN :lineIds`, then work from a `Map`
* **Index loops, size cached** — about 2× faster than for-each: ≈500 ms against ≈1,000 ms of CPU over 200,000 integers, measured in our org
* **Bind variables**, never joined-in user input
* **Select only the fields you need; filter on indexed fields**
* **Bound your results** — `LIMIT`, a QueryLocator, or a cursor; mind the 50,000-row limit

<!--
- One-minute PSA
- Cached index loop ≈ 2×
- Binds stop injection
- Null vs empty: contract
- Date literals: user TZ
-->

---

<!-- _class: detail-slide code-slide duo-slide drift-slide -->

# What's wrong with this picture?

<div class="duo">
<div class="duo-col">
<p class="dev-caption">👤 Developer "A" — the desk's LWC controller</p>
<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-client">WarehouseDeskController.cls</span></div>

```apex
Map<Id, FulfillmentLine__c> pending =
  new Map<Id, FulfillmentLine__c>([
  SELECT Id, Name, ProductSku__c, Quantity__c
  FROM FulfillmentLine__c
  WHERE Status__c = 'Pending'
    AND FulfillmentOrder__r.Warehouse__c = :warehouseId
]);
```

</div>
</div>
<div class="duo-col">
<p class="dev-caption">👤 Developer "B" — the dispatch batch</p>
<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-client">DispatchLinesJob.cls</span></div>

```apex
List<FulfillmentLine__c> pending = [
  SELECT Id, WeightKg__c, AssignedRobot__c
  FROM FulfillmentLine__c
  WHERE Status__c = 'Pending'
    AND AssignedRobot__c = null
    AND FulfillmentOrder__r.Warehouse__c IN :warehouseIds
    AND FulfillmentOrder__r.Status__c
        IN ('Released', 'InProgress')
  WITH SYSTEM_MODE
  ORDER BY Name
];
```

</div>
</div>
</div>

<div class="drift drift-meaning" data-marpit-fragment="1"><span class="drift-band" style="left:657px;top:269px;width:544px;height:16px"></span><span class="drift-band" style="left:657px;top:301px;width:544px;height:31px"></span><span class="drift-badge" style="left:1170px;top:277px">1</span><span class="drift-badge" style="left:1170px;top:316.5px">1</span><svg class="drift-arrow" viewBox="0 0 1280 720"><path class="line" pathLength="1" d="M1090 398 C1100 375 1100 355 1088 337"/><path class="head" d="M1088.0 337.0 L1098.5 342.0 L1088.6 348.6Z"/></svg><div class="drift-bubble" style="left:760px;top:398px;width:430px;transform-origin:top right"><b><span class="drift-num">1</span>Meaning</b>B skips lines already assigned to a robot, and orders that are Draft or On Hold. A selects them all.</div></div>
<div class="drift drift-security" data-marpit-fragment="2"><span class="drift-band" style="left:657px;top:332px;width:544px;height:16px"></span><span class="drift-badge" style="left:1170px;top:340px">2</span><svg class="drift-arrow" viewBox="0 0 1280 720"><path class="line" pathLength="1" d="M960 420 C985 380 900 340 836 340"/><path class="head" d="M836.0 340.0 L846.0 334.0 L846.0 346.0Z"/></svg><div class="drift-bubble" style="left:760px;top:420px;width:430px;transform-origin:top center"><b><span class="drift-num">2</span>Security mode</b>B elevates to <code>SYSTEM_MODE</code>. A takes the class default: user mode at API 67.0.</div></div>
<div class="drift drift-order" data-marpit-fragment="3"><span class="drift-band" style="left:657px;top:348px;width:544px;height:16px"></span><span class="drift-badge" style="left:1170px;top:356px">3</span><svg class="drift-arrow" viewBox="0 0 1280 720"><path class="line" pathLength="1" d="M930 440 C950 395 880 356 812 356"/><path class="head" d="M812.0 356.0 L822.0 350.0 L822.0 362.0Z"/></svg><div class="drift-bubble" style="left:760px;top:440px;width:430px;transform-origin:top center"><b><span class="drift-num">3</span>Order</b>B sorts by Name, though dispatch's rule is High priority first. A has no order at all.</div></div>
<div class="drift drift-shape" data-marpit-fragment="4"><span class="drift-band" style="left:72px;top:206px;width:544px;height:47px"></span><span class="drift-band" style="left:657px;top:206px;width:544px;height:31px"></span><span class="drift-badge" style="left:588px;top:229.5px">4</span><span class="drift-badge" style="left:1170px;top:221.5px">4</span><svg class="drift-arrow" viewBox="0 0 1280 720"><path class="line" pathLength="1" d="M480 372 C560 360 580 300 572 258"/><path class="head" d="M572.0 258.0 L579.8 266.7 L568.0 268.9Z"/><path class="line" pathLength="1" d="M552 400 C640 400 600 221 654 221"/><path class="head" d="M654.0 221.0 L644.0 227.0 L644.0 215.0Z"/></svg><div class="drift-bubble" style="left:100px;top:372px;width:452px;transform-origin:top right"><b><span class="drift-num">4</span>Shape</b>A builds a <code>Map</code>, B a <code>List</code>, with different fields. A caller can't switch queries, and a missing field only fails at runtime.</div></div>
<div class="drift drift-magic" data-marpit-fragment="5"><span class="drift-band drift-band-token" style="left:868px;top:317px;width:101px;height:16px"></span><span class="drift-badge" style="left:977px;top:325px">5</span><svg class="drift-mark" viewBox="0 0 1280 720"><path class="squiggle" pathLength="1" d="M872 336 Q874.0 333.8 876 336 Q878.0 338.2 880 336 Q882.0 333.8 884 336 Q886.0 338.2 888 336 Q890.0 333.8 892 336 Q894.0 338.2 896 336 Q898.0 333.8 900 336 Q902.0 338.2 904 336 Q906.0 333.8 908 336 Q910.0 338.2 912 336 Q914.0 333.8 916 336 Q918.0 338.2 920 336 Q922.0 333.8 924 336 Q926.0 338.2 928 336 Q930.0 333.8 932 336 Q934.0 338.2 936 336 Q938.0 333.8 940 336 Q942.0 338.2 944 336 Q946.0 333.8 948 336 Q950.0 338.2 952 336 Q954.0 333.8 956 336 Q958.0 338.2 960 336 Q962.0 333.8 964 336"/></svg><svg class="drift-arrow" viewBox="0 0 1280 720"><path class="line" pathLength="1" d="M1010 410 C1020 380 990 350 930 341"/><path class="head" d="M930.0 341.0 L940.8 336.5 L939.0 348.4Z"/></svg><div class="drift-bubble" style="left:760px;top:410px;width:430px;transform-origin:top center"><b><span class="drift-num">5</span>Magic strings</b><code>'InProgress'</code> matches nothing: the status is <code>'In Progress'</code>. It compiles, runs, and quietly returns fewer lines.</div></div>

<!--
- Same question, twice
- Both compile; both drift
- Illustrative, not app code
- Click five callouts
- Shape → slide 30
-->

---

<!-- _class: detail-slide checklist-slide -->

# Agenda

<img class="checklist-gears" src="images/pattern-layers-gears.svg" alt="Domain, Selector, and Service layers as interlocking gears" />

<ul class="checklist">
<li>Query Logic</li>
<li>Recap<span class="check">✅</span></li>
<li class="current">Why Query Logic Matters<span class="check"></span></li>
<li>Selector Principles<span class="check"></span></li>
<li>The fflib Selector<span class="check"></span></li>
<li>Warehouse App Selectors<span class="check"></span></li>
<li>Selector Evolution<span class="check"></span></li>
</ul>

---

<!-- _class: detail-slide promises-slide -->

# Where the pattern comes from

* **In a nutshell:** Selectors encapsulate query logic: one home for every question asked of the database
* **Data Mapper** (Fowler, *Patterns of Enterprise Application Architecture*) — moves data between objects and the database
* **Salesforce supplies the object half** — SObjects are the objects, so the Selector reduces to *where queries live*
* **Builder** — how fflib assembles those queries: `fflib_QueryFactory`
* **Selector** — Data Mapper's query half, built with a Builder

<!--
- Nutshell: encapsulation
- Fowler's Data Mapper
- Salesforce owns objects
- Builder = QueryFactory
-->

---

<!-- _class: detail-slide promises-slide -->

# A query carries five concerns

* **Meaning** — the business rule a query encodes: which records qualify as *pending* or *idle*
* **Security** — who may see which records and fields
* **Performance** — selectivity, limits, large data volumes
* **Shape** — fields, order, relationships, aggregates, result types
* **Testability** — the seam where tests replace the database

<!--
- Thesis in one list
- Maps to slide 8 drifts
-->

---

<!-- _class: detail-slide code-slide compact-code-slide tabs-slide -->

# Criteria: WHERE clause or Domain?

<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-selector">RobotsSelector.selectIdleByWarehouseWithModel</span><span class="vscode-tab vscode-tab-domain">Robots.canAcceptWork</span></div>
<div class="tab-panes">
<div class="tab-pane">
<p class="pane-caption">Selector — the coarse cut the database answers cheaply</p>

```apex
fflib_QueryFactory query = newQueryFactory();
RobotModelsSelector.newInstance().configureQueryFactoryFields(query, 'Model__r');
return (List<Robot__c>) Database.query(
  query.setCondition('Warehouse__c IN :warehouseIds AND Status__c = \''
    + Robots.STATUS_IDLE + '\'').toSOQL()
);
```

</div>
<div class="tab-pane" data-marpit-fragment="1">
<p class="pane-caption">Domain — the business rule that may change</p>

```apex
Decimal wear = robot.WearPercent__c == null ? 0 : robot.WearPercent__c;
Decimal battery = robot.BatteryLevel__c == null ? 0 : robot.BatteryLevel__c;
return robot.Status__c == STATUS_IDLE
  && robot.Health__c != HEALTH_CRITICAL
  && wear < WEAR_CANNOT_WORK
  && battery > MIN_BATTERY_TO_WORK;
```

</div>
</div>
</div>

<p class="quiet-note">ℹ️ <em>Alternative: a formula field moves the rule into the WHERE clause, with its own baggage.</em></p>

<!--
- JD: criteria then action
- Coarse cut vs changing rule
- Shared constants
- Example: exampleCode/CampaignMember
- Click: Domain tab
-->

---

<!-- _class: detail-slide promises-slide -->

# The canonical Selector

* **One object, one Selector** — the default; most Selectors never go further
* **It alone defines its object's query knowledge:**
  * fields · default order · access mode · named conditions (what "open" or "idle" means)
* **Everything broader is built from these roots** — next slide
* **Aggregates belong here too** — coming up on slide 31
* Example: `WarehousesSelector`

<!--
- One object, one Selector
- One source of truth
-->

---

<!-- _class: detail-slide promises-slide -->

# Beyond one object: related records

* **Canonical:** one Selector per object — Warehouse
* **Composite Selectors:** usually methods on the object's own Selector, returning related records composed from their Selectors
* **Tight (master-detail):** Fulfillment Order ⇄ Fulfillment Lines — `…WithLines`, `…WithOrder`
* **Looser (lookups):** each object through its own Selector; the Service joins them — Warehouse → Robots; Robot → Maintenance Jobs
* **Small parent, always needed:** Robot → Robot Model — `…WithModel`
* **Feature Selector:** queries grouped by purpose when no single object owns them — e.g. campaign engagement over `CampaignMember`
* *Composite Selectors build on each object's Selector; they never redefine it.*

<!--
- Usually methods, not classes
- Borrow fields, order, conditions
- Andy: selectByOpportunity
- CampaignMember example
-->

---

<!-- _class: detail-slide promises-slide -->

# Selector ☑️ Checklist

* **Method names say what is returned and how it's filtered:** `select…By…`, `count…`, `…AsQueryLocator`, `…AsCursor`, `…AsPaginationCursor`
  * ✅ `selectIdleByWarehouseWithModel(warehouseIds)` ❌ `getRobots(ids, true)`
* **Bulk in and out; empty in, empty out**
  * ✅ `selectById(Set<Id> idSet)` ❌ `selectById(Id robotId)`
* **Paramount fields by default, additions by need; consistent order**
* **User mode by default; aggregates and counts belong here too**

<!--
- Builds on Andy's S1 list
-->

---

<!-- _class: detail-slide promises-slide -->

# Questions you've already asked

* **May a Domain call a Selector?** Yes — when a robot is reassigned, the Robots Domain checks that the target warehouse is Active, through `WarehousesSelector`
* **May a client call a Selector directly?** Yes, for a plain read — `DispatchWarehouse` calls `WarehousesSelector.selectByName`
* **One Selector per record type?** No — one per object, as a rule; say the record type in the method name. A Feature Selector groups queries by purpose when no single object owns them
* **Common fields or a new method?** Common fields go on the shared list; a special shape earns its own method, or a parameter that lets the consumer add fields

<!--
- Open questions, Sessions 1–3
- fflib #379, #373
-->

---

<!-- _class: detail-slide quote-slide quote-statement-slide -->

<blockquote>
Questions so far?
</blockquote>

<!--
- Sally: chat questions
-->

---

<!-- _class: detail-slide checklist-slide -->

# Agenda

<img class="checklist-gears" src="images/pattern-layers-gears.svg" alt="Domain, Selector, and Service layers as interlocking gears" />

<ul class="checklist">
<li>Query Logic</li>
<li>Recap<span class="check">✅</span></li>
<li>Why Query Logic Matters<span class="check">✅</span></li>
<li>Selector Principles<span class="check">✅</span></li>
<li class="current">The fflib Selector<span class="check"></span></li>
<li>Warehouse App Selectors<span class="check"></span></li>
<li>Selector Evolution<span class="check"></span></li>
</ul>

---

<!-- _class: detail-slide code-slide compact-code-slide -->

# Anatomy of an fflib Selector

<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-selector">WarehousesSelector.cls</span></div>

```apex
public virtual inherited sharing class WarehousesSelector extends fflib_SObjectSelector {
  public static WarehousesSelector newInstance() {          // composition
    return new WarehousesSelector();
  }
  public WarehousesSelector() {                             // default posture
    super(false, fflib_SObjectSelector.DataAccess.USER_MODE);
  }
  public List<Schema.SObjectField> getSObjectFieldList() {   // design: paramount fields
    return new List<Schema.SObjectField>{
      Warehouse__c.Id, Warehouse__c.Name, Warehouse__c.Status__c, Warehouse__c.Location__c
    };
  }
  public Schema.SObjectType getSObjectType() {              // plumbing
    return Warehouse__c.SObjectType;
  }
  public virtual List<Warehouse__c> selectActive() {        // a select method
    return (List<Warehouse__c>) Database.query(
      newQueryFactory().setCondition('Status__c = \'' + Warehouses.STATUS_ACTIVE + '\'').toSOQL()
    );
  }
}
```

</div>

<p class="quiet-note">ℹ️ <em>Field tokens may help catch field-name issues before runtime.</em></p>

<!--
- newInstance vs constructors
- Field list = design
- App factory optional
- Factory ≈ 80%
- Token note: light touch
-->

---

<!-- _class: detail-slide promises-slide -->

# Security: the defaults flipped

* **API 67.0+ (Summer '26):** Apex runs in **user mode** by default; no sharing keyword means **with sharing** — fflib's move is in the works
* **API 66.0 and earlier:** **system mode** by default
* **Defaults follow each class's API version** — the Warehouse app is 67.0; fflib is 63.0
* **So state the mode:** `DataAccess.USER_MODE` appends `WITH USER_MODE` wherever the query executes

<!--
- User mode: CRUD, FLS, sharing
- fflib still 63.0
- Upgrade shipping soon
- Stated DataAccess: unaffected
- LEGACY → user mode
-->

---

<!-- _class: detail-slide code-slide compact-code-slide -->

# Data Access Layering

<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-selector">RobotsSelector.cls</span></div>

```apex
// 1. Default: user mode — RobotsSelector.newInstance()
// 2. Posture chosen at instantiation
public RobotsSelector(fflib_SObjectSelector.DataAccess access) {
  super(false, access);
}
// 3. Method argument: this query only; the instance is unchanged
public virtual List<Robot__c> selectById(Set<Id> idSet, fflib_SObjectSelector.DataAccess access) {
  return (List<Robot__c>) Database.query(
    newQueryFactory(access).setCondition(Robot__c.Id + ' IN :idSet').toSOQL()
  );
}
```

</div>

* **Entry points still declare**
* **Consumers stay inherited**
* **Queries declare user mode**
* **Elevation is named, never ambient**

<!--
- Default → posture → argument
- Elevation is deliberate
- Both modes, one transaction
- Class keyword = safety net
- withPermissionSetId: watch
-->

---

<!-- _class: detail-slide promises-slide -->

# What the base class gives you

* **Required:** `getSObjectType`, `getSObjectFieldList`
* **Free queries:** `selectSObjectsById`, `queryLocatorById`
* **`newQueryFactory()`** — creates a query factory pre-loaded with fields, order, and mode
* **Composition:**
  * `configureQueryFactoryFields` — adds a parent Selector's fields under a relationship path
  * `addQueryFactorySubselect` — adds a child Selector's fields and order as a subquery
* **Field sets:** `includeFieldSetFields` — adds the constituent fields of a field set
* **Default order:** the name field (unless encrypted) → CreatedDate → Id

<!--
- Skippable if short
- Name field, not always Name
-->

---

<!-- _class: detail-slide code-slide compact-code-slide tabs-slide -->

# The Builder in action

<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-selector">FulfillmentLinesSelector.getOrderBy</span><span class="vscode-tab vscode-tab-selector">WarehousesSelector.selectByName</span></div>
<div class="tab-panes">
<div class="tab-pane">
<p class="pane-caption">Order is a business rule, set once</p>

```apex
public override String getOrderBy() {
  return 'FulfillmentOrder__r.Priority__c, Name';
}
```

</div>
<div class="tab-pane" data-marpit-fragment="1">
<p class="pane-caption">A method states only its condition</p>

```apex
Map<String, Warehouse__c> warehouseByName = new Map<String, Warehouse__c>();
if (names == null || names.isEmpty()) {
  return warehouseByName;
}
for (Warehouse__c warehouse : (List<Warehouse__c>) Database.query(
  newQueryFactory().setCondition('Name IN :names').toSOQL()
)) {
  warehouseByName.put(warehouse.Name, warehouse);
}
return warehouseByName;
```

</div>
</div>
</div>

<p class="quiet-note">ℹ️ <em>An index loop may help with larger result sets.</em></p>

<!--
- Order = business rule
- Method states condition only
- Map by Name, once
- Click: second tab
-->

---

<!-- _class: detail-slide code-slide compact-code-slide -->

# Paramount fields, plus what you need

<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-selector">RobotsSelector.cls</span></div>

```apex
// In-method: a field for this method's purpose
public virtual List<Robot__c> selectByIdWithOwner(Set<Id> idSet) {
  return (List<Robot__c>) Database.query(
    newQueryFactory().selectField(Robot__c.OwnerId).setCondition(Robot__c.Id + ' IN :idSet').toSOQL()
  );
}
// Consumer-supplied: fields of particular interest
public virtual List<Robot__c> selectById(Set<Id> idSet, Set<Schema.SObjectField> additionalFields) {
  fflib_QueryFactory query = newQueryFactory();
  if (additionalFields != null) {
    query.selectFields(additionalFields);
  }
  return (List<Robot__c>) Database.query(query.setCondition(Robot__c.Id + ' IN :idSet').toSOQL());
}
// Declarative: field sets via includeFieldSetFields (the hook AT4DX builds on)
```

</div>

<p><strong>Tokens, not strings: shift left.</strong> Nobody removes the core.</p>

<!--
- Paramount core; add, never remove
- User mode covers added fields
- Tokens: light touch
- No duplicate fields
- Andy: common, then add
-->

---

<!-- _class: detail-slide quote-slide quote-statement-slide -->

<blockquote>
Questions before the Warehouse app?
</blockquote>

<!--
- Sally: chat questions
-->

---

<!-- _class: detail-slide checklist-slide -->

# Agenda

<img class="checklist-gears" src="images/pattern-layers-gears.svg" alt="Domain, Selector, and Service layers as interlocking gears" />

<ul class="checklist">
<li>Query Logic</li>
<li>Recap<span class="check">✅</span></li>
<li>Why Query Logic Matters<span class="check">✅</span></li>
<li>Selector Principles<span class="check">✅</span></li>
<li>The fflib Selector<span class="check">✅</span></li>
<li class="current">Warehouse App Selectors<span class="check"></span></li>
<li>Selector Evolution<span class="check"></span></li>
</ul>

---

<!-- _class: detail-slide code-slide compact-code-slide tabs-slide -->

# Tight relationships, in code

<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-selector">FulfillmentOrdersSelector.selectByIdWithLines</span><span class="vscode-tab vscode-tab-selector">FulfillmentLinesSelector.selectPendingUnassignedByWarehouseWithOrder</span></div>
<div class="tab-panes">
<div class="tab-pane">
<p class="pane-caption">Children through a subselect</p>

```apex
fflib_QueryFactory ordersQuery = newQueryFactory();
FulfillmentLinesSelector.newInstance().addQueryFactorySubselect(ordersQuery);
return (List<FulfillmentOrder__c>) Database.query(
  ordersQuery.setCondition('Id IN :idSet').toSOQL()
);
```

</div>
<div class="tab-pane" data-marpit-fragment="1">
<p class="pane-caption">Parent fields borrowed from the parent's Selector</p>

```apex
fflib_QueryFactory query = newQueryFactory();
FulfillmentOrdersSelector.newInstance().configureQueryFactoryFields(query, 'FulfillmentOrder__r');
return (List<FulfillmentLine__c>) Database.query(
  query.setCondition(
    'Status__c = \'' + FulfillmentLines.STATUS_PENDING + '\''
      + ' AND AssignedRobot__c = null'
      + ' AND FulfillmentOrder__r.Warehouse__c IN :warehouseIds'
      + ' AND FulfillmentOrder__r.Status__c IN (\''
      + FulfillmentOrders.STATUS_RELEASED + '\', \''
      + FulfillmentOrders.STATUS_IN_PROGRESS + '\')'
  ).toSOQL()
);
```

</div>
</div>
</div>

<!--
- Borrow from each Selector
- One query, one mode
- Subselect vs two queries
- Weigh child counts
- Click: second tab
-->

---

<!-- _class: detail-slide code-slide compact-code-slide drift-slide -->

# Who wrote this query?

<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-selector">FulfillmentLinesSelector.selectPendingUnassignedByWarehouseWithOrder(…) → toSOQL()</span></div>

```sql
SELECT id, name, fulfillmentorder__c, status__c,
  productsku__c, quantity__c, weightkg__c, assignedrobot__c,
  fulfillmentorder__r.id, fulfillmentorder__r.name,
  fulfillmentorder__r.warehouse__c, fulfillmentorder__r.status__c,
  fulfillmentorder__r.priority__c, fulfillmentorder__r.duedate__c
FROM FulfillmentLine__c
WHERE Status__c = 'Pending' AND AssignedRobot__c = null
  AND FulfillmentOrder__r.Warehouse__c IN :warehouseIds
  AND FulfillmentOrder__r.Status__c IN ('Released', 'In Progress')
WITH USER_MODE
ORDER BY FulfillmentOrder__r.Priority__c ASC NULLS FIRST , Name ASC NULLS FIRST
```

</div>

<div class="drift" data-marpit-fragment="1" style="--drift:#3ec7f5"><span class="drift-band" style="left:112px;top:130px;width:1047px;height:41px"></span><span class="drift-band" style="left:112px;top:232px;width:1047px;height:20px"></span><span class="drift-badge" style="left:1136px;top:150.5px">1</span><span class="drift-badge" style="left:1136px;top:242.0px">1</span><svg class="drift-arrow" viewBox="0 0 1280 720"><path class="line" pathLength="1" d="M1070 422 C1070 173.0 1046 161.0 1010 161.0 L795 161.0"/><path class="head" d="M795.0 161.0 L805.0 155.0 L805.0 167.0Z"/><path class="line" pathLength="1" d="M1070 422 C1070 254.0 1046 242.0 1010 242.0 L415 242.0"/><path class="head" d="M415.0 242.0 L425.0 236.0 L425.0 248.0Z"/></svg><div class="drift-bubble" style="left:540px;top:422px;width:560px;transform-origin:top right"><b><span class="drift-num">1</span>FulfillmentLinesSelector</b>Its paramount fields from <code>getSObjectFieldList</code>, and its object from <code>getSObjectType</code>.</div></div>
<div class="drift" data-marpit-fragment="2" style="--drift:#b48cff"><span class="drift-band" style="left:112px;top:171px;width:1047px;height:61px"></span><span class="drift-badge" style="left:1136px;top:201.5px">2</span><svg class="drift-arrow" viewBox="0 0 1280 720"><path class="line" pathLength="1" d="M1070 422 C1070 213.5 1046 201.5 1010 201.5 L856 201.5"/><path class="head" d="M856.0 201.5 L866.0 195.5 L866.0 207.5Z"/></svg><div class="drift-bubble" style="left:540px;top:422px;width:560px;transform-origin:top right"><b><span class="drift-num">2</span>FulfillmentOrdersSelector</b>Its paramount fields, prefixed by <code>configureQueryFactoryFields(query, 'FulfillmentOrder__r')</code>. Nothing retyped.</div></div>
<div class="drift" data-marpit-fragment="3" style="--drift:#ffb020"><span class="drift-band" style="left:112px;top:252px;width:1047px;height:62px"></span><span class="drift-badge" style="left:1136px;top:283.0px">3</span><svg class="drift-arrow" viewBox="0 0 1280 720"><path class="line" pathLength="1" d="M1070 422 C1070 295.0 1046 283.0 1010 283.0 L744 283.0"/><path class="head" d="M744.0 283.0 L754.0 277.0 L754.0 289.0Z"/></svg><div class="drift-bubble" style="left:540px;top:422px;width:560px;transform-origin:top right"><b><span class="drift-num">3</span>The method</b>Only the condition, through <code>setCondition</code>: the one part the method writes itself.</div></div>
<div class="drift" data-marpit-fragment="4" style="--drift:#3ec7f5"><span class="drift-band" style="left:112px;top:334px;width:1047px;height:20px"></span><span class="drift-badge" style="left:1136px;top:344.0px">4</span><svg class="drift-arrow" viewBox="0 0 1280 720"><path class="line" pathLength="1" d="M1070 422 C1070 356.0 1046 344.0 1010 344.0 L988 344.0"/><path class="head" d="M988.0 344.0 L998.0 338.0 L998.0 350.0Z"/></svg><div class="drift-bubble" style="left:540px;top:422px;width:560px;transform-origin:top right"><b><span class="drift-num">4</span>FulfillmentLinesSelector</b>Its <code>getOrderBy</code>: High priority first, a business rule set once for every query.</div></div>
<div class="drift" data-marpit-fragment="5" style="--drift:#3ec7f5"><span class="drift-band" style="left:112px;top:314px;width:1047px;height:20px"></span><span class="drift-badge" style="left:1136px;top:324.0px">5</span><svg class="drift-arrow" viewBox="0 0 1280 720"><path class="line" pathLength="1" d="M1070 422 C1070 336.0 1046 324.0 1010 324.0 L323 324.0"/><path class="head" d="M323.0 324.0 L333.0 318.0 L333.0 330.0Z"/></svg><div class="drift-bubble" style="left:540px;top:422px;width:560px;transform-origin:top right"><b><span class="drift-num">5</span>FulfillmentLinesSelector</b>Its posture, <code>DataAccess.USER_MODE</code> from the constructor: appended once, at the top level. It's also why the fields are lowercase.</div></div>

<p class="drift-tagline"><em>One statement, three sources of truth, nothing retyped.</em></p>

<!--
- Real toSOQL() output
- Click five sources
- Lowercase = user mode
- New field flows through
-->

---

<!-- _class: detail-slide code-slide compact-code-slide -->

# Looser relationships, in code

<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-service">DispatchService.dispatchWarehouses</span></div>

```apex
List<FulfillmentLine__c> pending =
  lineSelector.selectPendingUnassignedByWarehouseWithOrder(warehouseIds);
if (pending.isEmpty()) {
  return;
}
List<Robot__c> idle = robotSelector.selectIdleByWarehouseWithModel(warehouseIds);
```

</div>

<!--
- Service joins Selectors
- …WithModel: seen on 12
-->

---

<!-- _class: detail-slide callers-table-slide -->

# Return shapes

<table>
<thead><tr><th>Shape</th><th>When</th></tr></thead>
<tbody>
<tr><td>List or Map</td><td>Everyday reads</td></tr>
<tr><td>AggregateResult → Map</td><td>Counts and summaries</td></tr>
<tr><td>QueryLocator</td><td>Batch Apex</td></tr>
<tr><td>Cursor</td><td>Chunked async processing</td></tr>
<tr><td>PaginationCursor</td><td>UI paging</td></tr>
</tbody>
</table>

<!--
- Shape by job, not habit
-->

---

<!-- _class: detail-slide code-slide compact-code-slide -->

# Aggregates

<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-selector">RobotsSelector.countAvailableByWarehouse</span></div>

```apex
Map<Id, Integer> counts = new Map<Id, Integer>();
for (AggregateResult row : [
  SELECT Warehouse__c warehouseId, COUNT(Id) robotCount
  FROM Robot__c
  WHERE Warehouse__c IN :warehouseIds
    AND Status__c = :Robots.STATUS_IDLE
    AND (Health__c = null OR Health__c != :Robots.HEALTH_CRITICAL)
    AND (WearPercent__c = null OR WearPercent__c < :Robots.WEAR_CANNOT_WORK)
    AND BatteryLevel__c > :Robots.MIN_BATTERY_TO_WORK
  WITH USER_MODE
  GROUP BY Warehouse__c
]) {
  counts.put((Id) row.get('warehouseId'), (Integer) row.get('robotCount'));
}
return counts;
```

</div>

<!--
- A count is a query
- Mirrors canAcceptWork
- Static SOQL states mode
- Map by warehouse
- Named aliases, not ordinals
-->

---

<!-- _class: detail-slide code-slide compact-code-slide tabs-slide -->

# Batch versus Queueable chunking

<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-selector">WarehousesSelector.selectActiveAsQueryLocator</span><span class="vscode-tab vscode-tab-selector">FulfillmentLinesSelector.selectPendingByWarehouseAsCursor</span></div>
<div class="tab-panes">
<div class="tab-pane">
<p class="pane-caption">QueryLocator → Batch Apex</p>

```apex
return Database.getQueryLocator(
  newQueryFactory().setCondition('Status__c = \'' + Warehouses.STATUS_ACTIVE + '\'').toSOQL()
);
```

</div>
<div class="tab-pane" data-marpit-fragment="1">
<p class="pane-caption">Cursor → chunked Queueables</p>

```apex
String orderRelationship = FulfillmentLine__c.FulfillmentOrder__c
  .getDescribe().getRelationshipName();
return Database.getCursor(
  newQueryFactory()
    .setCondition(
      FulfillmentLine__c.Status__c + ' = \'' + FulfillmentLines.STATUS_PENDING + '\''
        + ' AND ' + orderRelationship + '.' + FulfillmentOrder__c.Warehouse__c
        + ' IN :warehouseIds'
    )
    .toSOQL()
);
```

</div>
</div>
</div>

<!--
- QueryLocator → Batch
- Cursor: 50M rows, 100 fetches
- Same factory, new shape
- Queueable via Service
- 50k-row limit
-->

---

<!-- _class: detail-slide code-slide compact-code-slide -->

# UI paging

<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-selector">RobotsSelector.selectByWarehouseAsPaginationCursor</span></div>

```apex
return Database.getPaginationCursor(
  newQueryFactory()
    .setCondition(Robot__c.Warehouse__c + ' IN :warehouseIds')
    // Name isn't unique, so Id breaks ties
    .setOrdering(Robot__c.Name, fflib_QueryFactory.SortOrder.ASCENDING)
    .addOrdering(Robot__c.Id, fflib_QueryFactory.SortOrder.ASCENDING)
    .toSOQL()
);
```

</div>

<p><strong>Live:</strong> <code>without-paging.apex</code>, then <code>with-paging.apex</code> · up to 100K rows · credit Andy's Jan 2026 post</p>

<!--
- Run both scripts
- Selector returns cursor only
- Three quirks
- Order by Name, Id
-->

---

<!-- _class: detail-slide pair-code-slide -->

# The Dispatch walk

<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-service">DispatchService.dispatchWarehouses</span></div>
<div class="vscode-prose">
<p class="walk-sig walk-sig-start"><span class="walk-kw">public virtual void</span> dispatchWarehouses(Set&lt;Id&gt; warehouseIds) {</p>

1. <span class="walk-layer walk-layer-selector">Selector</span> — pending, unassigned lines at these warehouses, with their orders
2. <span class="walk-layer walk-layer-selector">Selector</span> — idle robots at these warehouses, with their models
3. <span class="walk-layer walk-layer-domain">Domain</span> — keep robots that can legally accept work
4. <span class="walk-layer walk-layer-service">Service</span> — match one robot per line, within one warehouse
5. <span class="walk-layer walk-layer-domain">Domain</span> — start robots, assign lines, mark orders in progress
6. <span class="walk-layer walk-layer-service">Service</span> — one Unit of Work commits

<p class="walk-sig walk-sig-end">}</p>
</div>
</div>

<!--
- Skip if short
- Two queries, zero SOQL
-->

---

<!-- _class: detail-slide code-slide compact-code-slide tabs-slide -->

# The mocking seam

<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-service">DispatchService.newInstance</span><span class="vscode-tab vscode-tab-alt">DispatchServiceTest.cls</span></div>
<div class="tab-panes">
<div class="tab-pane">
<p class="pane-caption">Composition: real Selectors by default</p>

```apex
public static DispatchService newInstance() {
  return new DispatchService(
    FulfillmentLinesSelector.newInstance(),
    RobotsSelector.newInstance(),
    FulfillmentOrdersSelector.newInstance()
  );
}
```

</div>
<div class="tab-pane" data-marpit-fragment="1">
<p class="pane-caption">Tests: stub the virtual methods, inject through the constructor</p>

```apex
RobotsSelector robotSelectorMock = (RobotsSelector) mocks.mock(RobotsSelector.class);
mocks.startStubbing();
mocks.when(robotSelectorMock.selectIdleByWarehouseWithModel(warehouseIds))
  .thenReturn(new List<Robot__c>{ robot });
mocks.stopStubbing();
new DispatchService(lineSelectorMock, robotSelectorMock, orderSelectorMock)
  .dispatchWarehouses(warehouseIds);
```

</div>
</div>
</div>

<p>ⓘ <strong>Session #5 — Mocking in Apex</strong> · Oct 20: the deep dive</p>

<!--
- JD's promise kept
- virtual + constructor injection
- No interfaces needed
- Session 5: deep dive
- Click: test tab
-->

---

<!-- _class: detail-slide checklist-slide -->

# Agenda

<img class="checklist-gears" src="images/pattern-layers-gears.svg" alt="Domain, Selector, and Service layers as interlocking gears" />

<ul class="checklist">
<li>Query Logic</li>
<li>Recap<span class="check">✅</span></li>
<li>Why Query Logic Matters<span class="check">✅</span></li>
<li>Selector Principles<span class="check">✅</span></li>
<li>The fflib Selector<span class="check">✅</span></li>
<li>Warehouse App Selectors<span class="check">✅</span></li>
<li class="current">Selector Evolution<span class="check"></span></li>
</ul>

---

<!-- _class: detail-slide promises-slide service-evolution-slide -->

# Selector 🔁 Evolution

* **Explicit access modes**
  * ✅ `DataAccess.USER_MODE`, and the API 67.0 user-mode default
  * ❌ `enforceFLS()`, CRUD/FLS constructor flags, `without sharing` inner classes
* **Fields**
  * ✅ Common fields, with additions by need
  * ❌ Kitchen-sink Selectors that fetch everything for everyone
* **Composition**
  * ✅ Instances composed through `newInstance()` and constructors; feature Selectors where queries belong together
  * ❌ Static query methods
* **New shapes:** cursors, absorbed without changing the pattern

<!--
- Memoization: future idea
-->

---

<!-- _class: detail-slide promises-slide service-evolution-slide -->

# The library keeps moving

* **`setAllRows(Boolean)` overload** — Reinier van den Assum, Sep 2026
* **`@NamespaceAccessible`** — Aug 2026
* **Apex Mocks** — no longer a dependency
* **AT4DX** — cross-package extension through field sets (`includeFieldSetFields`)

<p class="session-callout"><span class="info-mark">ⓘ</span> <strong>Session #6 — Enterprise-Scale Apex Across Multiple Packages</strong><span class="session-callout-sub">Nov 3: AT4DX and more</span></p>

<!--
- Skippable if short
- AT4DX → Session 6
-->

---

<!-- _class: detail-slide promises-slide -->

# Go deeper

* **Matt Gerry** — chapters 12–14 at apex-enterprise-patterns.dev; moving to the AEP GitHub soon
* **fflib-apex-common** — github.com/apex-enterprise-patterns/fflib-apex-common
* **The Warehouse sample** — this session's repo and README
* **Andy Fawcett** — andyinthecloud.com
  * [Recent updates and thoughts on the Application class](https://andyinthecloud.com/2026/04/13/apex-enterprise-patterns-recent-updates-and-thoughts-on-the-application-class/) (Apr 2026)
  * [What does the new Apex User Mode Default mean for you?](https://andyinthecloud.com/2026/04/27/what-does-the-new-apex-user-mode-default-mean-for-you/) (Apr 2026)
  * [Infinite scrolling with Apex Pagination Cursors](https://andyinthecloud.com/2026/01/19/improved-infinite-data-scrolling-with-new-apex-pagination-cursors-ga/) (Jan 2026)

---

<!-- _class: detail-slide quote-slide quote-statement-slide -->

<blockquote>
Ask the database a question once, in one place, in words the business would recognise.
</blockquote>

---

<!-- _class: detail-slide series-slide -->

# What's Next — FFLib Series

<table>
<thead>
<tr><th></th><th>Session</th></tr>
</thead>
<tbody>
<tr class="done"><td><span class="check">✅</span></td><td>Session #1 — Separation of Concerns in Apex: Why Your Future Self Will Thank You</td></tr>
<tr class="done"><td><span class="check">✅</span></td><td>Session #2 — Service Layers Explained: Coordinating Business Logic in Apex</td></tr>
<tr class="done"><td><span class="check">✅</span></td><td>Session #3 — Domain vs Service: Where Should Your Apex Logic Live?</td></tr>
<tr class="done"><td><span class="check">✅</span></td><td>Session #4 — Query Logic as a First-Class Architecture Concern</td></tr>
<tr class="current"><td><span class="check"></span></td><td>Session #5 — Mocking in Apex: Why It Changes Everything · Oct 20</td></tr>
<tr><td><span class="check"></span></td><td>Session #6 — Enterprise-Scale Apex Across Multiple Packages · Nov 3</td></tr>
</tbody>
</table>

<!--
- Sally may present roadmap
-->

---

<!-- _class: title-slide -->

# Thank you!

#### John Storey · Code With Sally
### FFLib Series · Session 004

![Code With Sally](images/codewithsally.png)

