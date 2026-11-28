# Requirements — Agentforce Voice Demo

This document describes **what** we are building for the demo. It is the source of
truth for the fictitious scenario, the sample data, and the functional use cases the
agent must satisfy. For **how** to actually build it (org setup, data loading
mechanics, agent configuration steps), see [`SETUP_GUIDE.md`](./SETUP_GUIDE.md).

## 1. Demo Context

- **Audience**: [CodeWithSally](https://www.youtube.com/@CodeWithSally) YouTube channel.
- **Presenter role**: Developer, building live with Cursor and Claude Code.
- **Environments**:
  | Org alias    | Purpose                                                                                                                         |
  | ------------ | ------------------------------------------------------------------------------------------------------------------------------- |
  | `sally-prep` | SDO sandbox used to build, test, and rehearse everything before the recording.                                                  |
  | `sally-demo` | SDO sandbox used for the live recording. Built **from scratch** during the demo, following what was proven out in `sally-prep`. |
- **Source control**: [git@github.com:dangt85/sally-afv.git](https://github.com/dangt85/sally-afv)

Everything in this repo (metadata, data plans, docs) must be reproducible against a
clean sandbox so the live "from scratch" build in `sally-demo` is a repeat of a
rehearsed script, not a first attempt.

## 2. Fictitious Scenario

### 2.1 Company

**Cairn Outdoor Co.** — "Gear that finds your way."

A direct-to-consumer outdoor and camping equipment retailer headquartered in Bend,
Oregon. Founded in 2011 by a group of backpacking guides, Cairn Outdoor Co. grew from
a single retail storefront into a national e-commerce brand with roughly 40 employees,
selling online and through a small number of wholesale partners.

### 2.2 Vertical / Industry

Outdoor recreation & camping equipment retail (D2C e-commerce with a phone-based
support channel).

### 2.3 Background / Current State

Cairn Outdoor Co. runs its contact center on **Amazon Connect** (telephony/IVR) with
**Salesforce Service Cloud Voice** providing the agent softphone, call controls,
transcription, and screen-pop inside Salesforce. There are two queues, split by
language:

- **Cairn Support – English**
- **Cairn Support – Spanish**

Every call today is handled entirely by a human agent — there is no AI/virtual agent
or self-service IVR deflection. This means agents spend time on high-volume,
low-complexity calls that don't need a human:

- "Where's my order?"
- "What's your return policy?"
- "How do I light my camp stove?" (reading straight out of a PDF manual)

This is expensive and creates long queue times for customers with genuinely complex
issues. Leadership wants to pilot **Agentforce Voice** to auto-resolve the routine
call volume while keeping the same Amazon Connect queues as the escalation path to a
human agent, before deciding whether to eventually replace Amazon Connect with
**Agentforce Contact Center (AFCC)**, Salesforce's native CCaaS offering.

### 2.4 Demo Narrative Arc

1. **Before**: show the current, human-only Voice setup (two queues, no AI).
2. **Build**: stand up an Agentforce (Voice) service agent, backed by real Salesforce
   data (orders, products, knowledge) and product Q&A grounded in real product
   content.
3. **After**: call in, let the agent resolve an order-status question and a product
   FAQ, then trigger an escalation to a human agent in the same Amazon Connect queue,
   and separately show a case getting created when no human is available.

## 3. Sample Data Requirements

All sample data is fictitious. It is loaded via the **Salesforce CLI data import
plan** (`sf data import tree --plan ...`, per Salesforce's SObject Tree Save API) so
that it can be reloaded identically into `sally-prep` and, live, into `sally-demo`.
See `SETUP_GUIDE.md` for the file layout and loading mechanics, including the parts
that fall outside a plain tree import (standard Pricebook activation, Knowledge
article publishing).

### 3.1 Products (with manuals/how-tos as linked files)

A small catalog (~8 products) across categories that plausibly need documentation —
tents, packs, stoves, filters, sleeping bags, headlamps, boots, camp furniture. Each
product must have at least one PDF (manual, troubleshooting guide, or how-to) attached
as a `ContentVersion` linked to the `Product2` record (so the agent's Apex
vector-search retriever has real content to ground answers in).

| Product                    | SKU          | Linked content                                              |
| -------------------------- | ------------ | ----------------------------------------------------------- |
| Alpine Peak 2 Tent         | `TENT-AP2`   | Setup manual; "leaking seams / broken pole" troubleshooting |
| Summit Trail 65 Backpack   | `PACK-ST65`  | Fitting & adjustment guide                                  |
| BlazeLight Camp Stove      | `STOVE-BL1`  | Manual; "won't ignite" troubleshooting                      |
| StreamPure Water Filter    | `FILTER-SP3` | Manual; cleaning/backwashing how-to                         |
| Frostguard 20 Sleeping Bag | `BAG-FG20`   | Care guide (washing/storage)                                |
| TrailBeam 500 Headlamp     | `LAMP-TB500` | Manual; charging troubleshooting                            |
| Ridgeline Hiking Boots     | `BOOT-RL7`   | Sizing guide; waterproofing how-to                          |
| BaseCamp Quad Chair        | `CHAIR-BC4`  | Assembly guide                                              |

### 3.2 Customers (Person Accounts)

Roughly 6 fictitious customers modeled as **Person Accounts**, deliberately mixing
English- and Spanish-preferring customers to mirror the two-queue reality:

| Name            | Preferred language | Location     |
| --------------- | ------------------ | ------------ |
| Maria Alvarez   | Spanish            | Austin, TX   |
| James Whitfield | English            | Portland, OR |
| Linh Tran       | English            | Seattle, WA  |
| Carlos Mendoza  | Spanish            | Miami, FL    |
| Emily Carter    | English            | Denver, CO   |
| Sofia Reyes     | Spanish            | Phoenix, AZ  |

### 3.3 Orders & Order Items

Each customer has 10–20 `Order` records, each with 2–4 `OrderItem` line items (multiple
products per order, multiple orders per customer). Orders carry a realistic mix of
statuses (e.g., Processing, In Transit, Delivered) with an order number, total, and
estimated delivery date, since those are exactly the fields the agent must be able to
report back.

### 3.4 Knowledge Articles

A small set of Knowledge articles covering the FAQs the agent should be able to
answer directly, without needing an order or product lookup:

- Return & Exchange Policy
- Shipping & Delivery Times
- Order Cancellation & Changes
- Warranty Policy
- Price Match Guarantee
- Cairn Rewards (loyalty program)
- Store Locations & Hours
- How to Reach a Human Agent

## 4. Agent Use Cases (Functional Requirements)

The Agentforce Voice agent must support the following:

1. **Order lookup** — Given identifying information from the caller, look up a
   standard `Order` and report back order number, total, status, and estimated
   delivery date. If the caller's ANI didn't resolve to exactly one Account (no
   match, or more than one), the agent must not accept a bare order number as
   proof — it also requires the date the order was placed, verified against the
   record, before it will disclose anything; if the caller can't provide both or
   they don't match, the agent escalates to a human rather than retrying with
   other identifiers. That verified-but-unidentified path also gets a
   deliberately minimal reply (fulfillment status and estimated delivery date
   only, no name, no order number/total readback) rather than the personalized
   full detail an ANI-verified caller gets. (Grounding/retrieval approach: §5.1.)
2. **Company FAQs** — Answer frequently asked questions about Cairn Outdoor Co.
   (returns, shipping, warranty, price match, loyalty, store hours) grounded in the
   Knowledge articles above. (Grounding/retrieval approach: §5.2.)
3. **Product Q&A** — Answer questions about products (specs, compatibility,
   troubleshooting, how-tos) grounded in the linked PDF manuals/guides, not just
   free-form generation. (Grounding/retrieval approach: §5.3.)
4. **Escalation to a human agent** — If a question can't be answered by the agent,
   escalate the live call to a human agent in the appropriate queue.
5. **Case creation as a fallback** — If a question can't be answered _and_ no human
   agent is available to escalate to, create a `Case` capturing the caller's issue so
   a human can follow up later.

## 5. Grounding & Retrieval Approaches

Order lookup and company FAQ are each built in stages of increasing sophistication,
so the demo shows _why_ each upgrade matters, not just the final state. Product Q&A
ships as a single approach.

### 5.1 Order Lookup

1. **Flow** — a declarative Flow action looks up `Order`/`OrderItem` by
   customer-provided identifiers. Fastest path to a working `order_lookup` topic.
2. **Apex (local SOQL)** — the Flow action is replaced by an Apex action running the
   equivalent SOQL query directly against Salesforce.
3. **Data360 Data Graph** — the Apex action is replaced by a Data Cloud data graph
   built over Account/Order/OrderItem/Product2 data ingested from Salesforce CRM.
   This is the only place in the demo a data graph is used — the structured,
   multi-object shape of an order (customer + line items + products) is what a data
   graph is suited for. Reaching this stage requires a preparation step: ingest the
   CRM data into Data Cloud and manually map it to Data Cloud's Standard Data Model
   (e.g. Individual, Sales Order, Sales Order Product, Product) — deliberately **not**
   using Data Cloud's built-in Salesforce CRM connector/data kit, so the ingestion and
   mapping mechanics are visible on camera — before building the data graph on top of
   the mapped objects. The data graph is then queried by an Apex invocable action
   (`OrderLookupDataGraph`) wired into the `order_lookup` topic. A data graph has **no**
   no-code retriever action — unlike §5.2/§5.3's search-index retrievers, it is
   reachable only through the Data Graph Query API — so this stage swaps one Apex
   action for another, and the interesting change is where the data comes from, not
   how the topic is wired. See `SETUP_GUIDE.md` §6.1.3 for the constraints that shape
   the implementation.

### 5.2 Company FAQ

1. **Prompt Template + Data Cloud retriever** — a Prompt Template action with a
   built-in Data Cloud/Knowledge retriever, grounded on the Knowledge articles in
   §3.4.
2. **Custom Apex vector-search retriever** — the Prompt Template's retriever call is
   replaced by a custom Apex action that queries Data Cloud's vector search index
   directly, skipping the Prompt Template retriever's orchestration overhead.
   Demonstrated as a "here's what's happening under the hood, and why it's faster"
   comparison segment.

### 5.3 Product Q&A

**Custom Apex hybrid-search retriever** — a single approach: a custom Apex action
queries a Data Cloud **hybrid** (keyword + vector) search index directly over the
product catalog's linked manual/how-to content (§3.1), grounding answers in the
actual PDF content rather than free-form generation. Hybrid, not pure vector, so
exact troubleshooting phrases ("won't ignite," "leaking seams") aren't under-ranked
by semantic similarity alone — see `SETUP_GUIDE.md` §6.3 for the build detail and
the "the wizard defaults to Vector" gotcha. No data graph is used for this use case.

## 6. Voice Channel: Telephony Approach

Two approaches are in scope; the primary reflects Cairn's actual current-state stack,
the alternate is what they're evaluating next.

- **Primary — Amazon Connect + Salesforce Voice**: matches Cairn's real current call
  center stack. The demo shows the AI service agent slotting into the existing Amazon
  Connect queues/IVR and Salesforce Service Cloud Voice, escalating into the same
  queues agents already work today.
- **Alternate — Agentforce Contact Center (AFCC)**: Salesforce's native CCaaS
  offering, shown as the "what if you moved off Amazon Connect entirely" story.

## 7. Out of Scope

- Real payment processing, shipping integrations, or any live third-party carrier
  data — delivery estimates are static sample data.
- Any real customer PII — all customers, orders, and contact details are fictitious.
- Production deployment — this project targets sandbox orgs only.

## 8. Success Criteria

The demo is successful if, live in `sally-demo`, built from scratch on camera:

- [ ] A caller can ask about an existing order and get order number, total, status,
      and estimated delivery date back correctly.
- [ ] A caller can ask a company FAQ (e.g., return policy) and get a correct,
      Knowledge-grounded answer.
- [ ] A caller can ask a product question (e.g., "how do I clean my water filter?")
      and get an answer grounded in the actual linked manual, via the Apex
      vector-search retriever.
- [ ] A caller can ask something the agent can't answer and be escalated live into
      the correct Amazon Connect queue.
- [ ] A caller can ask something unanswerable while no human agent is available and
      have a Case created on their behalf.
- [ ] The Amazon Connect + Salesforce Voice integration (or the AFCC alternate, if
      that's the version shown) is visibly working end-to-end on the call.
