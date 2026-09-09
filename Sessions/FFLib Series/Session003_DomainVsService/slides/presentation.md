---
marp: true
theme: session
paginate: true
lang: en
html: true
---

<!-- _class: title-slide -->

# [Session Title]
### [Session Sub Title]
#### [Series Name] · Session [Number]

#### [Name]
###### [Organisation]

<div class="template-logo">[Logo]</div>

---

<!-- _class: detail-slide about-slide -->

<div class="about-split">
<div class="about-copy">

# About me

##### [Role] | [Organisation] | [Previous Role]

* **[Area of Expertise]** — [Short description]
* **[Experience or Achievement]** — [Short description]
* **[How I Help]** — [Short description]

<!-- -->

* [Personal introduction or closing statement]

</div>
<div class="about-aside">
<div class="about-logo-wrap">
<div class="template-logo">[Organisation Logo]</div>
</div>
<div class="about-book template-image">[Photo / Book / Project Image]</div>
</div>
</div>

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
<tr class="current"><td><span class="check"></span></td><td>Session #3 — Domain vs Service: Where Should Your Apex Logic Live?</td></tr>
<tr><td><span class="check"></span></td><td>Session #4 — Query Logic as a First-Class Architecture Concern</td></tr>
<tr><td><span class="check"></span></td><td>Session #5 — Mocking in Apex: Why It Changes Everything</td></tr>
<tr><td><span class="check"></span></td><td>Session #6 — Enterprise-Scale Apex Across Multiple Packages</td></tr>
</tbody>
</table>

---

<!-- _class: detail-slide service-layer-def-slide -->

# [Session Title]

<div class="service-layer-graphic">
  <div class="template-image">[Session Opening Image]</div>
</div>

<!-- TODO: Replace the title and image with the opening idea for this session. -->

---

<!-- _class: detail-slide quote-slide service-quote-slide -->

# [Session Concept]

<blockquote>
[Add a short definition or statement that introduces the session.]
</blockquote>

<p class="quote-source">[Author / source, if quoting]</p>


<!-- TODO: Add the session definition; cite the source if using a quotation. -->

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

<!-- _class: detail-slide checklist-slide -->

# [Session Title]

<img class="checklist-gears" src="images/pattern-layers-gears.svg" alt="Domain, Selector, and Service layers as interlocking gears" />

<ul class="checklist">
<li>[Session Title]</li>
<li class="current">Recap - Service Layer<span class="check"></span></li>
<li>Domain Principles<span class="check"></span></li>
<li>Warehouse App Objects and Behaviors<span class="check"></span></li>
<li>Warehouse App Domain vs Trigger Code<span class="check"></span></li>
</ul>

<!-- Pattern section: Domain for Session 003. For another session, use Selector Principles or [Other] Principles and replace the overview/checklist slides. -->

---

<!-- _class: detail-slide promises-slide -->

# Recap - Service Layer

* **Task-oriented** — a Service represents a feature; its methods expose business tasks.
  * `DispatchService.dispatchWarehouses(...)`
* **Reusable entry point** — LWC, REST, Flow, Agent actions, and Batch call the same Service.
* **Coordinates the work** — Selectors query; Domains apply object-specific behaviour.
* **Owns the transaction** — create a Unit of Work, register changes, then commit once.

<!-- Source: Session 002, Service Task Orientated Logic, Services have many Consumers, Consumers and Dependencies, and Leveraging Unit of Work. -->

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

<!-- _class: detail-slide diagram-slide -->

# Services have many Consumers

![Hub and spoke: UI controllers, web and REST services, invocable methods, agent actions, email, batch, scheduled, and queueable all call one Apex Service](images/apex-service-entry-points.svg)

---

<!-- _class: detail-slide checklist-slide -->

# [Session Title]

<img class="checklist-gears" src="images/pattern-layers-gears.svg" alt="Domain, Selector, and Service layers as interlocking gears" />

<ul class="checklist">
<li>[Session Title]</li>
<li>Recap - Service Layer<span class="check">✅</span></li>
<li class="current">Domain Principles<span class="check"></span></li>
<li>Warehouse App Objects and Behaviors<span class="check"></span></li>
<li>Warehouse App Domain vs Trigger Code<span class="check"></span></li>
</ul>

<!-- Pattern section: Domain for Session 003. For another session, use Selector Principles or [Other] Principles and replace the overview/checklist slides. -->

---

<!-- _class: detail-slide domain-logic-slide -->

# Domain ➡️ Object Orientated Logic

* A Domain class combines **data and behavior** of an object
  * Opportunities — `Opportunities.newInstance(List<Opportunity> opportunities)`
  * Accounts — `Accounts.newInstance(List<Account> accounts)`
  * Base domain classes include common behaviors — `AbstractChargeable`
  * Top level domain classes extend — `TrainingWorkItems.cls`, `DeveloperWorkItems.cls`
* **Methods** are ways to interact with the object's behaviors, `opportunities.applyDiscount`, `workItem.updateCostOfHoursWorked`
* Additional **methods** can respond to data manipulation scenarios (Triggers), `opportunities.onBeforeUpdate`, `opportunities.onValidate`
  * Or can be split into a **sidecar handler** class if you prefer, `new OpportunitiesTriggerHandler().onBeforeUpdate`

<!--
Domain is data plus behavior. Methods are the object's tasks. Trigger / CRUD responses can live on the Domain, or in a sidecar handler. Combined is still fine. Service callers come later.
-->

---

<!-- _class: detail-slide promises-slide -->

# Domain ☑️ Checklist

* Record collections — wrap many records, not one
  * ✅ `Opportunities.newInstance(List<Opportunity> opportunities)`
  * ❌ `Opportunities.newInstance(Opportunity opportunity)`
* In-memory behavior — mutate records; no DML
  * ✅ `void applyDiscount(Decimal discountPercentage)`
  * ❌ `void applyDiscount() { update records; }`
* **Records encapsulated** — don't have callers pass them in
  * ✅ `opportunities.applyDiscount(10)`
  * ❌ `applyDiscount(Opportunity opportunity)`
* **Trigger logic** — Optional trigger handler sidecar class
* **Object-oriented** — data and behavior stay together
* **Security** — SOQL and DML are user mode, unless Apex Trigger context

<!--
Domain wraps a list via newInstance. applyDiscount mutates in memory; Service or Handler commits via getRecords. Methods use the encapsulated records — callers do not pass them in. Trigger CRUD can stay on the Domain or move to an optional sidecar handler. SOQL and DML stay user mode unless Apex Trigger context.
-->

---

<!-- _class: detail-slide promises-slide service-evolution-slide -->

# Domain 🔁 Evolved

* **[Evolution Topic 1]** — [What has changed]
  * ✅ [Current approach and why it helps]
  * ❌ [Earlier approach or limitation]
* **[Evolution Topic 2]** — [What has changed]
  * ✅ [Current approach and why it helps]
  * ❌ [Earlier approach or limitation]
* **[Evolution Topic 3]** — [Guidance to explore]
  * [Example or supporting reference]

<p class="session-callout"><span class="info-mark">ⓘ</span> <strong>[Related Topic / Session]</strong><span class="session-callout-sub">[Optional follow-up or supporting reference]</span></p>

<!-- TODO: Decide which Domain changes to cover. Layout copied from Session 002's Service Evolution slide; no recommendations asserted yet. -->

---

<!-- _class: detail-slide code-slide pair-code-slide service-ide-slide -->

# Domain — Code Example 1

<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-domain">[DomainClass.methodName]</span></div>

```apex
// [Show how the Domain wraps a collection of records.]
//
// [Add the focused Apex example.]
// [Highlight the key behaviour.]
```

</div>

<!-- TODO: Replace the example. Keep the inherited IDE frame and layer-coloured tab. -->

---

<!-- _class: detail-slide code-slide pair-code-slide service-ide-slide -->

# Domain — Code Example 2

<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-domain">[DomainClass.methodName]</span></div>

```apex
// [Show an object-specific behaviour that changes records in memory.]
//
// [Add the focused Apex example.]
// [Highlight the key behaviour.]
```

</div>

<!-- TODO: Replace the example. Keep the inherited IDE frame and layer-coloured tab. -->

---

<!-- _class: detail-slide code-slide pair-code-slide service-ide-slide -->

# Domain — Code Example 3

<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-domain">[DomainClass.methodName]</span></div>

```apex
// [Show how a caller invokes the Domain behaviour.]
//
// [Add the focused Apex example.]
// [Highlight the key behaviour.]
```

</div>

<!-- TODO: Replace the example. Keep the inherited IDE frame and layer-coloured tab. -->

---

<!-- _class: detail-slide code-slide duo-slide domain-examples-slide -->

# Trigger Handlers vs Domain

<div class="trigger-callout trigger-callout-south">[Explain the responsibility of a Domain and the optional separate Trigger Handler.]</div>

<div class="duo">
<div class="duo-col">
<p class="dev-caption">Service Layer → Domain</p>
<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-domain">[DomainClass].cls</span></div>

```apex
// [Domain behaviour example]
// [Wrap records and expose object behaviour.]
// [Add a focused method example.]
```

</div>
</div>
<div class="duo-col-stack">
<div class="duo-col">
<p class="dev-caption">Apex Trigger → Trigger Handler → Domain</p>
<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-domain">[TriggerHandlerClass].cls</span></div>

```apex
// [Trigger Handler example]
// [Respond to a trigger event.]
// [Delegate to the Domain where appropriate.]
```

</div>
</div>
<div class="trigger-callout trigger-callout-west"><span class="callout-west"></span><span class="callout-west-fill"></span>[Add the key distinction or design trade-off.]</div>
</div>
</div>

<!-- TODO: Develop the comparison and examples. Layout copied from Session 001. -->

---

<!-- _class: detail-slide checklist-slide -->

# [Session Title]

<img class="checklist-gears" src="images/pattern-layers-gears.svg" alt="Domain, Selector, and Service layers as interlocking gears" />

<ul class="checklist">
<li>[Session Title]</li>
<li>Recap - Service Layer<span class="check">✅</span></li>
<li>Domain Principles<span class="check">✅</span></li>
<li class="current">Warehouse App Objects and Behaviors<span class="check"></span></li>
<li>Warehouse App Domain vs Trigger Code<span class="check"></span></li>
</ul>

<!-- Pattern section: Domain for Session 003. For another session, use Selector Principles or [Other] Principles and replace the overview/checklist slides. -->

---

<!-- _class: detail-slide promises-slide -->

# Warehouse App Objects and Behaviors

* **[Principle one]**
  * ✅ [Example that follows the principle]
  * ❌ [Example to avoid]
* **[Principle two]**
  * ✅ [Example that follows the principle]
  * ❌ [Example to avoid]
* **[Principle three]** — [Short explanation]

<!-- TODO: Replace the bracketed content. Use the inherited checklist layout. -->

---

<!-- _class: detail-slide pair-code-slide service-ide-slide -->

# Warehouse App Objects and Behaviors

<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-service">[ClassName.methodName]</span></div>
<div class="vscode-prose">
<p class="walk-sig walk-sig-start"><span class="walk-kw">public virtual void</span> [methodName]([parameters]) {</p>

1. <span class="walk-layer walk-layer-service">Service</span> — [Coordinate the operation]
2. <span class="walk-layer walk-layer-selector">Selector</span> — [Load the records]
3. <span class="walk-layer walk-layer-domain">Domain</span> — [Apply the object-specific behaviour]
4. <span class="walk-layer walk-layer-service">Service</span> — [Complete the transaction]

<p class="walk-sig walk-sig-end">}</p>
</div>
</div>

<!-- TODO: Replace the signature and walkthrough steps. -->

---

<!-- _class: detail-slide code-slide pair-code-slide service-ide-slide dispatch-gutter-slide -->

# Warehouse App Objects and Behaviors

<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-service">[ClassName.methodName]</span></div>

```apex
// [Paste the focused Apex example here.]
//
// [Introduce the records or inputs.]
// [Show the behaviour this section explains.]
// [Highlight the important decision.]
```

</div>

<!-- TODO: Replace the example. Keep the inherited IDE frame and layer-coloured tab. -->

---

<!-- _class: detail-slide checklist-slide -->

# [Session Title]

<img class="checklist-gears" src="images/pattern-layers-gears.svg" alt="Domain, Selector, and Service layers as interlocking gears" />

<ul class="checklist">
<li>[Session Title]</li>
<li>Recap - Service Layer<span class="check">✅</span></li>
<li>Domain Principles<span class="check">✅</span></li>
<li>Warehouse App Objects and Behaviors<span class="check">✅</span></li>
<li class="current">Warehouse App Domain vs Trigger Code<span class="check"></span></li>
</ul>

<!-- Pattern section: Domain for Session 003. For another session, use Selector Principles or [Other] Principles and replace the overview/checklist slides. -->

---

<!-- _class: detail-slide diagram-slide -->

# Warehouse App Domain vs Trigger Code

<div class="template-image">[Diagram / Illustration]</div>

<!-- TODO: Replace this placeholder with the section visual. -->

---

<!-- _class: detail-slide code-slide pair-code-slide service-ide-slide dispatch-gutter-slide -->

# Warehouse App Domain vs Trigger Code

<div class="vscode">
<div class="vscode-tabs"><span class="vscode-tab vscode-tab-service">[ClassName.methodName]</span></div>

```apex
// [Paste the focused Apex example here.]
//
// [Introduce the records or inputs.]
// [Show the behaviour this section explains.]
// [Highlight the important decision.]
```

</div>

<!-- TODO: Replace the example. Keep the inherited IDE frame and layer-coloured tab. -->

---

<!-- _class: detail-slide promises-slide -->

# Warehouse App Domain vs Trigger Code

* **[Scenario one]**
  * [Question for the audience]
* **[Scenario two]**
  * [Question for the audience]
* **[Discussion takeaway]**
  * [Reveal or summarise the reasoning]

<!-- TODO: Replace the discussion prompts. -->

---

<!-- _class: detail-slide checklist-slide -->

# [Session Title]

<img class="checklist-gears" src="images/pattern-layers-gears.svg" alt="Domain, Selector, and Service layers as interlocking gears" />

<ul class="checklist">
<li>[Session Title]</li>
<li>Recap - Service Layer<span class="check">✅</span></li>
<li>Domain Principles<span class="check">✅</span></li>
<li>Warehouse App Objects and Behaviors<span class="check">✅</span></li>
<li>Warehouse App Domain vs Trigger Code<span class="check">✅</span></li>
</ul>

<!-- Pattern section: Domain for Session 003. For another session, use Selector Principles or [Other] Principles and replace the overview/checklist slides. -->

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
<tr class="current"><td><span class="check"></span></td><td>Session #4 — Query Logic as a First-Class Architecture Concern</td></tr>
<tr><td><span class="check"></span></td><td>Session #5 — Mocking in Apex: Why It Changes Everything</td></tr>
<tr><td><span class="check"></span></td><td>Session #6 — Enterprise-Scale Apex Across Multiple Packages</td></tr>
</tbody>
</table>

---

<!-- _class: title-slide -->

# Thank you!

#### Andrew Fawcett · Code With Sally
### FFLib Series · Session 003

![Code With Sally](images/codewithsally.png)

