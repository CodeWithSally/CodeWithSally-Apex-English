# Session 005 — Mocking in Apex

**Why It Changes Everything**

A unit test proves one method's logic and nothing else. Mocking makes that possible. This session covers how to make Apex code mockable, how ApexMocks builds on the Apex Stub API, and how to test each fflib layer in memory: no DML, no SOQL, every collaborator mocked. Most of the code comes from a small, self-contained Widgets example; the Warehouse Operations app from earlier sessions shows the same patterns at real scale.

After this session you'll be able to:

- tell quality tests (no DML, no SOQL, every collaborator mocked) from the few tests that exist only for coverage;
- make code mockable with `newInstance()` plus constructor injection, and explain why `virtual` isn't needed;
- stub and verify with ApexMocks, including matchers, argument captors, and in-order verification;
- test code that uses a Unit of Work, either fully mocked or with an inert IDML that records what would have been saved;
- cover Selectors and triggers cheaply;
- decide what to mock at each layer: Service, Domain, Selector, and trigger handler.

[Slides](slides/presentation.html) · [Editable slide source](slides/presentation.md)

The Warehouse Operations app and supporting tooling are copied from Session 004 as the starting point for this session. Session 005 adds the self-contained Widgets example under `force-app/mocking-with-widgets/`; no inherited code changes. The setup commands below use the new `session005-mfg` alias.

## Session walkthrough

- **Opening** — The series so far, and the promises earlier sessions made about mocking.
- **The goal** — Meet the Widgets. What's wrong with a test that saves and queries real records; unit tests for quality, a few special cases for coverage; just enough vocabulary.
- **Seams: making code mockable** — The Stub API and how ApexMocks uses it; what can't be stubbed; `newInstance()` plus constructors; substituting stateful objects where they're created; a mockability checklist; where fflib is heading, and how its mocking evolved.
- **The tools** — ApexMocks stubbing and verification, more than one way to verify the same call, records built in memory, and testing Selectors, the Unit of Work, and triggers.
- **At real scale** — The Warehouse app's `DispatchServiceTest` and a Domain test, what to mock at each layer, and pitfalls.
- **Close** — Test the method. Mock the rest. Next: Session 006, packages and AT4DX.

## Sample project

The inherited Warehouse Fulfillment agent remains part of the app setup. Publish it so the `WarehouseOperations` permission set can resolve its agent access. The agent isn't part of the Session 005 presentation.

One package directory: `force-app` (app in `main`, Apex tests in `test`), plus the Warehouse Fulfillment employee agent.

Use a scratch org from `config/project-scratch-def.json` (Einstein / Agentforce enabled). Alias used below is `session005-mfg`.

## The Widgets example

`force-app/mocking-with-widgets/` is a small example written for this session, separate from the inherited Warehouse app. Everything in it is prefixed `WDGT_`, a namespace-like prefix inside one package (Session 006 takes that separation across packages). It deploys with `force-app`.

One Service method does the work: `WDGT_WidgetsService.tagWidgetsWithGuid(Set<Id>)` selects the widgets, gives each a new GUID, registers each as dirty with a Unit of Work, and commits.

| Class | Role |
|---|---|
| `WDGT_WidgetsService` | The method under test. `newInstance()` for callers; a constructor that takes the Selector and utility, where tests inject mocks |
| `WDGT_WidgetsSelector` | Queries widgets by Id. Deliberately doesn't query `WDGT_MightBeRequired__c` |
| `WDGT_WidgetsUtility` | `generateGuid()`: random, so tests must mock it |
| `WDGT_UnitOfWork` | Unit of Work factory with a `@TestVisible` static `mock` |
| `WDGT_WidgetsTriggerHandler` and `WDGT_Widgets.trigger` | A trigger handler with no logic yet |
| `WDGT_InertDml` (test) | An `IDML` that saves nothing and records what would have been saved |

| Test class | What it shows |
|---|---|
| `WDGT_UnitOfWorkTest` | The same method tested three ways: a mocked Unit of Work, an inert Unit of Work over `WDGT_InertDml`, and real DML and SOQL. Two more mocked tests verify the same calls with matchers, an argument captor, and in-order verification |
| `WDGT_WidgetsServiceTest` | A Selector stubbed to throw; verifies nothing else is called |
| `WDGT_WidgetsSelectorTest` | Empty and null conditions. Two marked demonstrations: reading a field the Selector doesn't query (and how a mocked Selector hides it), and the hazard of tests that depend on DML |
| `WDGT_WidgetsTriggerHandlerTest` | Trigger coverage: disable the handler, save one widget |
| `WDGT_WidgetsUtilityTest` | GUID shape and randomness |

### Run the Widgets example on its own

The Widgets example depends only on fflib, so it doesn't need the Warehouse app or the agent publish step. Clone fflib as shown in [Deploy fflib](#deploy-fflib), then:

```bash
sf org create scratch --definition-file config/project-scratch-def.json --alias widgets-mfg
( cd /tmp/fflib-apex-mocks && sf project deploy start --source-dir sfdx-source/apex-mocks --target-org widgets-mfg --wait 15 )
( cd /tmp/fflib-apex-common && sf project deploy start --source-dir sfdx-source/apex-common --target-org widgets-mfg --wait 20 --ignore-warnings )
sf project deploy start --source-dir force-app/mocking-with-widgets --target-org widgets-mfg --wait 15
```

Then run the tests below with `--target-org widgets-mfg`.

### Run the Widgets tests

These run in either org; change `--target-org` to match:

```bash
sf apex run test --class-names WDGT_UnitOfWorkTest --class-names WDGT_WidgetsServiceTest \
  --class-names WDGT_WidgetsSelectorTest --class-names WDGT_WidgetsTriggerHandlerTest \
  --class-names WDGT_WidgetsUtilityTest --target-org session005-mfg --wait 20 --result-format human
```

Each `WDGT_UnitOfWorkTest` test writes a `TIMING` line to its debug log (elapsed and CPU milliseconds, SOQL queries, DML statements), so the three approaches can be compared. Open the log in the Developer Console.

### Optional demo: a validation rule breaks DML-dependent tests

The `WDGT_MightBeRequired` validation rule requires **Might Be Required** and deploys inactive. In Setup, open Object Manager → **Widget** → Validation Rules, activate it, and rerun the Widgets tests. The tests that save widgets fail even though no Apex changed; the mocked and inert tests still pass. Deactivate the rule afterwards.

## Architecture notes

The Selector examples added in Session 004 (per-query access, additive fields, cursors, pagination) remain; see the [Session 004 README](../Session004_QueryLogicAsFirstClassArchitectureConcern/README.md).

The Widgets example follows the same patterns as the inherited code: `newInstance()` is the default composition, constructors take collaborators so tests can inject mocks, `WDGT_UnitOfWork.mock` substitutes the Unit of Work, and there is no `Application` factory.

The following describes the inherited implementation:

This sample uses **concrete** Domain, Selector, and Service classes. Constructors take collaborators; `newInstance()` is the default composition. Prefer `X.newInstance()` at entry points over `new X()`. Use the constructor to inject selector and service mocks during Apex tests. Service methods that persist call `UnitOfWork.newInstance()` so each persist gets a fresh Unit of Work — it is not a constructor-injected reusable resource (`commitWork()` does not clear registered work). Tests set `UnitOfWork.mock` to substitute that instance. Callers that already own a Unit of Work pass it as a method argument (for example `FulfillmentService` to `MaintenanceService`). Domain `newInstance(records)` keeps a `@TestVisible` mock for mid-method construction. This sample does not include an `Application` factory.

Domains wrap records, so they are constructed when those records are in hand — including mid-method, as when `FulfillmentService.completeLines` builds `FulfillmentLines` and `Robots`. Domain `newInstance(records)` keeps a `@TestVisible` mock for that case. This sample does not include an `Application` factory.

## Deploy the Warehouse app

This deploys the Widgets example too, since it lives under `force-app`. To run Widgets alone, see [Run the Widgets example on its own](#run-the-widgets-example-on-its-own).

### Create a scratch org

```bash
sf org create scratch --definition-file config/project-scratch-def.json --alias session005-mfg
```

### Deploy fflib

The sample depends on Apex Mocks and Apex Common. Clone them once, then deploy from inside each clone.

```bash
git clone --depth 1 https://github.com/apex-enterprise-patterns/fflib-apex-mocks.git /tmp/fflib-apex-mocks
git clone --depth 1 https://github.com/apex-enterprise-patterns/fflib-apex-common.git /tmp/fflib-apex-common
```

```bash
( cd /tmp/fflib-apex-mocks && sf project deploy start --source-dir sfdx-source/apex-mocks --target-org session005-mfg --wait 15 )
( cd /tmp/fflib-apex-common && sf project deploy start --source-dir sfdx-source/apex-common --target-org session005-mfg --wait 20 --ignore-warnings )
```

### Deploy force-app

```bash
sf project deploy start --source-dir force-app --target-org session005-mfg --wait 15 --ignore-errors
```

`--ignore-errors` is only needed on a brand-new org. `WarehouseOperations` grants Agent Access to `WarehouseFulfillment`, and that Bot does not exist until you publish. Without `--ignore-errors` Salesforce rolls back the whole deploy — app and tests.

## Load sample data

```bash
./bin/data.sh -o session005-mfg
```

The copied data script creates North Hub, Picker 100, Atlas / Bolt / Ember, a High-priority ticket with three pending lines, and extra draft orders.

To delete warehouse sample objects and reload:

```bash
./bin/data.sh -cleanup -o session005-mfg
```

## Warehouse Fulfillment agent

Publish first — `WarehouseOperations` cannot deploy until the Bot exists, and Apex tests need that permission set.

```bash
sf agent publish authoring-bundle --api-name WarehouseFulfillment \
  --skip-retrieve --target-org session005-mfg

sf agent activate --api-name WarehouseFulfillment --target-org session005-mfg --json
```

`--skip-retrieve` keeps generated Bot / planner metadata out of the repo. Source of truth is `force-app/main/aiAuthoringBundles/WarehouseFulfillment/`.

Inherited agent example: from the utility bar, say **Process North Hub** — the desk action takes the warehouse name.

Run the same package deploy again so the permission set can resolve the Bot, then assign it:

```bash
sf project deploy start --source-dir force-app --target-org session005-mfg --wait 15

sf org assign permset --name WarehouseOperations --target-org session005-mfg
sf org assign permset --name UseSetupWithAgentforce --target-org session005-mfg
```

## Run Apex tests

Run these after the second `force-app` deploy and `WarehouseOperations` assign. Integration tests look up that permission set, and some inserts run as the current user.

```bash
sf apex run test --test-level RunLocalTests --target-org session005-mfg --wait 20 --result-format human
```

## Test the agent

```bash
./scripts/agent/warehouse-fulfillment.sh -o session005-mfg
```

Reloads the warehouse fixtures, runs a live `sf agent preview` session against the authoring bundle, and SOQL-asserts extra robots were created and that one dispatch assigned every pending North Hub line.

The agent looks up North Hub by name with `GetWarehouseDesk`, creates robots through the Create Robot flow, and calls `ReleaseOrders` and `DispatchWarehouse` with record names. Do not add generated Bot or planner metadata to the repo; publish with `--skip-retrieve`.

To deploy, publish, activate, then test in one step:

```bash
./scripts/agent/warehouse-fulfillment.sh -o session005-mfg --deploy
```

## PaginationCursor demo

The `scripts/apex/*-paging.apex` scripts are carried over from Session 004; see the [Session 004 README](../Session004_QueryLogicAsFirstClassArchitectureConcern/README.md) for how to run them.

## Build and preview the slides

The deck starts from the Session 004 template. From this session directory:

```bash
./slides/bin/build.sh
./slides/bin/preview.sh
```

Replace the remaining slide placeholders as the session is developed.
