# Build Recipe — Cairn Compass Voice Agent

This document is the **build narrative** for `feature/data360-enhancement`: what
existed before this branch, what exists now, and the concrete recipe — deploys, data
loads, and manual Data Cloud (Data360) configuration — to reproduce it from a clean
sandbox. It's written for a developer or architect picking up this branch cold.

It complements, and deliberately doesn't replace, the two docs that already govern
this repo's ongoing work:

- [`REQUIREMENTS.md`](./REQUIREMENTS.md) — the source of truth for the demo scenario
  and functional requirements, kept current as the build evolves.
- [`SETUP_GUIDE.md`](./SETUP_GUIDE.md) — the living technical reference, with every
  confirmed gotcha, error message, and API quirk hit along the way. This recipe
  points into specific `SETUP_GUIDE.md` sections rather than re-deriving that detail.

This document itself is a point-in-time snapshot of this branch's work and won't be
kept in sync the way the other two are.

## 1. Before → After

**Before this branch:** a freshly scaffolded Agentforce DX project. The starter
template's sample agent ("Local Info Agent") and its example Apex/Flow/Prompt
Template components were the only agent-shaped thing in the repo — no Cairn-specific
agent, no grounding data, no Data Cloud configuration of any kind.

**After this branch:** `Cairn_Compass`, a voice agent with a router and five
subagents, backed by three different grounding mechanisms — a Data Cloud data graph,
and two Data Cloud vector/hybrid search indexes — plus the sample data, Apex, Flow,
and permission-set metadata needed to run all of it end-to-end against a real
Amazon Connect + Salesforce Service Cloud Voice call.

|                       | Before                                          | After                                                                                                                                                      |
| --------------------- | ----------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Agent                 | Starter "Local Info Agent"                      | `Cairn_Compass` — router + 5 subagents (`order_lookup`, `company_faq`, `product_qa`, `escalate_to_agent`, `create_case`)                                   |
| Order lookup          | —                                               | Data Cloud **data graph** (`Compass_Order_Lookup`), queried via Apex (`OrderLookupDataGraph`)                                                              |
| Company FAQ           | —                                               | Data Cloud **vector search index** (`Cairn_Knowledge`), queried via Apex (`CompanyFAQVectorSearch`)                                                        |
| Product Q&A           | —                                               | Data Cloud **hybrid search index** (`Compass_Product_QnA`), queried via Apex (`ProductQnAHybridSearch`)                                                    |
| Caller identification | —                                               | ANI → Person Account phone match (`PersonAccountPhoneLookup`) sets `VoiceCall.Account__c`, surfaced to the agent as a linked variable                      |
| Voice channel         | Amazon Connect + SCV assumed, not built against | `Cairn_Inbound`/`Cairn_Outbound` Flows wired to a real backed-up Amazon Connect contact flow                                                               |
| Sample data           | None                                            | ~8 products w/ linked PDF manuals, 6 Person Accounts, 300+ orders/line items, bilingual Knowledge articles — loaded via `sf data import tree`              |
| Data Cloud config     | Not provisioned                                 | 4 Data Streams (Account/Order/OrderItem/Product2) hand-mapped to the Standard Data Model, 1 data graph, 2 search indexes, 1 file-attachment content bundle |

Everything Data Cloud-side (Data Streams, Standard Data Model mappings, the data
graph, both search indexes) is **manual UI configuration, not deployable metadata** —
none of it is checked into `force-app`. Only the Apex/Flow/Agent Script that _queries_
it is source-controlled. Reproducing this build in a fresh org means replaying the
manual steps below in Data Cloud Setup, not just running `sf project deploy start`.

## 2. Architecture at a glance (final state)

```
Caller → Amazon Connect (ANI) → Cairn_Inbound (Flow)
                                   │
                                   ├─ PersonAccountPhoneLookup (Apex, SOSL phone match)
                                   │     └─ single match → VoiceCall.Account__c, .ContactName__c
                                   │
                                   └─ routeWork → Cairn_Compass (agent, live channel)

Cairn_Compass
 └─ agent_router  (classifies intent, transitions — never answers directly)
     ├─ order_lookup ────────► apex://OrderLookupDataGraph ──► Data Graph: Compass_Order_Lookup
     │                                                          (Account → Sales Order → Sales Order
     │                                                           Product → Product, rooted at Account)
     ├─ company_faq ─────────► apex://CompanyFAQVectorSearch ─► Search Index: Cairn_Knowledge
     │                                                          (over ssot__KnowledgeArticleVersion__dlm)
     ├─ product_qa ───────────► apex://ProductQnAHybridSearch ─► Search Index: Compass_Product_QnA
     │                                                          (over ssot__ContentDocumentVersion__dlm)
     ├─ escalate_to_agent ────► @utils.escalate ────────────────► Cairn_Outbound (Flow) → Amazon Connect queue
     └─ create_case ──────────► flow://Cairn_Create_Case ───────► Case
```

Each of `order_lookup` and `company_faq` reached this final shape through an earlier,
intentionally simpler stage (Flow, then Prompt Template) — see §4.4 and §4.6.
`product_qa` shipped as a single stage.

## 3. Prerequisites

Same as `SETUP_GUIDE.md` §1 — two Agentforce- and Data Cloud-enabled sandboxes
(`sally-prep`, `sally-demo`), Person Accounts enabled, Amazon Connect wired up via
Salesforce Service Cloud Voice, `sf` CLI current. Authorize both orgs before starting:

```bash
sf org login web --alias sally-prep
sf org login web --alias sally-demo
```

Everything below is written against `sally-prep`; repeat verbatim against
`sally-demo` for the live build.

## 4. The Recipe

### 4.1 Deploy the metadata baseline

```bash
sf project deploy start --target-org sally-prep
```

This deploys everything source-controlled: the `Cairn_Compass` agent bundle, all
Apex classes, all four Flows, the custom fields (`Order.Fulfillment_Status__c`,
`Order.Estimated_Delivery_Date__c`, `Account.Preferred_Language__c`,
`VoiceCall.Account__c`, `VoiceCall.ContactName__c`), and both permission sets
(`Cairn_Voice_Agent`, `Cairn_Data_Load`).

Assign the data-load permission set once per org before loading sample data (new
fields deploy with no FLS granted to any profile):

```bash
sf org assign permset --target-org sally-prep --name Cairn_Data_Load
```

### 4.2 Load sample data

```bash
data/scripts/load-data.sh sally-prep
```

One orchestrator script loads, in order: Products (with linked PDF `ContentVersion`s
inserted in the same tree-import run so `FirstPublishLocationId` resolves), Standard
Pricebook activation + PricebookEntries (org-specific id, resolved and templated at
run time), Person Accounts (record type id resolved the same way), Orders +
OrderItems (activated from Draft afterward, since the API rejects inserting
`Activated` directly), and Knowledge articles (loaded Draft, published separately via
`KbManagement.PublishingService`). Full mechanics, including the reasons each step
can't be a plain tree import: `SETUP_GUIDE.md` §4.

This is **not idempotent** — re-running against a non-empty org duplicates
everything (`SETUP_GUIDE.md` §10).

### 4.3 Scaffold the agent

Author `Cairn_Compass` as an Agent Script (`AiAuthoringBundle`) replacing the removed
starter template, one topic per use case:

- `agent_router` — classifies caller intent, transitions to exactly one subagent per
  turn, never answers directly itself.
- `order_lookup`, `company_faq`, `product_qa` — the three grounded use cases.
- `escalate_to_agent`, `create_case` — reached only as hand-offs from the three above,
  never routed to directly.
- `off_topic`, `unclear_request` — guardrail subagents for out-of-scope and ambiguous
  requests.

Voice-channel system instructions (short turns, no monologuing, handle interruptions
cleanly, never re-ask for information already given, warm-but-brief personality,
anti-prompt-injection / no-instruction-disclosure guardrails) live in the top-level
`system.instructions` block and apply across every subagent. See
`force-app/main/default/aiAuthoringBundles/Cairn_Compass/Cairn_Compass.agent` for the
current instruction text verbatim.

At this stage, `order_lookup` and `create_case` were wired to real Flow actions
(§4.4, §4.5); `company_faq` and `product_qa` were left as documented placeholders
until their Data Cloud dependencies existed (§4.6, §4.7). A new `Cairn_Voice_Agent`
permission set was created to hold the agent's runtime user's access, growing with
each stage (§4.8).

Preview in simulated mode before wiring live data:

```
AFDX: Preview This Agent   (VS Code command palette)
```

### 4.4 Order lookup — stage 1: Flow

First working version — a declarative Flow (`Cairn_Order_Lookup`) queries
`Order`/`OrderItem` by customer-provided order number, or name + phone/email,
returning order number, total, fulfillment status, and estimated delivery date. This
established the topic's input/output contract that every later stage kept.

_(This branch actually skipped a separate "stage 2: Apex/SOQL" swap that
`REQUIREMENTS.md` §5.1 describes as the intermediate step, and went straight from
the Flow to the Data Cloud data graph in §4.9 below.)_

### 4.5 Caller identification (ANI → Person Account) and escalation/case fallback

Built alongside stage-1 order lookup, since none of it depends on Data Cloud:

- **`VoiceCall.Account__c`** (new lookup field) and **`PersonAccountPhoneLookup`**
  (Apex, SOSL phone search across Person Account phone fields) — `Cairn_Inbound`
  calls the Apex on every inbound call; on a single match it sets
  `VoiceCall.Account__c` and `VoiceCall.ContactName__c`, then routes the call to
  `Cairn_Compass`. Multiple or zero matches leave both fields blank — the caller is
  treated as unidentified.
- **`escalate_to_agent`** — invokes `@utils.escalate`, which routes into
  `Cairn_Outbound` (an `OmniChannelFlow`-type routing flow) to transfer the live call
  to a human specialist queue.
- **`create_case`** — a Flow action (`Cairn_Create_Case`) creating a `Case` from a
  short caller-issue summary plus name/phone/email, reached only when
  `escalate_to_agent` couldn't connect a live specialist.

A later fix (commit `301df39`) corrected a same-turn invocation bug: both
`order_lookup`'s hand-off and `escalate_to_agent` were telling the caller "connecting
you now" as a text-only turn with no tool call attached, leaving them on hold until
they spoke again. The reasoning instructions now require the hand-off/transfer action
to fire in the _same_ turn as the sentence announcing it — confirmed 3/3 via
`sf agent preview` traces (`tool_invocations` no longer `null` on that turn).

### 4.6 Voice channel: Amazon Connect wiring

The existing Amazon Connect contact flow (`Sample_SCV_Inbound_Flow`) — the
"before" state's actual current call routing — was backed up into the repo
(`aws/connect-flows/`) before any changes, so the pre-agent baseline is reproducible
and diffable. `Cairn_Inbound`/`Cairn_Outbound` (Salesforce Flows, §4.5) are what
`Cairn_Compass`'s `connection telephony` block (`outbound_route_name:
"flow://Cairn_Outbound"`) actually drives at the Salesforce Service Cloud Voice
layer.

### 4.7 Data Cloud data graph — order lookup, stage 2

Replaces the Flow action with a Data Cloud data graph, closing the gap where an
ANI-identified caller still had to repeat identifying information the platform
already had. Three parts, in order:

**1. Ingest & map (Data Cloud → Data Streams → Data Model, manual UI work, not
metadata):**

- Activate the four Data Streams for `Account`, `Order`, `OrderItem`, `Product2`
  (standard Salesforce Data Cloud connector, streaming ingestion).
- Manually map each to the Standard Data Model — **deliberately skipping** the
  pre-built "Sales and Service Cloud" data kit's automatic mapping, so the mapping
  decisions are visible rather than hidden behind defaults:
  - `Account` → `Account` DMO (`ssot__Account__dlm`) — was already mapped in this
    org from prior CRM Data Kit scaffolding.
  - `Order` → `Sales Order` DMO (`ssot__SalesOrder__dlm`): map `Order.AccountId` onto
    **`Bill To Account`** (`ssot__BillToAccountId__c`), not `Ship To Contact` — this
    is what auto-creates the `Sales Order` → `Account` relationship the graph needs.
    Add `Order.Fulfillment_Status__c`/`Estimated_Delivery_Date__c` as custom fields
    on the DMO during mapping (no standard counterpart). **`Order.EffectiveDate`
    maps to `Order Start Date`** (`ssot__OrderStartDate__c`) — not `Activated Date`
    or `Created Date`, both of which are identical bulk-load timestamps across every
    seeded order and don't reflect the real order date.
  - `OrderItem` → `Sales Order Product` DMO (`ssot__SalesOrderProduct__dlm`) — mapped
    cleanly, no gotchas.
  - `Product2` → `Product` DMO (`ssot__Product__dlm`).
- Confirm the mapping in Data Explorer (query the `Sales Order` DMO, spot-check a few
  rows against core `Order` via `sf data query`) before building anything on top of
  it.

**2. Build the data graph (Data Cloud → Data Graphs → New, **Standard** type — not
Real-Time, which serves a different Web/Mobile SDK personalization use case, not the
Agent Builder retriever path):**

- Root: **`Account`** — not `Individual` (planned originally, but `Individual`'s
  primary key was locked in this sandbox; `Account` achieves the same thing more
  directly, since `VoiceCall.Account__c` is already an Account id with no extra hop).
- Relationship chain: `Account` → `Sales Order` (1:many, via the `Bill To Account`
  relationship) → `Sales Order Product` (1:many) → `Product` (many:1 lookup).
- Fields projected: `Account` (`Id`, `Name`); `Sales Order` (order number, total,
  fulfillment status, estimated delivery date, `Order Start Date`); `Sales Order
Product` (quantity, unit price — nice-to-have, not required by the current output
  contract); `Product` (`Name`).
- On the `Sales Order` node's **Filters tab → Sort and Limit**: `Sort Field: Order
Start Date`, `Sort Order: Descending` — this, not any graph-level setting, is what
  makes "most recent order" resolvable.
- **There is no separate "lookup keys" configuration screen** in this builder,
  despite the Data Graph API's own docs describing primary/secondary lookup keys.
  Empirically, **only the root object's primary key is queryable** — confirmed via
  Data Cloud's Data Explorer, which lists graph rows keyed by `Account Id` with no
  other filter option at all. A caller-facing `OrderNumber` lookup is _not_
  independently queryable through this graph; the order-number path (§4.9's Apex)
  works around this by resolving an order number to its `Account Id` via a plain
  SOQL query first, then querying the graph by that id.
- Name it exactly **`Compass_Order_Lookup`** (API name) — this is a hardcoded string
  on the consuming Apex side, not just documentation. Publish/activate. Refreshes on
  a scheduled ~1 hour cadence.
- Sanity-check directly in Data Explorer for 2–3 known accounts before wiring the
  agent, cross-checked against `sf data query` on core `Order`.

**3. Wire it up (`OrderLookupDataGraph.cls` + `Cairn_Compass.agent`):**

There is **no no-code retriever action for a data graph** — Setup → Retrievers only
offers a search-index retriever (needs a DMO with a vector search index, which a data
graph doesn't have). A data graph is reachable only through the Data Graph Query API,
so `order_lookup_action` targets `apex://OrderLookupDataGraph`, which calls
`ConnectApi.CdpQuery.getDataGraphData("Compass_Order_Lookup", accountId, "default")`.
Two API-shape gotchas worth knowing before writing against it, and one design
decision, all detailed in `SETUP_GUIDE.md` §6.1.3:

- The returned rows are raw Gson maps — calling any `Map` method on one faults the
  Apex interpreter uncatchably. `String.valueOf(row)` plus `JSON.deserializeUntyped`
  is the safe path (`OrderLookupDataGraph.parseRow`).
- An Apex `Decimal` output must be declared `lightning__numberType` in the `.agent`
  file, not `lightning__currencyType` (the Flow-era type is rejected at runtime).
- **The known-caller path is pre-fetched deterministically, not left to the LLM.**
  `order_lookup`'s `before_reasoning` hook runs the action whenever
  `@variables.AccountId` is set and stores the result in
  `@variables.known_order_summary`, interpolated into the reasoning prompt before the
  model reasons. Left to decide for itself, the reasoning LLM either narrated "let me
  pull that up" with no tool call, or fabricated plausible order numbers — several
  rounds of stricter instruction wording didn't fix it; putting the real data in the
  prompt up front did.
- **A caller the ANI didn't identify still can't resolve an order by number alone.**
  `OrderDateInput` (the date the order was placed) is required alongside
  `OrderNumberInput` for this path; a match found this way gets a deliberately
  minimal reply (fulfillment status + delivery date only, no name/number/total
  readback), since the caller still isn't personally verified the way an ANI match
  establishes.

`Cairn_Order_Lookup` (the Flow) was left in place rather than deleted once the data
graph path was proven — see §5, Known Gaps.

### 4.8 Company FAQ — stage 1: Agentforce Data Library, then stage 2: custom Apex vector search

**Stage 1** built `company_faq` as an Agentforce Data Library (`Cairn_Knowledge`)
over the Knowledge articles loaded in §4.2, using Salesforce's out-of-the-box
"Answer Questions with Knowledge" action rather than a hand-built retriever:

- Content fields (embedded/searched): `FAQ_Question__c`, `FAQ_Answer__c`,
  `Chat_Answer__c`. Identifying fields (citation metadata only): `Title`,
  `ArticleNumber`.
- Agent Builder's Data section didn't offer a way to actually assign the ADL to the
  agent (a UI gap, not agent-specific — confirmed the ADL was `READY` with a real
  retriever and still had an empty `featureAssignments` list). Fixed by wiring it
  directly in Agent Script with a top-level `knowledge:` block
  (`rag_feature_config_id: "ARFPC_<the ADL's libraryId>"`) — full detail and the two
  related permission-set/field-access gotchas in `SETUP_GUIDE.md` §6.2.

**Stage 2** replaced that action with a custom Apex vector-search retriever
(`CompanyFAQVectorSearch.cls`), querying Data Cloud's vector search index directly —
skipping the standard action's orchestration overhead, demoed as a before/after
latency comparison.

- **No new ingestion needed**: `Knowledge__kav` was already flowing into Data Cloud
  as `ssot__KnowledgeArticleVersion__dlm` from stage 1's setup.
- Built a **Vector** (not hybrid — FAQ questions don't hinge on exact phrases the way
  product troubleshooting does) search index named **`Cairn_Knowledge`**
  (`Cairn_Knowledge_index__dlm` / `_chunk__dlm`), over that DLM, with
  `FAQ_Question_c__c`/`FAQ_Answer_c__c`/`Chat_Answer_c__c` as content fields and
  `ssot__Name__c`/`ssot__ArticleNumber__c` as identifying fields.
- `vector_search(table(<index>), '<query>', '', <top_k>)` — the empty string is a
  required positional argument, confirmed live; passing `top_k` in its place fails
  with a type mismatch.

### 4.9 Product Q&A — Data Cloud hybrid search over product manuals

Single-stage build: `product_qa`'s "reason from general knowledge" placeholder was
replaced directly with a custom Apex hybrid-search retriever
(`ProductQnAHybridSearch.cls`, renamed from an earlier `ProductQnAVectorSearch` name
during the build), grounded in the actual PDF manuals already linked to each
`Product2` record from §4.2 — no new sample data, only new Data Cloud ingestion, a
search index, and Apex/agent wiring.

**1. Ingest the manual `ContentVersion` files (Data Cloud Setup → "Ingest File
Attachments from Salesforce CRM Objects"):**

- Deploys a standard Content Bundle: Data Lake Objects / DMOs / Data Streams for
  `ContentDocument`, `ContentVersion`, `ContentDocumentLink` (`ContentDocument_Home`,
  `ContentVersion_Home`, `ContentDocumentLink_Home` in this build).
- `ContentDocumentLink_Home` failed to create with a generic error until the **Data
  Cloud Salesforce Connector** permission set's **"Query Non Vetted Files"** and
  **"Allow View Knowledge"** app permissions were enabled — not obvious from the
  error message alone.
- **Backfill gotcha, confirmed:** `ContentVersion_Home`/`ContentDocument_Home` both
  completed with `Total Records = 0` — every manual PDF predates the streams, and
  the streams only ingest post-creation create/update events. "Refresh Now" alone
  didn't fix it. Fixed by running
  `data/scripts/touch-product-content-versions.apex` (re-saves each `ContentVersion`
  with a real `Description`, without touching the PDF content) to trigger the
  incremental stream, then a further Refresh Now picked up all 13.
- Final ingested counts: 13/13 `ContentVersion`, 13/13 `ContentDocument`, 44/45
  `ContentDocumentLink` (more links than files — a `ContentDocument` can have more
  than one link row; harmless here).

**2. Build a Hybrid search index (Data Cloud → Search Index → New) over the ingested
`ssot__ContentDocumentVersion__dlm` DMO:**

- Name it exactly **`Compass_Product_QnA`** — `ProductQnAHybridSearch.cls`'s
  `INDEX_TABLE`/`CHUNK_TABLE` constants are derived from this name and are
  hardcoded. A mismatch fails silently: `querySql` throws, the class catches it and
  returns `ContentFound=false`, which looks exactly like the feature not working
  rather than a naming typo.
- **Select Hybrid, not Vector** — the wizard defaults to Vector. Pure vector
  under-ranks exact troubleshooting phrases ("won't ignite," "leaking seams"), and
  querying a vector-only index with `hybrid_search()` fails outright
  (`KEYWORD_INDEX_CONNECTION_DETAILS`), it doesn't just degrade gracefully.
  Rebuilding from Vector to Hybrid re-runs the entire chunk/embed/index pipeline from
  scratch (15–35 min, not instant) — get this right the first time.
- Building the index creates 4 DMOs (`_index__dlm`, `_chunk__dlm`, `_transcribe__dlm`
  unused here, `_centr__dlm`), none visible via SOQL/`describeGlobal` — Data
  Lake-backed, queryable only through the CDP query API's ANSI SQL.

**3. Apex retriever (`ProductQnAHybridSearch.cls`)** — queries the index via the
_async_ `ConnectApi.CdpQuery.querySql`/`querySqlStatus`/`querySqlRows`/
`cancelQuerySql` API (chosen over `queryAnsiSqlV2` specifically for its timeout/
cancel handling, so a slow query can't leave a live call hanging). Confirmed shapes,
all empirical (Salesforce's reference docs cover the REST shape, not Apex parsing):

- `output.dataRows` is **not reliably populated** even when `completionStatus`
  reports done — always fetch via a follow-up `querySqlRows` call, never trust the
  submit response's own `dataRows`.
- No server-side wait parameter on `querySqlStatus` — `pollUntilDone` retries
  back-to-back with no artificial delay, relying on real round-trip latency for
  pacing (a spin-wait against `System.currentTimeMillis()` risks an uncatchable
  CPU-limit abort instead of graceful degradation).
- The join is `hybrid_search()` result's `SourceRecordId__c` → chunk table's
  `RecordId__c`. Labeling each excerpt with its source manual's title needs a
  _second_ join — the chunk table's own `SourceRecordId__c` is a trap (a constant
  User Id, not a real pointer); the real pointer is
  `SecondarySourceRecordId__c` → `ssot__ContentDocumentVersion__dlm.ssot__Id__c`.
  Use a `LEFT JOIN` — chunks sourced from `Product2` fields directly (not a manual
  PDF) have a null `SecondarySourceRecordId__c` and shouldn't be dropped.
- Escape a literal single quote by **doubling** it (`''`) — Data Cloud's ANSI-SQL
  layer, not SOQL/SOSL's backslash convention; `String.escapeSingleQuotes()` breaks
  on any caller input with an apostrophe.
- `ContentFound = true` means rows came back, not that they're relevant — vector/
  hybrid search always returns its top-K nearest results, no similarity threshold.
  The graceful "I don't have that" behavior comes from `product_qa`'s reasoning
  instructions judging relevance, not the boolean flag alone.

Full class-level detail: `SETUP_GUIDE.md` §6.3.

### 4.10 Permission sets — access granted per stage

`Cairn_Voice_Agent` grew incrementally as each stage added a new action target.
Current grants (`force-app/main/default/permissionsets/Cairn_Voice_Agent.permissionset-meta.xml`):

- `classAccesses`: `OrderLookupDataGraph`, `ProductQnAHybridSearch`,
  `CompanyFAQVectorSearch` — required for _any_ `apex://` action target; missing it
  doesn't error, it silently withholds the action from the LLM (`NO_USER_ACCESS` in
  the trace), which looks identical to the model just choosing not to call it.
- `flowAccesses`: `Cairn_Order_Lookup`, `Cairn_Create_Case`.
- `fieldPermissions`: `Order.Fulfillment_Status__c`, `Order.Estimated_Delivery_Date__c`.
- `objectPermissions`: read on `Order`/`Account`/`Contact`, read+create on `Case`.

Not tracked here because it isn't permission-set metadata: the standard "Answer
Questions with Knowledge" action (§4.8 stage 1) separately needed `Knowledge__kav`
object read + field read on the three content fields; Data Cloud retriever access for
the agent's default agent user is managed in Data Cloud/Setup, not this file.

### 4.11 Testing & validation

`sf agent preview` drives the agent headlessly for regression checks despite being an
interactive TUI — give it a pty and read the per-turn trace files, not just the
transcript, since the trace is the only reliable way to tell a grounded answer from a
confidently hallucinated one (`EnabledToolsStep`/`runtime_withheld_actions` for
access issues, `tool_invocations` for whether an action actually fired). Exact
invocation: `SETUP_GUIDE.md` §5.

Structured functional and security test suites exist for `Cairn_Compass`
(`tests/Cairn_Compass-testing-center.yaml`, `tests/Cairn_Compass-security.yaml`, and
their compiled `AiEvaluationDefinition` metadata under
`force-app/main/default/aiEvaluationDefinitions/`) covering router classification,
both order-lookup identity paths, FAQ/product grounding, escalation/case fallback,
and prompt-injection resistance — run via `sf agent test run`. These are new,
untracked in this branch as of this writing; commit them alongside this document if
they're meant to ship with it.

## 5. Known gaps / cleanup opportunities

Left over from this build, worth resolving before calling the branch done:

- **`Cairn_Order_Lookup` (the stage-1 Flow) was never deleted.** §4.7's data graph
  fully replaced it in the agent, but the Flow metadata and its `flowAccesses` grant
  in `Cairn_Voice_Agent` are both still present — dead, unused, but still deployed
  and still granted. Confirm nothing references it (`grep -rn "Cairn_Order_Lookup"
force-app/ docs/`), then delete the Flow (`sf project delete source --metadata
Flow:Cairn_Order_Lookup`) and drop the permission-set entry.
- **`Cairn_Outbound` is a minimal stub** (a single assignment element setting
  `reasonForNotRouting`) — it satisfies the `connection telephony` block's required
  `outbound_route_name` target but doesn't yet do real queue-based routing logic on
  the Salesforce side; confirm what actually resolves the target queue before
  treating escalation as fully proven end-to-end.
- **`queue_target` is function-based** (`Orders_Returns` / `Customer_Support`), not
  the language-based (English/Spanish) queue split `REQUIREMENTS.md`'s original
  two-queue narrative and `Account.Preferred_Language__c` describe. Neither
  `Cairn_Inbound` nor `Cairn_Outbound` currently reads `Preferred_Language__c` for
  routing — confirm which queue model is actually intended before demo day and
  reconcile the docs/field with whichever one wins.
- No Apex test class exists for `OrderLookupDataGraph` or `ProductQnAHybridSearch` —
  `ConnectApi` static methods can't be mocked with `Test.setMock`, so both are
  verified via live anonymous Apex and `sf agent preview` traces instead of unit
  tests (documented, not an oversight — but worth knowing before assuming coverage).

## 6. Where to go for more detail

- **Why** each piece exists, and the full functional requirements: `REQUIREMENTS.md`.
- **Every** confirmed gotcha, exact error string, and API shape referenced above, in
  full: `SETUP_GUIDE.md` §4 (data load), §5 (agent build/preview), §6.1–§6.3
  (grounding build detail), §10 (known gotchas index).
- The rehearsal and live-demo run-of-show: `SETUP_GUIDE.md` §8–§9.
