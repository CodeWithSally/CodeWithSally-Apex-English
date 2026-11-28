# Setup Guide — Agentforce Voice Demo

This is the working, technical companion to [`REQUIREMENTS.md`](./REQUIREMENTS.md).
It's written as a run-of-show: build and rehearse everything here against
`sally-prep`, then repeat the same steps live against `sally-demo`.

## 1. Prerequisites

- **Salesforce CLI** (`sf`) installed and up to date (`sf update`).
- Two Salesforce **SDO sandbox orgs**, both Agentforce-enabled:
  - `sally-prep` — rehearsal org.
  - `sally-demo` — clean org used for the live recording.
- **Person Accounts** enabled in both orgs (this cannot be toggled via CLI/metadata —
  confirm with `sf org display --target-org <alias>` / Setup → Account Settings
  before relying on it; request enablement ahead of time if it's missing).
- **Data Cloud (Data360)** provisioned in both orgs — for the order lookup data graph
  and for the vector search index backing the FAQ/Product Q&A Apex retrievers.
- **Amazon Connect** instance connected to both orgs via **Salesforce Service Cloud
  Voice**, with the two existing queues (`Cairn Support`,
  `Cairn Orders & Returns`) already configured — this is the "current state" the
  demo starts from.
- VS Code with **Salesforce Extensions** + **Agentforce DX** extension, or
  Cursor/Claude Code for the pro-code agent build.

Authorize both orgs once, aliased exactly as above so the rest of this guide (and any
scripts) can assume those alias names:

```bash
sf org login web --alias sally-prep
sf org login web --alias sally-demo
```

Never assume a default org for destructive or org-specific commands — always pass
`--target-org sally-prep` or `--target-org sally-demo` explicitly.

## 2. Project Structure

```
force-app/main/default/       # agent metadata (aiAuthoringBundles, flows, classes, ...)
data/
  plans/                      # sf data import tree plan definitions
  records/                    # SObject tree JSON record files referenced by plans
  files/                      # sample PDF manuals/how-tos, base64'd into ContentVersion records
  scripts/                    # orchestrator script(s) + any Apex helper scripts
docs/
  REQUIREMENTS.md
  SETUP_GUIDE.md
```

`data/plans/` and `data/records/` are checked into git; `data/records/.generated/`
holds record files with org-specific IDs (Standard Pricebook, Person Account record
type) templated in at load time, and is git-ignored — see §4.1 step 3 and §4.2.

## 3. Deploying Metadata

```bash
sf project deploy start --target-org sally-prep
```

Repeat against `sally-demo` during the live build.

New custom fields deploy with **no field-level security** granted to any profile, so
the data load will fail with an `FlsError` until the user running it can write to
them. Assign the `Cairn_Data_Load` permission set (deployed above) to that user once,
per org:

```bash
sf org assign permset --target-org sally-prep --name Cairn_Data_Load
```

## 4. Loading Sample Data

The data plan follows Salesforce's **SObject Tree Save API** format
(`sf data import tree --plan <plan>.json`), per the sample data described in
`REQUIREMENTS.md` §3. A few objects don't fit a plain tree import cleanly — read this
section fully before building the plan files, since it drives how they need to be
laid out.

**Schema this plan depends on, beyond stock Product2/Account/Order/OrderItem:**

- `Order.Fulfillment_Status__c` (picklist: Processing / In Transit / Delivered /
  Cancelled) and `Order.Estimated_Delivery_Date__c` (date) — custom fields, deployed
  with the metadata (`force-app/main/default/objects/Order/fields/`). The agent
  reports `Fulfillment_Status__c` as "status," not the standard `Status` field, which
  every seed order leaves at `Activated` (required for the order to carry
  `OrderItem`s and roll up `TotalAmount`).
- `Account.Preferred_Language__c` (picklist: English / Spanish) — custom field on the
  Person Account, also deployed with the metadata
  (`force-app/main/default/objects/Account/fields/`).
- Knowledge Articles load into `Knowledge__kav` — the **default** Article Type
  Salesforce Knowledge creates automatically when the feature is enabled, not a
  custom one we defined. Our `sally-prep`/`sally-demo` org template happens to seed
  it with `FAQ_Question__c`, `FAQ_Answer__c`, and `Chat_Answer__c` fields, which the
  Knowledge article records in step 6 below populate (`Chat_Answer__c` as the short,
  voice-friendly response; `FAQ_Answer__c` as the fuller version). If a fresh org's
  `Knowledge__kav` doesn't have those fields, either add them or repoint
  `data/records/knowledge-articles.json` / `data/plans/03-knowledge-plan.json` at
  whatever article type + fields that org actually has — confirm with
  `sf sobject describe --sobject Knowledge__kav --target-org <alias>` before loading.

### 4.1 Load order & why

1. **Products** (`Product2`) — plain tree records, no external dependencies.
2. **Product files** (`ContentVersion`) — inserted in the **same plan run** as
   Products, so their `FirstPublishLocationId` field can reference a product's
   `@ProductRefN` reference id directly. Setting `FirstPublishLocationId` at insert
   time creates the `ContentDocumentLink` to the product automatically — no separate
   linking step needed. Keep sample PDFs small; `VersionData` is inline base64.
3. **Standard Pricebook activation + PricebookEntries** — the Standard Pricebook
   record itself already exists in every org (it can't be created), and its `Id` is
   org-specific, so it can't be hardcoded into a committed JSON file that has to work
   in both `sally-prep` and `sally-demo`. Handle this as a small scripted step, not a
   tree import:
   ```bash
   PB_ID=$(sf data query --target-org <alias> \
     --query "SELECT Id FROM Pricebook2 WHERE IsStandard=true" --json \
     | python3 -c "import json,sys; print(json.load(sys.stdin)['result']['records'][0]['Id'])")
   sf data update record --target-org <alias> \
     --sobject Pricebook2 --record-id "$PB_ID" --values "IsActive=true"
   ```
   Then template `$PB_ID` into the PricebookEntry record file (e.g. via `envsubst` on
   a `.json.tpl` with a `${STANDARD_PRICEBOOK_ID}` placeholder) before running the
   plan that creates the `PricebookEntry` records (referencing `@ProductRefN` for
   `Product2Id`, and the resolved literal id for `Pricebook2Id`) —
   `data/plans/01-products-plan.json`. `Order` also requires a literal
   `Pricebook2Id`, so `orders-*.json.tpl` carries the same
   `${STANDARD_PRICEBOOK_ID}` placeholder.
4. **Person Accounts** — the Person Account record type `Id` is org-specific too, so
   `person-accounts.json.tpl` templates a `${PERSON_ACCOUNT_RECORD_TYPE_ID}`
   placeholder, resolved the same way by querying `RecordType` where
   `SObjectType = 'Account' AND IsPersonType = true`.
5. **Orders + OrderItems** — Accounts and Orders load together via
   `data/plans/02-customers-orders-plan.json`, so `Order.AccountId` can reference
   `@PersonAccountRefN` — a top-level field, which `@Ref` resolution handles fine
   across plan entries. `OrderItem.PricebookEntryId` can't work the same way: `@Ref`
   tokens only resolve on top-level record fields, not on fields nested inside a
   child relationship (`Order.OrderItems[].PricebookEntryId`) — confirmed against
   `sally-prep` (`MALFORMED_ID` on every `@PricebookEntryRefN`). So PricebookEntries
   load in the earlier, separate `01-products-plan.json` run, `load-data.sh` queries
   their real Ids by `Product2.ProductCode` right after, and `orders-*.json.tpl`
   carries `${PRICEBOOK_ENTRY_ID_<SKU>}` placeholders instead of `@Ref`s. Two more
   gotchas surfaced testing this against `sally-prep`: `Order.Status` can't be
   inserted as `Activated` — the API rejects it (`FAILED_ACTIVATION`) — so every seed
   order loads as `Draft` and `load-data.sh` flips it to `Activated` afterward with
   `activate-orders.apex`, scoped to accounts that have `Preferred_Language__c` set
   so it can never touch unrelated Draft orders already in the org; and
   `OrderItem.TotalPrice` is system-calculated, so it's omitted from the record data
   entirely rather than set. Orders are also split across
   `orders-01.json.tpl`/`-02`/`-03` (regenerate via `data/scripts/generate-orders.py`)
   because a single Order + its nested OrderItems all count against the SObject Tree
   Save API's 200-records-per-request cap.
6. **Knowledge Articles** (`Knowledge__kav`) — load as Draft via tree import
   (`data/plans/03-knowledge-plan.json`), then **publish** separately with
   `data/scripts/publish-knowledge-articles.apex` (uses
   `KbManagement.PublishingService.publishArticle`, run via `sf apex run --file`) —
   publishing is a workflow action, not a plain field update. Authored in English and
   Spanish, matching the two support queues.

### 4.2 Running it

Wrap the above into a single orchestrator script (`data/scripts/load-data.sh`) that
takes the target org alias as an argument, so the exact same script runs against
`sally-prep` during rehearsal and `sally-demo` live:

```bash
data/scripts/load-data.sh sally-prep
# ...on demo day...
data/scripts/load-data.sh sally-demo
```

## 5. Building the Agent

Author the agent as an **Agent Script** (`AiAuthoringBundle`), matching the five use
cases in `REQUIREMENTS.md` §4 — one topic/subagent per use case is a reasonable
starting split:

- `order_lookup` — staged build from Flow → Apex (SOQL) → Data360 data graph; see
  §6.1. Returns order number, total, status, estimated delivery date.
- `company_faq` — staged build from Prompt Template + Data Cloud retriever → custom
  Apex vector-search retriever; see §6.2. Grounded in the Knowledge articles loaded
  in §4.1 step 6.
- `product_qa` — custom Apex vector-search retriever over linked product manuals; see
  §6.3.
- `escalate_to_agent` — transfers the live Voice call into the correct Amazon Connect
  queue (English/Spanish) based on the caller's language.
- `create_case` — invoked when `escalate_to_agent` isn't possible (no agent
  available); creates a `Case` capturing the caller's issue.

Preview each topic in simulated mode in VS Code (`AFDX: Preview This Agent`) before
wiring up real data, then switch to live mode once Apex/Flow/data are deployed.

`sf agent preview` is the CLI equivalent, and it can be scripted despite being an
interactive TUI — useful for regression-checking a topic without re-typing utterances
by hand:

```bash
mkfifo in.fifo
( sleep 28; printf 'what is the status of my order?'; sleep 2; printf '\r'; sleep 150 ) > in.fifo &
script -qc 'stty cols 120 rows 45; sf agent preview --target-org sally-prep \
  --authoring-bundle Cairn_Compass --use-live-actions \
  --context-variables "\$Context.AccountId=001Sv00000gWLyyIAG" \
  --output-dir ./transcripts' /dev/null < in.fifo
```

Two gotchas: linked variables need the **`$Context.` prefix** — without it they're
treated as state variables and silently don't resolve — and `--output-dir` writes
`transcript.jsonl` plus per-turn trace files. Read the traces, not just the
transcript: they list which actions actually fired, which is the only way to tell a
grounded answer from a confidently hallucinated one.

## 6. Grounding & Retrieval Build

### 6.1 Order Lookup

Build in stages against `sally-prep`; each stage should work end-to-end before
moving to the next.

1. **Flow** — declarative Flow action querying `Order`/`OrderItem` by
   customer-provided identifiers (order number, customer name/phone/email). Wire it
   into the `order_lookup` topic as the first working version.
2. **Apex (local SOQL)** — swap the Flow action for an Apex invocable action running
   the equivalent SOQL query. Same inputs/outputs as stage 1, so the topic wiring
   doesn't change, only the action implementation.
3. **Data360 Data Graph** — replace the Apex action with a Data Cloud data graph, in
   three steps:
   1. **Ingest & map** — configure Data Cloud ingestion (Data Stream) from Salesforce
      CRM for `Account` (Person Account), `Order`, `OrderItem`, and `Product2`, using
      the standard Salesforce Data Cloud connector for streaming ingestion. Skip the
      pre-built "Sales and Service Cloud" data kit's automatic mapping — manually map
      the ingested fields to Data Cloud's Standard Data Model objects (e.g.
      `Individual`, `Sales Order`, `Sales Order Product`, `Product`) in the Data Cloud
      Data Model canvas, so the mapping decisions are visible on camera rather than
      hidden behind the kit's defaults. Confirm the exact standard object/field names
      available in the org's Data Model canvas before mapping — Data Cloud's Standard
      Data Model can vary slightly by org/release.
   2. **Build the data graph** — build a data graph over the mapped standard objects,
      so a single query returns the order, its line items, the customer, and the
      ordered products. Root the graph at `Account` and sort the `Sales Order` node by
      `Order Start Date` descending (Filters tab → Sort and Limit) — that sort is what
      makes "my most recent order" resolvable. There is no lookup-key configuration
      screen in this builder, and only the root's primary key is queryable; see step 3.
   3. **Wire it up** — point `order_lookup_action` at an Apex invocable action
      (`apex://OrderLookupDataGraph`) that queries the data graph. There is **no**
      no-code retriever action for a data graph: Setup → Retrievers only offers a
      search-index retriever (the `product_qa`/`company_faq` mechanism in §6.3),
      which needs a DMO with a vector search index, not a data graph. A data graph is
      queried through the Data Graph Query API — from Apex via
      `ConnectApi.CdpQuery.getDataGraphData(graphName, accountId, 'default')`.
      Two things about that call are worth knowing before you write against it:
      - Its lookup key must be the **root DMO's primary key** (here, the Account id).
        Arbitrary nested fields like `Sales Order.OrderNumber` are not lookup keys, so
        the Apex resolves an order number to its Account id with a plain SOQL query
        against core `Order` first, then queries the graph by that id.
      - **A caller the ANI didn't already identify can't resolve an order by number
        alone** — an order number by itself is guessable and isn't proof it's really
        their order. `order_lookup_action`'s `OrderDateInput` (the date the order was
        placed) is required alongside `OrderNumberInput` for this path; the Apex
        resolves the order by number, then checks `Order.EffectiveDate` against
        `OrderDateInput` before returning anything — a mismatch, or either input
        missing, is treated the same as no match found. The `AccountIdInput` path
        (a caller the ANI already matched) skips this check entirely, since identity
        is already established. `order_lookup`'s reasoning instructions escalate to a
        human immediately if the caller can't supply both, rather than falling back to
        another identifier, and give a deliberately minimal reply (fulfillment status
        and estimated delivery date only — no name, no order number or total readback)
        when a match is found this way, since the caller still isn't personally
        identified the way an ANI match would establish.
      - The rows in `CdpQueryOutput.data` are raw Java maps, not Apex `Map`s. Calling
        any `Map` method on one (`get`, `keySet`, `size`, even `toString`) faults the
        Apex interpreter in a way `try`/`catch` cannot intercept, and the failure
        aborts the request before debug logs flush — so it looks like nothing ran.
        `String.valueOf(row)` is safe, and renders as
        `{json_blob__c=<the whole graph as JSON>, version__c=0}`; cut the payload out
        of that string and `JSON.deserializeUntyped` it into real Apex collections.
        See `OrderLookupDataGraph.parseRow`.
      - An Apex `Decimal` output must be declared `lightning__numberType` in the
        `.agent` file. The Flow-era `lightning__currencyType` is rejected at runtime.

      **Fetch the known caller's order deterministically, not by asking the LLM to.**
      `order_lookup`'s `before_reasoning` hook runs the action whenever `AccountId` is
      set and stores the result in `@variables.known_order_summary`, which the
      reasoning instructions interpolate. This is not a stylistic choice: left to
      decide for itself, the reasoning LLM would not call an action it had no inputs
      to fill — it either narrated "one sec, let me pull that up" and ended the turn,
      or **fabricated** plausible order numbers and totals. Several rounds of
      instruction wording, including an explicit "never invent an order's details",
      did not fix it; putting the real data in the prompt before the model reasons
      did. The Apex's `OrderSummaryOutput` exists for this hook, because Agent Script
      mutable variables are limited to `string`/`number`/`boolean`/`object` (`date` is
      action-parameter-only), so the five typed outputs can't each be held in one.

      Two caveats worth knowing on camera: the data graph refreshes hourly, so an
      order created mid-demo won't appear until the next refresh; and the
      `before_reasoning` hook re-runs the graph query on every turn inside
      `order_lookup`, which adds a round-trip per turn.

### 6.2 Company FAQ

1. **Agentforce Data Library (ADL) + standard "Answer Questions with Knowledge"
   action** — built as an ADL (`Cairn_Knowledge`) over the Knowledge articles
   published in §4.1 step 6, using Salesforce's out-of-the-box retriever/action
   rather than a hand-built Prompt Template. Baseline version of `company_faq`.
   - **Field selection**: content fields (what gets embedded/searched) —
     `FAQ_Question__c`, `FAQ_Answer__c`, `Chat_Answer__c`. Include the question
     field, not just the answer — a caller's spoken query semantically matches
     the stored question much more closely than the answer text alone.
     Identifying fields (metadata for citation/labeling, not embedded) —
     `Title`, `ArticleNumber`.
   - **Wiring gotcha, confirmed**: adding the ADL in Agent Builder generates the
     `AnswerQuestionsWithKnowledge` action in the `.agent` file automatically,
     but the agent's Data section may not offer a way to actually assign the
     ADL to the agent (no add/plus control) — this looks like a UI gap for the
     current release, not something specific to this agent. Confirmed via
     `sf agent adl get` that the ADL can be `READY` with a real retriever and
     still show an empty `featureAssignments` list, which produces this exact
     runtime error when the action fires: `REQUIRED_FIELD_MISSING: We
couldn't find a data library assigned to this agent.` The `sf agent adl`
     command group has no flag for this assignment either.
     **Fix**: wire it directly in Agent Script with a top-level `knowledge:`
     block (sibling to `system:`/`language:`/`variables:`):
     ```
     knowledge:
         rag_feature_config_id: "ARFPC_<the ADL's libraryId>"
         citations_enabled: True
         citations_url: ""
     ```
     The libraryId comes from `sf agent adl list --target-org sally-prep`
     (18-char id, `1JD` prefix) — `rag_feature_config_id` is literally
     `"ARFPC_"` prefixed onto it, not a separately-queryable record. Once this
     block exists, the action definition's `"ragFeatureConfigId":
string=@knowledge.rag_feature_config_id` (and the `citationsUrl`/
     `citationsEnabled` equivalents) resolve correctly — without it, the
     compiler rejects those same expressions with `Unknown @knowledge field`,
     since `@knowledge.*` references this block, not a system-wide namespace.
   - **Retrieve round-trip bug, confirmed**: pulling the bundle after an
     Agent Builder UI save can corrupt `additional_locales: ""` into an
     unindented, invalid two-line form (`additional_locales:` then `""` on
     its own line at column 0), which cascades into several unrelated parse
     errors below it. `sf agent validate authoring-bundle --target-org
sally-prep` catches this — fix by putting the value back on one line.
   - **Permission set gotcha, confirmed**: same category as the
     `classAccesses` gap in §6.3 for Apex actions, but for Knowledge field
     access — without `Knowledge__kav` object read plus field read on
     `FAQ_Question__c`/`FAQ_Answer__c`/`Chat_Answer__c` in
     `Cairn_Voice_Agent.permissionset-meta.xml`, the action fails with
     `INSUFFICIENT_ACCESS_OR_READONLY: Looks like you don't have access to
one or more fields used by the assigned data library.` — a different
     error from the missing-assignment one above, easy to conflate if you
     only read the first line.
2. **Custom Apex vector-search retriever** (`CompanyFAQVectorSearch.cls`) —
   replaces the standard "Answer Questions with Knowledge" action with a
   custom Apex action that queries Data Cloud's vector search index directly
   over the Knowledge article content, skipping the standard action's
   orchestration overhead. Demo this as a before/after latency comparison
   against stage 1 (rehearse/record stage 1 before swapping, per the
   commit history — the two don't run side by side in the live agent).
   Plain `vector_search()`, not `hybrid_search()` — unlike Product Q&A
   (§6.3), FAQ questions don't hinge on exact troubleshooting phrases.

   No separate ingestion step was needed: `Knowledge__kav` was already
   flowing into Data Cloud as `ssot__KnowledgeArticleVersion__dlm` before
   this stage was built (confirmed live via `ConnectApi.CdpQuery` — its
   content fields are `FAQ_Question_c__c`/`FAQ_Answer_c__c`/
   `Chat_Answer_c__c`, its title is `ssot__Name__c`, primary key
   `ssot__Id__c`). The Vector Search index is named `Cairn_Knowledge`
   (`Cairn_Knowledge_index__dlm`/`_chunk__dlm`, matching the same naming
   convention as `Compass_Product_QnA` in §6.3), built over that DLM with
   `FAQ_Question_c__c`/`FAQ_Answer_c__c`/`Chat_Answer_c__c` as content
   fields and `ssot__Name__c`/`ssot__ArticleNumber__c` as identifying
   fields.

   **`vector_search()`'s signature, confirmed live**:
   `vector_search(table(<index>), '<query>', '', <top_k>)` — the empty
   string is a required positional argument (unlike `hybrid_search()`'s
   trailing JSON options argument, unconfirmed what it's for); passing
   `top_k` in its place fails with an argument-type mismatch. The score
   column on the result is `score__c`. The three-table join (index →
   `_chunk__dlm` → `ssot__KnowledgeArticleVersion__dlm`) was confirmed live
   to compile and run clean while the index was still empty — the SQL shape
   is right, but the join keys (`SourceRecordId__c`/
   `SecondarySourceRecordId__c`, same pattern as §6.3) still need
   re-confirming against real rows once the index finishes populating,
   since this index has only one source object (Knowledge) rather than
   Product Q&A's two — the "`SourceRecordId__c` is a useless constant"
   gotcha from §6.3 may not actually apply here.

### 6.3 Product Q&A

A custom Apex action (`ProductQnAHybridSearch`) queries a Data Cloud **hybrid**
search index directly over the product manual/guide `ContentVersion` files linked to
each `Product2` record — no data graph, no Prompt Template retriever, single
approach. Build in two parts:

1. **Ingest the manuals into Data Cloud** — Data Cloud Setup → "Ingest File
   Attachments from Salesforce CRM Objects" (exact label may vary by release), which
   deploys a standard Content Bundle: Data Lake Objects/Data Model Objects/Data
   Streams for `ContentDocument`, `ContentVersion`, and `ContentDocumentLink`
   (`ContentDocument_Home`, `ContentVersion_Home`, `ContentDocumentLink_Home` in this
   build). Activate all three streams and give them a few minutes.

   **Backfill gotcha, confirmed:** the `ContentVersion` stream only ingests versions
   created or updated _after_ the stream exists — every manual PDF here predates it.
   `Refresh Now` didn't backfill; the fix was a no-op re-save of each `ContentVersion`
   (`data/scripts/touch-product-content-versions.apex`) to trigger the incremental
   stream. `ContentDocumentLink_Home` separately needed the Data Cloud Salesforce
   Connector permission set's "Query Non Vetted Files" + "Allow View Knowledge"
   enabled before it would ingest without erroring.

2. **Build a Hybrid search index** over the ingested `ssot__ContentDocumentVersion__dlm`
   DMO — Data Cloud → Search Index → New. **Name it exactly `Compass_Product_QnA`** —
   `ProductQnAHybridSearch.cls`'s `INDEX_TABLE`/`CHUNK_TABLE` constants
   (`Compass_Product_QnA_index__dlm`/`Compass_Product_QnA_chunk__dlm`) are derived
   from this name and are hardcoded, not configurable; a different name here means
   those DLMs won't exist under the names the class queries. The failure is silent
   from the caller's perspective — `querySql` throws, the class catches it and
   returns `ContentFound=false`, and the agent just says "I don't have that" and
   escalates, which looks like the feature doesn't work rather than a naming
   mismatch. **Select Hybrid Search, not Vector Search**
   (the wizard defaults to Vector selected): pure vector search under-ranks the exact
   troubleshooting phrases these manuals hinge on ("won't ignite," "leaking seams"),
   and a vector-only index has no keyword index to fall back to at all — querying it
   with `hybrid_search()` fails outright with a `KEYWORD_INDEX_CONNECTION_DETAILS`
   error, it doesn't just degrade to weaker ranking. This is easy to
   get wrong live since the wizard doesn't warn you either way. Rebuilding the index
   from Vector to Hybrid re-runs the entire chunk/embed/keyword-index pipeline from
   scratch (another 15-35 minute wait on this data volume, not instant).

   Building the index creates 4 additional DMOs, named `<index name>_index__dlm`,
   `_chunk__dlm`, `_transcribe__dlm` (unused here — audio/video only), and
   `_centr__dlm` (vector cluster centroids, not queried directly). None of these are
   visible via standard SOQL/`describeGlobal` — they're Data Lake-backed, queryable
   only through the CDP query API's ANSI SQL, which is exactly why `queryAnsiSqlV2`/
   `querySql` exists as a separate code path from ordinary Apex SOQL.

**Apex** (`ProductQnAHybridSearch.cls`) queries the index via the async
`ConnectApi.CdpQuery.querySql`/`querySqlStatus`/`querySqlRows`/`cancelQuerySql` API
(not `queryAnsiSqlV2`) specifically for its timeout/cancel handling, so a slow query
can't leave a live voice call hanging. Confirmed shapes and gotchas, empirically
(Salesforce's reference docs cover the REST shape, not a concrete Apex parsing
example):

- `ConnectApi.CdpQuery.querySql(QuerySqlInput)` returns `QuerySqlOutput`; the
  `queryId` is nested at `output.status.queryId`, not a top-level field.
  `completionStatus` (a `QuerySqlStatusEnum`) reads `ResultsProduced` immediately on
  the submit call for most queries at this data volume — polling is the exception,
  not the rule, but the bounded loop still matters for the case it isn't.
- **`output.dataRows` is not reliably populated even when `completionStatus` reports
  done** — confirmed with a one-row `COUNT(*)` that came back with `dataRows: null`
  on the submit response, correct only via a follow-up `querySqlRows` call. Always
  fetch rows via `querySqlRows(queryId, 0, limit)` once the query is done, whether
  "done" arrived on the initial submit or after polling — never trust the submit
  response's own `dataRows`.
- `querySqlStatus(queryId)` takes a single argument — no server-side wait parameter.
  Apex has no synchronous sleep primitive, and a spin-wait against
  `System.currentTimeMillis()` burns real CPU-governor time rather than suspending
  (unlike a callout), risking an uncatchable CPU-limit abort instead of graceful
  degradation. `pollUntilDone` retries `querySqlStatus` back-to-back with no
  artificial delay, relying on each call's own real round-trip latency for pacing.
- `ConnectApi.QuerySqlRow` (from either `QuerySqlOutput.dataRows` or
  `QuerySqlPageOutput.dataRows`) is a proper ConnectApi output class — its `.row`
  field is a real `List<Object>`, safe to index directly. This is **not** the data
  graph's raw Java/Gson-map gotcha (§6.1.3) — don't port that string-cutting
  workaround here, it solves a problem this API doesn't have.
- The `hybrid_search()`/`vector_search()` join is on the result's
  `SourceRecordId__c` matching the chunk table's `RecordId__c` (the index row's own
  `RecordId__c` is its own vector-record id, not a pointer to the chunk — easy to
  get backwards).
- **Labeling each excerpt with its source manual's title** requires a second join,
  and the obvious field is a trap: the chunk table's own `SourceRecordId__c` looks
  like it should point back to the source `ContentVersion`, but confirmed live it's
  populated with a constant value (a User Id, apparently `CreatedById`) identical
  across every manual-PDF chunk — useless as a join key. The real pointer is the
  chunk table's `SecondarySourceRecordId__c`, confirmed live to equal
  `ssot__ContentDocumentVersion__dlm.ssot__Id__c` (its primary key) and to resolve
  to the correct, sensible title for the chunk's content. Use a `LEFT JOIN` here,
  not an inner join — the index's declared source DMO is `ssot__Product__dlm` as
  well as this attachment DMO, so a chunk sourced from Product2 fields directly
  (rather than a manual PDF) has a null `SecondarySourceRecordId__c` and must not be
  dropped just because it has no manual title.
- Data Cloud's ANSI-SQL layer escapes a literal single quote by **doubling** it
  (`''`), not backslash-escaping — `String.escapeSingleQuotes()` (SOQL/SOSL
  convention) does not work here and breaks on any caller input with an apostrophe
  ("won't," "can't") with a SQL syntax error, not a clean failure.
- `ContentFound = true` means the query returned rows, not that they're relevant —
  vector/hybrid search has no similarity threshold and always returns its top-K
  nearest results. An out-of-catalog question ("how do I fix my kayak paddle") still
  came back `ContentFound: true` with the closest semantic match (a tent's pole-repair
  steps). The graceful "I don't have that" behavior comes from `product_qa`'s
  reasoning instructions judging the retrieved content isn't actually relevant to the
  question, not from the boolean flag alone — the flag and the instruction-level
  relevance check both have to be doing their job.
- **The Apex class needs an explicit `classAccesses` grant** in
  `Cairn_Voice_Agent.permissionset-meta.xml` for the agent's running user, same as
  any other `apex://` action target — missing it doesn't error, it silently withholds
  the action from the LLM (`NO_USER_ACCESS` in the trace) and looks exactly like the
  model just deciding to escalate instead of searching. Check the trace's
  `EnabledToolsStep`/`runtime_withheld_actions`, not just the transcript, if an action
  never seems to fire.

No Apex test class exists for this or `OrderLookupDataGraph` (§6.1.3) — `ConnectApi`
static methods can't be mocked with `Test.setMock`, so both are verified via live
anonymous Apex plus `sf agent preview` traces instead of unit tests.

What "good" looks like here is a clear before/after: without grounding, the agent
gives a generic answer and asks the caller for details it should already be able to
look up. With the retriever wired in, the agent answers already grounded in the
specific product — citing the actual spec or troubleshooting step rather than a
generic response. That contrast is worth making visible on camera, not just the
final grounded answer.

## 7. Voice Channel Setup

### 7.1 Primary: Amazon Connect + Salesforce Voice

This is the "before" state already running for Cairn Outdoor Co. — document/screen
record the existing setup (two queues, Salesforce Service Cloud Voice adapter) before
adding the Agentforce Voice agent in front of it, then show:

- The agent answering calls that used to go straight to a human.
- `escalate_to_agent` handing off into the same English/Spanish Amazon Connect
  queues, mid-call, with context.

### 7.2 Alternate: Agentforce Contact Center (AFCC)

Optional second segment: same agent, but fronted by AFCC instead of Amazon Connect,
as the "native CCaaS" story for orgs not already invested in Amazon Connect.

## 8. Rehearsal Checklist (`sally-prep`)

- [ ] Metadata deploys clean to a fresh sandbox.
- [ ] `data/scripts/load-data.sh sally-prep` runs end-to-end with no manual fixups.
- [ ] All five use cases pass manual QA in the Agentforce DX preview panel.
- [ ] Order lookup data graph returns the correct order, line items, and
      customer/product details for at least 2–3 sample orders.
- [ ] A caller whose ANI matched an Account gets their most recent order without
      being asked for any identifiers, and is addressed by name.
- [ ] Every order number/total/status/date the agent says matches core CRM exactly —
      check the preview traces to confirm the action actually fired rather than the
      model answering from nothing.
- [x] Product Q&A Apex retriever returns grounded answers for at least 2–3 product
      questions per product category worth demoing.
- [ ] Company FAQ Apex retriever returns grounded answers at lower latency than the
      Prompt Template baseline for at least 2–3 sample questions.
- [ ] Escalation actually rings into the correct Amazon Connect queue.
- [ ] Case creation fires correctly when escalation isn't available (simulate no
      agents available).
- [ ] Full run-of-show timed end-to-end at least once.

## 9. Live Demo Run-of-show (`sally-demo`)

Repeat, from a clean sandbox, on camera:

1. `sf org login web --alias sally-demo` (if not already authorized).
2. `sf project deploy start --target-org sally-demo`.
3. `sf org assign permset --target-org sally-demo --name Cairn_Data_Load` (§3).
4. `data/scripts/load-data.sh sally-demo`.
5. Walk through agent build/config live (per §5–7), narrating for the audience.
6. Live call demo covering the use cases in `REQUIREMENTS.md` §8 success criteria.

## 10. Known Gotchas

- Standard Pricebook `Id` is org-specific — never hardcode it in committed data files
  (see §4.1 step 3).
- `ContentVersion.FirstPublishLocationId` must be set in the **same** tree import run
  as the `Product2` records it references, or the `@ProductRefN` reference won't
  resolve.
- Knowledge articles inserted via tree import land as **Draft** — they won't show up
  in agent retrieval until published.
- Person Accounts can't be enabled via CLI/metadata — verify it's on before building
  anything that depends on it.
- Knowledge Articles load into `Knowledge__kav`, Salesforce's default Article Type —
  its `FAQ_Question__c`/`FAQ_Answer__c`/`Chat_Answer__c` fields come from the org
  template, not from `force-app`; re-check field names with `sf sobject describe` on
  any org that wasn't built from the same template (see §4).
- Some org templates (ours included) seed more than one `IsPersonType = true`
  Account record type. `load-data.sh` prefers the one named `PersonAccount`; if a
  target org doesn't have that exact `DeveloperName`, it falls back to whichever
  Person Account record type sorts first — check that's the intended one.
- Person Account and PricebookEntry record type/pricebook `Id`s are resolved live by
  `data/scripts/load-data.sh`, which writes rendered files to the git-ignored
  `data/records/.generated/`. Run the script rather than `sf data import tree`
  directly against the `.tpl` files — they contain unresolved `${...}` placeholders.
- `OrderItem.TotalPrice` is system-calculated from `Quantity` × `UnitPrice` — the API
  rejects it on insert (`INVALID_FIELD_FOR_INSERT_UPDATE`), so it's omitted from
  `orders-*.json.tpl` and left for the platform to compute (`Order.TotalAmount` then
  rolls up from that automatically).
- `load-data.sh` is **not idempotent** — every object it inserts (Products,
  ContentVersions, PricebookEntries, Person Accounts, Orders, Knowledge articles) is
  a plain `sf data import tree`/create, with no upsert or dedup. Re-running it against
  an org that already has this sample data creates a second set of everything.
  Clean up first (e.g. delete `Product2` by the SKUs in `REQUIREMENTS.md` §3.1,
  cascading to their `PricebookEntry`/`ContentDocument`, plus the 6 Person Accounts by
  `Preferred_Language__c != null`, which cascades to their Orders/OrderItems) before
  reloading into a non-empty `sally-prep`.
- Data Cloud ingestion is streaming, not instant — allow a few minutes after loading
  sample data before the order lookup data graph reflects it; don't assume it's
  broken if a freshly loaded order doesn't show up immediately.
- The Salesforce CRM data kit's automatic mapping is intentionally skipped for order
  lookup — `Account`/`Order`/`OrderItem`/`Product2` fields are mapped to Data Cloud's
  Standard Data Model by hand (§6.1) — double-check the mapping after any Data Cloud
  org refresh/reset.
- A Data Cloud search index built to link an unstructured DMO (e.g.
  `ContentDocumentLink` → a structured DMO for file attachments) needs the linking
  DLO's own primary key mapped into the target DMO too, separately from whatever
  business-key mapping actually does the linking — "Primary key of all source DLOs
  must be mapped to the source DMO" at Save time means exactly this, usually on a
  DLO you didn't think of as a "real" data source (see §6.3).
- The Search Index Builder wizard defaults to Vector Search selected, not Hybrid —
  easy to build the wrong one without noticing, and there's no in-place edit, only a
  full rebuild (another full chunk/embed/index cycle) to fix it (§6.3).
- `ContentVersion`'s Data Cloud stream only ingests versions created/updated _after_
  the stream exists — pre-existing files need a no-op re-save to backfill (§6.3, same
  underlying behavior `SETUP_GUIDE.md` already notes for order lookup above, just a
  file-attachment-specific instance of it).
- Any new `apex://` action target needs an explicit `classAccesses` grant in
  `Cairn_Voice_Agent.permissionset-meta.xml` — missing it silently withholds the
  action from the LLM (`NO_USER_ACCESS`) rather than erroring, and looks identical to
  the model just choosing not to call it (§6.3).
- An Agentforce Data Library can be `READY` with a real retriever and still not be
  assigned to any agent (Agent Builder's Data-section UI may not offer a way to do
  this) — wire it directly with a top-level `knowledge:` block in Agent Script
  instead (§6.2).
- The standard "Answer Questions with Knowledge" action needs its own field-level
  security grant (`Knowledge__kav` read + the specific content fields) in
  `Cairn_Voice_Agent.permissionset-meta.xml`, same category as the `classAccesses`
  gotcha above but for Knowledge fields, not Apex classes (§6.2).

## 11. References

- [Salesforce CLI — Import Data Reference (SObject Tree)](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/data_import_ref.htm)
- [Agentforce DX Developer Guide](https://developer.salesforce.com/docs/einstein/genai/guide/agent-dx.html)
- [Agent Script](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-script.html)
