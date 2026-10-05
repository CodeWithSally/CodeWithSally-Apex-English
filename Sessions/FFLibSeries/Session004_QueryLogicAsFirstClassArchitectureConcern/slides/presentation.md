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
Sally introduces John and reads the bio. One sentence of thanks to Sally, Andy, and John Daniel, then straight to the problem, not to us.
-->

---

<!-- _class: detail-slide about-slide -->

<div class="about-split">
<div class="about-copy">

# About me

##### Staff Software Engineer | Thrivent | Apex Enterprise Patterns maintainer

* **Apex Enterprise Patterns** — a maintainer of fflib, the library this series is built on
* **FinancialForce roots** — helped build fflib in the mid-2010s, alongside Andy Fawcett and John Daniel

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
Keep it brief: Sally has just read the bio.
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
We're here: Session 4 of 6. Mocking (Oct 20) and multi-package (Nov 3) follow, and both build on tonight.
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
Three parts: the pattern, fflib's version of it, then the Warehouse app. Two question pauses are built in.
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
Service conducts: one task per method, and it owns the Unit of Work (Andy's conductor and band).
Domain is the Lego brick: behaviour of one object, criteria then action (John Daniel's bricks).
The Selector is the brick everyone reaches for: it's the only column with a dot on every row.
-->

---

<!-- _class: detail-slide promises-slide -->

# Demo: deploy fflib and the app

* **① Apex Mocks** — the README's "Deploy fflib" step
* **② Apex Common** — depends on Apex Mocks; same README step
* **③ The Warehouse app (`force-app`)** — depends on Apex Common; the README's "Deploy force-app" step
* **It's a source deploy, not a package install** — each `sf project deploy start` runs from inside its own repo
* **Everything is in the session README** — nothing to copy from the screen
  * github.com/CodeWithSally/CodeWithSally-Apex-English → Sessions/FFLibSeries/Session004…

<!--
Live: run the README's "Deploy the app" commands exactly as written, with the README open beside the terminal. The scratch org and the two clones are ready beforehand.
--ignore-warnings stops Apex Common's compile warnings from failing the deploy.
--ignore-errors: say the README's one-line reason and move on; the agent isn't today's topic.
Talk over the Common deploy: "this is the base class library the rest of tonight builds on".
Agent publishing, permission sets, sample data and tests come later in the README and aren't part of the demo.
-->

---

<!-- _class: detail-slide promises-slide -->

# PSA: good SOQL habits

* **No SOQL (or DML) inside loops**
  * ❌ `for (Id lineId : lineIds) { [SELECT … WHERE Id = :lineId]; }`
  * ✅ One query with `WHERE Id IN :lineIds`, then work from a `Map`
* **Index loops, size cached** — about 2× faster than for-each: ≈500 ms against ≈1,000 ms of CPU over 200,000 integers, measured in our org
* **Bind variables**, never joined-in user input
* **Select only the fields you need; filter on indexed fields**
* **Bound your results** — `LIMIT`, a QueryLocator, or a cursor; mind the 50,000-row limit

<!--
A one-minute public-service announcement before the Selector content: good SOQL practice wherever your queries live.
Loop timings, three runs each: index loop with the size cached 487–529 ms; for-each 962–1,177 ms; index loop calling size() every pass 733–920 ms. It's a general Apex habit.
Bind variables prevent SOQL injection. Formula fields and a leading % in LIKE stop indexes being used. SOQL for loops keep heap down on large results.
Null versus empty input is a business decision (an empty result or an exception); state it in the method's contract.
Date literals (TODAY, LAST_N_DAYS) use the running user's time zone.
-->

---

<!-- _class: detail-slide code-slide duo-slide -->

# What's wrong with this picture?

<div class="duo">
<div class="duo-col">
<p class="dev-caption">👤 Developer "A" — the desk's LWC controller</p>
<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-client">WarehouseDeskController.cls</span></div>

```apex
List<FulfillmentLine__c> pending = [
  SELECT Id, Name, ProductSku__c, Quantity__c
  FROM FulfillmentLine__c
  WHERE Status__c = 'Pending'
    AND FulfillmentOrder__r.Warehouse__c = :warehouseId
];
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

<!--
The same business question, "which lines are pending?", written twice by hand. Both compile and both work, which is exactly why the drift goes unnoticed.
Illustrative only: this code is not in the Warehouse app.
Let the audience spot the differences before the next slide names them.
-->

---

<!-- _class: detail-slide issue-slide issue-slide-single -->

# So what was wrong with that picture?

<div class="issue-block">
<p class="issue-who">The same question, asked twice, answered differently</p>
<table>
<thead><tr><th>Drift</th><th>Issue</th></tr></thead>
<tbody>
<tr><td>Meaning</td><td>A counts lines already assigned to a robot, and lines on Draft or On Hold orders. B doesn't.</td></tr>
<tr><td>Security mode</td><td>A runs in the class default (user mode at API 67.0); B elevates to system mode.</td></tr>
<tr><td>Order</td><td>A has none; B sorts by Name, though dispatch's rule is High priority first.</td></tr>
<tr><td>Shape</td><td>Different fields, so a caller switching queries breaks.</td></tr>
<tr><td>Magic strings</td><td>B's <code>'InProgress'</code> matches nothing: the status is <code>'In Progress'</code>.</td></tr>
</tbody>
</table>
</div>

<!--
Queries drift in five ways: meaning, security mode, order, shape, and magic strings.
None is a syntax error; each is a business decision made by accident.
Thesis: SOQL is logic, so it needs one authoritative home.
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

* **Data Mapper** (Fowler, *Patterns of Enterprise Application Architecture*) — moves data between objects and the database
* **Salesforce supplies the object half** — SObjects are the objects, so the Selector reduces to *where queries live*
* **Builder** — how fflib assembles those queries: `fflib_QueryFactory`
* **Selector** — Data Mapper's query half, built with a Builder

<!--
The Selector descends from Fowler's Data Mapper: it moves data between objects and the database.
Salesforce already provides the objects, so the Selector reduces to "where queries live."
The Builder pattern is how fflib assembles those queries (fflib_QueryFactory).
Visual to add: the PoEAA cover, and links to Fowler's catalog.
-->

---

<!-- _class: detail-slide promises-slide -->

# A query carries five concerns

* **Meaning** — what "pending" or "idle" means to the business
* **Security** — who may see which records and fields
* **Performance** — selectivity, limits, large data volumes
* **Shape** — fields, order, relationships, aggregates, result types
* **Testability** — the seam where tests replace the database

<!--
The thesis in one list. Each concern maps to one of the drifts on slide 9.
-->

---

<!-- _class: detail-slide code-slide duo-slide -->

# Criteria: WHERE clause or Domain?

<div class="duo">
<div class="duo-col">
<p class="dev-caption">Selector — the coarse cut the database answers cheaply</p>
<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-selector">RobotsSelector.selectIdleByWarehouseWithModel</span></div>

```apex
fflib_QueryFactory query = newQueryFactory();
RobotModelsSelector.newInstance()
  .configureQueryFactoryFields(query, 'Model__r');
return (List<Robot__c>) Database.query(
  query.setCondition('Warehouse__c IN :warehouseIds AND Status__c = \''
    + Robots.STATUS_IDLE + '\'').toSOQL()
);
```

</div>
</div>
<div class="duo-col">
<p class="dev-caption">Domain — the business rule that may change</p>
<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-domain">Robots.canAcceptWork</span></div>

```apex
return robot.Status__c == STATUS_IDLE
  && robot.Health__c != HEALTH_CRITICAL
  && wear < WEAR_CANNOT_WORK
  && battery > MIN_BATTERY_TO_WORK;
```

</div>
</div>
</div>

<!--
Bridge from John Daniel's criteria-then-action.
The Selector makes the coarse cut the database can answer cheaply (idle robots at these warehouses).
The Domain applies the business rule that may change (health, wear, battery), in getAvailableForWork via canAcceptWork.
Both use the same Domain constants, so meaning has one home.
Rule of thumb: Selector for cheap, shared filters; Domain for rules that compute or change; shared constants for both; Service to join several queries.
-->

---

<!-- _class: detail-slide promises-slide -->

# The canonical Selector

* **One object, one Selector** — the default; most Selectors never go further
* **It alone defines its object's query knowledge:**
  * fields · default order · access mode · named conditions (what "open" or "idle" means)
* **Everything broader is built from these roots** — next slide
* Example: `WarehousesSelector`

<!--
Establish the root: one object, one Selector, one source of truth for that object's query knowledge.
Visual to add: one Selector box listing what it owns.
-->

---

<!-- _class: detail-slide promises-slide -->

# Beyond one object: joint Selectors

* **Canonical:** Warehouse
* **Tight (master-detail):** Fulfillment Order ⇄ Fulfillment Lines — `…WithLines`, `…WithOrder`
* **Looser (lookups):** Warehouse → Robots; Robot → Maintenance Jobs — separate Selectors, joined by the Service
* **Small parent, always needed:** Robot → Robot Model — `…WithModel`
* **Feature Selector:** queries grouped by purpose rather than object
* *Joint Selectors are derived, not defined.*

<!--
Significant relationships are needed so often that Selectors should serve them, but joint Selectors are derived from their canonical roots, never defined afresh.
The mechanics: instance the root Selectors → configure them (fields, conditions, access mode) → let them contribute to the query factory → call toSOQL().
The rule: a joint Selector instances its root Selectors for fields, relationship name, order, and conditions. It may return more than its object; it never defines another object's query knowledge.
Andy's Session 1 example accountsSelector.selectByOpportunity(opportunities) is the same idea from the other direction.
Feature Selectors are illustrative for now: the Warehouse app has no cross-object feature to host one, and its desk snapshot correctly joins two Selectors in WarehouseService, as Andy showed in Session 2. Give a one-line generic example, such as a returns or pricing feature spanning several objects.
Visual to add: the object model as a spectrum, master-detail solid and lookups dashed.
-->

---

<!-- _class: detail-slide promises-slide -->

# Selector ☑️ Checklist

* **Name what is returned, and how it's filtered** — the method name is documentation
  * ✅ `selectIdleByWarehouseWithModel(warehouseIds)` ❌ `getRobots(ids, true)`
* **Bulk in and out; empty in, empty out**
  * ✅ `selectById(Set<Id> idSet)` ❌ `selectById(Id robotId)`
* **Paramount fields by default, additions by need; consistent order**
* **User mode by default; aggregates and counts belong here too**
* **Naming:** `select…`, `count…`, `…AsQueryLocator`, `…AsCursor`, `…AsPaginationCursor`

<!--
The principles, building on Andy's Session 1 list.
-->

---

<!-- _class: detail-slide promises-slide -->

# Questions you've already asked

* **May a Domain call a Selector?** Yes — say a warehouse fire takes a site offline: the Domain handling it may load that warehouse's robots through a Selector
* **May a client call a Selector directly?** Yes, for a plain read — `DispatchWarehouse` calls `WarehousesSelector.selectByName`
* **One Selector per record type?** No — one per object; say the record type in the method name
* **Common fields or a new method?** Common fields go on the shared list; a special shape earns its own method

<!--
Answers to open questions from Sessions 1–3. Nod to fflib issues #379 and #373.
-->

---

<!-- _class: detail-slide quote-slide quote-statement-slide -->

<blockquote>
Questions so far?
</blockquote>

<!--
First pause for Sally to relay chat questions.
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

<!--
extends fflib_SObjectSelector, inherited sharing, virtual methods.
Composition: a static newInstance() is the canonical way in; constructors serve deliberate needs, such as elevated posture (new RobotsSelector(DataAccess.SYSTEM_MODE)) and tests.
getSObjectFieldList is the design decision: the paramount fields. Optional getOrderBy.
getSObjectType: still required plumbing for the base class; no longer required for Application factory lookup. For audience members on the Application factory: it still works and getSObjectType still routes it; it's simply optional now (Andy's April 2026 post).
The query factory covers the common 80% of SOQL. For the rest (toLabel(), convertCurrency(), TYPEOF, SOSL, and ALL ROWS through setAllRows()), the method is still the home: write raw SOQL or SOSL, or build with the factory and substitute a token into its output. Mind that user and system mode lowercase selected fields. The inherited aggregate methods already use static SOQL inside the Selector.
The slide shows selected methods from WarehousesSelector, without Javadoc.
-->

---

<!-- _class: detail-slide promises-slide -->

# Security: the defaults flipped

* **API 67.0+ (Summer '26):** Apex runs in **user mode** by default; no sharing keyword means **with sharing**
* **API 66.0 and earlier:** **system mode** by default
* **Defaults follow each class's API version** — the Warehouse app is 67.0; fflib is 63.0
* **So state the mode:** `DataAccess.USER_MODE` appends `WITH USER_MODE` wherever the query executes

<!--
User mode enforces the running user's object permissions, field-level security, and sharing.
fflib's master branch is 63.0 (a 67.0 bump is in progress; recheck before the session), so one Selector can run under two defaults unless you state the mode.
In system mode, record sharing follows the class keyword, so inherited base methods (which run in fflib_SObjectSelector, a with sharing class) keep sharing even when elevated.
Visual to add: a small table, where the query executes × class API version → default mode.
-->

---

<!-- _class: detail-slide code-slide compact-code-slide -->

# Access layering

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

<p><strong>Entry points still declare. Consumers stay inherited. Queries declare user mode. Elevation is named, never ambient.</strong></p>

<!--
Default user mode → posture optionally changed at instantiation (new RobotsSelector(DataAccess.SYSTEM_MODE)) → method argument, if provided (selectById(ids, DataAccess.SYSTEM_MODE)); each overrides the one before.
newInstance() is the canonical composition; constructors are for deliberate composition, and elevation is deliberate.
Choose posture when composing a Selector; never flip a shared one mid-logic. One transaction may legitimately use both modes: system mode to compute robot health from maintenance history the user never sees, user mode for the desk's robot list. A system-mode result shouldn't flow back to the user.
The class keyword remains the safety net for anything not explicitly moded: inline SOQL, DML outside the Unit of Work, and SYSTEM_MODE queries.
newQueryFactory(access) wraps fflib's legacy-named setEnforceFLS, which emits native WITH USER_MODE / WITH SYSTEM_MODE.
enforceFLS() and the without sharing inner class are retired (see the Evolution slide). AccessLevel.withPermissionSetId() (developer preview) for targeted elevation is worth a one-line "watch this space."
-->

---

<!-- _class: detail-slide promises-slide -->

# What the base class gives you

* **Required:** `getSObjectType`, `getSObjectFieldList`; optional `getOrderBy`
* **Free queries:** `selectSObjectsById`, `queryLocatorById`
* **`newQueryFactory()`** — starts pre-loaded with fields, order, and mode
* **Composition:** `configureQueryFactoryFields` (parents), `addQueryFactorySubselect` (children)
* **Field sets:** `includeFieldSetFields`
* **Default order:** Name → CreatedDate → Id

<!--
Fold candidate: could merge into slide 20.
-->

---

<!-- _class: detail-slide code-slide duo-slide -->

# The Builder in action

<div class="duo">
<div class="duo-col">
<p class="dev-caption">Order is a business rule, set once</p>
<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-selector">FulfillmentLinesSelector.getOrderBy</span></div>

```apex
public override String getOrderBy() {
  return 'FulfillmentOrder__r.Priority__c, Name';
}
```

</div>
</div>
<div class="duo-col">
<p class="dev-caption">A method states only its condition</p>
<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-selector">WarehousesSelector.selectByName</span></div>

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

<!--
Ordering can be a business rule: High priority first, set once in getOrderBy.
A method states only its condition; fields, order, and mode are inherited.
Shape choices, such as a map keyed by Name, are made once for every caller.
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
The hard-coded list holds the paramount fields nearly every caller needs. Methods and consumers may add fields of interest, never remove the core.
User mode still checks field-level security on every added field.
Prefer schema tokens over magic strings: Robot__c.WearPercent__c fails at compile time rather than at query time, can't be deleted out from under the code, and resolves to one canonical name. The cure for slide 9's magic strings. Relationship paths can come from the lookup's token through getRelationshipName(); the inherited code writes them once as strings, a style choice we leave as it is.
Additions are safe from duplicates: the query factory keeps selected fields in a set, normalised for case.
Edge cases for the curious: switching a factory from LEGACY to USER_MODE after fields are added can defeat the case normalisation (our Selectors start in USER_MODE, so they're safe); in user or system mode, string field names aren't validated until the query runs.
Echoes Andy's "start with common fields, add as needed".
-->

---

<!-- _class: detail-slide quote-slide quote-statement-slide -->

<blockquote>
Questions before the Warehouse app?
</blockquote>

<!--
Second pause for chat questions, before the code.
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

<!-- _class: detail-slide code-slide duo-slide -->

# Tight relationships, in code

<div class="duo">
<div class="duo-col">
<p class="dev-caption">Children through a subselect</p>
<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-selector">FulfillmentOrdersSelector.selectByIdWithLines</span></div>

```apex
fflib_QueryFactory ordersQuery = newQueryFactory();
FulfillmentLinesSelector.newInstance()
  .addQueryFactorySubselect(ordersQuery);
return (List<FulfillmentOrder__c>) Database.query(
  ordersQuery.setCondition('Id IN :idSet').toSOQL()
);
```

</div>
</div>
<div class="duo-col">
<p class="dev-caption">Parent fields borrowed from the parent's Selector</p>
<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-selector">FulfillmentLinesSelector.selectPending…WithOrder</span></div>

```apex
fflib_QueryFactory query = newQueryFactory();
FulfillmentOrdersSelector.newInstance()
  .configureQueryFactoryFields(query, 'FulfillmentOrder__r');
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
A joint Selector borrows fields, relationship names, and order from its roots. One toSOQL() renders the whole query, with child subselects inside it.
One query, one mode: subselects ride the outer query's access mode; mixing modes means two queries, each through its root Selector, joined in memory.
WITH USER_MODE / WITH SYSTEM_MODE is a clause on the whole statement; fflib appends it only at the top level.
Caveat: a standalone root factory's toSOQL() is a complete top-level query, so it can't be pasted in as a semi-join subquery.
A joint Selector can also borrow named conditions. This sample keeps its conditions where its authors wrote them.
Subselect or two queries? Weigh the likely child counts: subselects handled implicitly in one Selector, or parent Ids passed to a child Selector. Iterate a large child relationship with a for loop; reading it directly can throw "Aggregate query has too many rows for direct assignment". One could get fancy and react to the QueryException instead.
-->

---

<!-- _class: detail-slide code-slide duo-slide -->

# Looser relationships, in code

<div class="duo">
<div class="duo-col">
<p class="dev-caption">The Service joins two Selectors</p>
<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-service">DispatchService.dispatchWarehouses</span></div>

```apex
List<FulfillmentLine__c> pending =
  lineSelector.selectPendingUnassignedByWarehouseWithOrder(warehouseIds);
if (pending.isEmpty()) {
  return;
}
List<Robot__c> idle =
  robotSelector.selectIdleByWarehouseWithModel(warehouseIds);
```

</div>
</div>
<div class="duo-col">
<p class="dev-caption">A small parent, always needed: …WithModel</p>
<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-selector">RobotsSelector.selectIdleByWarehouseWithModel</span></div>

```apex
fflib_QueryFactory query = newQueryFactory();
RobotModelsSelector.newInstance()
  .configureQueryFactoryFields(query, 'Model__r');
return (List<Robot__c>) Database.query(
  query.setCondition('Warehouse__c IN :warehouseIds AND Status__c = \''
    + Robots.STATUS_IDLE + '\'').toSOQL()
);
```

</div>
</div>
</div>

<!--
Robots and fulfillment lines are each queried by warehouse through their own Selectors; DispatchService matches them.
Robot Model is a small parent dispatch always needs, so RobotsSelector borrows its fields with …WithModel. Still derived: RobotModelsSelector.newInstance().configureQueryFactoryFields(query, 'Model__r').
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
Pick the return shape by the job, not by habit.
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
A count is a query, so it lives in the Selector.
It mirrors Robots.canAcceptWork through the shared Domain constants.
It states WITH USER_MODE itself, because it's static SOQL rather than factory-built.
Returns a map keyed by warehouse: shaped for the caller.
-->

---

<!-- _class: detail-slide code-slide duo-slide -->

# Batch versus Queueable chunking

<div class="duo">
<div class="duo-col">
<p class="dev-caption">QueryLocator → Batch Apex</p>
<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-selector">WarehousesSelector.selectActiveAsQueryLocator</span></div>

```apex
return Database.getQueryLocator(
  newQueryFactory().setCondition(
    'Status__c = \'' + Warehouses.STATUS_ACTIVE + '\''
  ).toSOQL()
);
```

</div>
</div>
<div class="duo-col">
<p class="dev-caption">Cursor → chunked Queueables</p>
<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-selector">FulfillmentLinesSelector.selectPendingByWarehouseAsCursor</span></div>

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
QueryLocator feeds Batch Apex (DispatchPendingJob.start); the batch job never writes SOQL.
Database.Cursor walks up to 50M rows in chunks across Queueables: fetch(position, count), at most 100 fetches per transaction, serializable.
Same factory, same fields, same mode; only the return shape changes.
The cursor method has no caller: the Selector's job ends at returning the cursor. A chunking Queueable keeps the cursor and its position, fetches the next chunk, and re-enqueues itself. It calls existing logic only through a Service or a Domain.
Unbounded list queries fail past 50,000 rows (slide 7); the QueryLocator and Cursor are the remedy.
Let toSOQL() carry the access mode rather than also passing an AccessLevel to getCursor.
A cursor would suit any Queueable that chunks through large data.
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
A new platform feature is cheap to adopt because queries already have one home.
Run without-paging.apex (one list query holds every robot), then with-paging.apex (pages of two, the quirks, and page 2 again on a fresh cursor).
The Selector returns the cursor; the paging arithmetic belongs to the consumer (here, the script).
Quirk: fetchPage throws "Fetch beyond bound" past the last record, so the consumer shortens the last page.
Quirk: getNextIndex() returns 0 after the last page, so the consumer works out the next index itself.
Quirk: isDone() returned true after every page in our tests; compare the next index with getNumRecords() instead.
Each page request opens a new cursor, so the query runs again. Pages need a total order: Name isn't unique, so the query orders by Name, Id.
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
Fold candidate: drop if time is short.
Selectors inside a real Service: two query lines, zero SOQL in the Service. (A third, orderSelector.selectById, loads the parent orders before marking them in progress.)
-->

---

<!-- _class: detail-slide code-slide duo-slide -->

# The mocking seam

<div class="duo">
<div class="duo-col">
<p class="dev-caption">Composition: real Selectors by default</p>
<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-service">DispatchService.newInstance</span></div>

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
</div>
<div class="duo-col">
<p class="dev-caption">Tests: stub the virtual methods, inject through the constructor</p>
<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-alt">DispatchServiceTest.cls</span></div>

```apex
RobotsSelector robotSelectorMock =
  (RobotsSelector) mocks.mock(RobotsSelector.class);
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
Keeps John Daniel's promise: "you'll see the same thing with selectors next."
virtual Selector methods plus constructor injection make Selectors easy to stub. No interfaces or Application factory required.
Session 5 goes deeper.
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
  * ❌ God-selectors that fetch everything for everyone
* **Composition**
  * ✅ Instances composed through `newInstance()` and constructors; feature Selectors where queries belong together
  * ❌ Static query methods
* **New shapes:** cursors, absorbed without changing the pattern

<!--
A small, safe idea for later: per-transaction memoization, where a Selector remembers results within one transaction instead of asking the same question twice.
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
Fold candidate: could merge into slide 37.
-->

---

<!-- _class: detail-slide promises-slide -->

# Go deeper

* **Matt Gerry** — chapters 12–14 at apex-enterprise-patterns.dev
* **fflib-apex-common** — github.com/apex-enterprise-patterns/fflib-apex-common
* **The Warehouse sample** — this session's repo and README
* **Andy Fawcett** — posts on the Application class (Apr 2026) and Apex Pagination Cursors (Jan 2026)

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
To confirm with Sally: she may prefer to present the series roadmap herself. If so, this slide hands off to her.
-->

---

<!-- _class: title-slide -->

# Thank you!

#### John Storey · Code With Sally
### FFLib Series · Session 004

![Code With Sally](images/codewithsally.png)

---

<!-- _class: detail-slide callers-table-slide -->
<!-- _paginate: false -->

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

<!--
Buffer slide for Q&A: point at this when questions come up about who may call a Selector.
Marp has no built-in hidden slide; it's last, after Thank you, so it's only shown if needed.
-->
