# Session 004 — Query Logic as a First-Class Architecture Concern

**The Role of the Selector Layer**

[Session introduction: explain Selector responsibilities and why query logic belongs in architecture, not scattered SOQL.]

[Learning outcomes: describe what attendees will understand and practise in Session 004.]

[Slides](slides/presentation.html) · [Editable slide source](slides/presentation.md)

The Warehouse Operations app and supporting tooling are copied from Session 003 as the starting point for this session. The app implementation is unchanged; Session 004-specific examples and walkthroughs are still to be developed. The setup commands below use the new `session004-mfg` alias.

## Session walkthrough

- **Installing FFLib** — Clone `fflib-apex-common` / `fflib-apex-mocks` and deploy from `sfdx-source`. Note the other `apex-enterprise-patterns` repos; mocks, `force-di`, and AT4DX are later sessions.
- **Recap - Domain Layer** — [Connect Session 003 Domain responsibilities to the Selector discussion.]
- **Selector Principles** — [Add the Selector overview, checklist, evolution, and example walkthrough.]
- **Warehouse App Query Logic** — [Choose the queries, field lists, and demo steps.]
- **Warehouse App Selectors vs Inline SOQL** — [Choose the Selector and inline SOQL examples and explain the boundary.]

## Sample project

The inherited Warehouse Fulfillment agent remains part of the app setup. Publish it so the `WarehouseOperations` permission set can resolve its agent access. [Decide whether the agent appears in the Session 004 presentation.]

One package directory: `force-app` (app in `main`, Apex tests in `test`), plus the Warehouse Fulfillment employee agent.

Use a scratch org from `config/project-scratch-def.json` (Einstein / Agentforce enabled). Alias used below is `session004-mfg`.

## Architecture notes

[Add the Session 004-specific Selector and query-logic design discussion here.]

The following describes the inherited implementation:

This sample uses **concrete** Domain, Selector, and Service classes. Constructors take collaborators; `newInstance()` is the default composition. Prefer `X.newInstance()` at entry points over `new X()`. Use the constructor to inject selector and service mocks during Apex tests. Service methods that persist call `UnitOfWork.newInstance()` so each persist gets a fresh Unit of Work — it is not a constructor-injected reusable resource (`commitWork()` does not clear registered work). Tests set `UnitOfWork.mock` to substitute that instance. Callers that already own a Unit of Work pass it as a method argument (for example `FulfillmentService` to `MaintenanceService`). Domain `newInstance(records)` keeps a `@TestVisible` mock for mid-method construction. This sample does not include an `Application` factory.

Domains wrap records, so they are constructed when those records are in hand — including mid-method, as when `FulfillmentService.completeLines` builds `FulfillmentLines` and `Robots`. Domain `newInstance(records)` keeps a `@TestVisible` mock for that case. This sample does not include an `Application` factory.

## Deploy the app

### Create a scratch org

```bash
sf org create scratch --definition-file config/project-scratch-def.json --alias session004-mfg
```

### Deploy fflib

The sample depends on Apex Mocks and Apex Common. Clone them once, then deploy from inside each clone.

```bash
git clone --depth 1 https://github.com/apex-enterprise-patterns/fflib-apex-mocks.git /tmp/fflib-apex-mocks
git clone --depth 1 https://github.com/apex-enterprise-patterns/fflib-apex-common.git /tmp/fflib-apex-common
```

```bash
( cd /tmp/fflib-apex-mocks && sf project deploy start --source-dir sfdx-source/apex-mocks --target-org session004-mfg --wait 15 )
( cd /tmp/fflib-apex-common && sf project deploy start --source-dir sfdx-source/apex-common --target-org session004-mfg --wait 20 --ignore-warnings )
```

### Deploy force-app

```bash
sf project deploy start --source-dir force-app --target-org session004-mfg --wait 15 --ignore-errors
```

`--ignore-errors` is only needed on a brand-new org. `WarehouseOperations` grants Agent Access to `WarehouseFulfillment`, and that Bot does not exist until you publish. Without `--ignore-errors` Salesforce rolls back the whole deploy — app and tests.

## Load sample data

```bash
./bin/data.sh -o session004-mfg
```

The copied data script creates North Hub, Picker 100, Atlas / Bolt / Ember, a High-priority ticket with three pending lines, and extra draft orders.

[Session 004 fixtures: describe any additional objects, states, or queries needed for the Selector examples.]

To delete warehouse sample objects and reload:

```bash
./bin/data.sh -cleanup -o session004-mfg
```

## Warehouse Fulfillment agent

Publish first — `WarehouseOperations` cannot deploy until the Bot exists, and Apex tests need that permission set.

```bash
sf agent publish authoring-bundle --api-name WarehouseFulfillment \
  --skip-retrieve --target-org session004-mfg

sf agent activate --api-name WarehouseFulfillment --target-org session004-mfg --json
```

`--skip-retrieve` keeps generated Bot / planner metadata out of the repo. Source of truth is `force-app/main/aiAuthoringBundles/WarehouseFulfillment/`.

Inherited agent example: from the utility bar, say **Process North Hub** — the desk action takes the warehouse name.

[Session 004 demo: add the prompt and expected behaviour if using the agent.]

Run the same package deploy again so the permission set can resolve the Bot, then assign it:

```bash
sf project deploy start --source-dir force-app --target-org session004-mfg --wait 15

sf org assign permset --name WarehouseOperations --target-org session004-mfg
sf org assign permset --name UseSetupWithAgentforce --target-org session004-mfg
```

## Run Apex tests

Run these after the second `force-app` deploy and `WarehouseOperations` assign. Integration tests look up that permission set, and some inserts run as the current user.

```bash
sf apex run test --test-level RunLocalTests --target-org session004-mfg --wait 20 --result-format human
```

## Test the agent

```bash
./scripts/agent/warehouse-fulfillment.sh -o session004-mfg
```

Reloads the warehouse fixtures, runs a live `sf agent preview` session against the authoring bundle, and SOQL-asserts extra robots were created and that one dispatch assigned every pending North Hub line.

The agent looks up North Hub by name with `GetWarehouseDesk`, creates robots through the Create Robot flow, and calls `ReleaseOrders` and `DispatchWarehouse` with record names. Do not add generated Bot or planner metadata to the repo; publish with `--skip-retrieve`.

To deploy, publish, activate, then test in one step:

```bash
./scripts/agent/warehouse-fulfillment.sh -o session004-mfg --deploy
```

[Session 004 example output: add a representative transcript after the demo has been finalised and verified.]

## Build and preview the slides

The existing Session 004 deck is preserved. From this session directory:

```bash
./slides/bin/build.sh
./slides/bin/preview.sh
```

Replace the remaining slide placeholders as the session is developed.
