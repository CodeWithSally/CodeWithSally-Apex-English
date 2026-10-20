# Widgets

**Mocking with FFLib**

A small, self-contained example for Session 005. One object, one Service method, and the collaborators around it, small enough that each idea in the session fits on a slide. The same method is tested several ways: fully mocked, over an inert Unit of Work, and with real DML and SOQL, so the difference is visible side by side.

Everything here is prefixed `WDGT_`, a namespace-like prefix inside one package. Session 006 takes that separation across packages.

With this example you'll see:

- a Service with `newInstance()` for callers and a constructor where tests inject mocks;
- a GUID generator that tests must mock, because its output can't be predicted;
- a Unit of Work factory with a `@TestVisible` static `mock` for stateful substitution;
- an inert IDML that saves nothing and records what would have been saved;
- the cheap coverage tests for a Selector and a trigger;
- two marked demonstrations of what mocks hide and what DML-dependent tests suffer.

[Session README](../../README.md) · [Slides](../../slides/presentation.html)

## The example

`WDGT_WidgetsService.tagWidgetsWithGuid(Set<Id>)` selects the widgets, gives each a new GUID, registers each as dirty with a Unit of Work, and commits.

**Schema:** `WDGT_Widget__c` (auto-number Name), `WDGT_Guid__c` (Text 32), and `WDGT_MightBeRequired__c` with the inactive validation rule `WDGT_MightBeRequired`. The `WDGT_Widgets` permission set grants access to the object and both fields.

| Class | Role |
|---|---|
| `WDGT_WidgetsService` | The method under test. `newInstance()` for callers; a constructor that takes the Selector and utility, where tests inject mocks |
| `WDGT_WidgetsSelector` | Queries widgets by Id, in user mode. Converts a null Id set to empty and runs the query. Deliberately doesn't query `WDGT_MightBeRequired__c` |
| `WDGT_WidgetsUtility` | `generateGuid()`: a 32-character version 4 GUID; random, so tests must mock it |
| `WDGT_UnitOfWork` | Unit of Work factory registering `WDGT_Widget__c`, with a `@TestVisible` static `mock` |
| `WDGT_WidgetsTriggerHandler` and `WDGT_Widgets.trigger` | A thin trigger handler with no logic yet |
| `WDGT_InertDml` (test) | An `IDML` that saves nothing and records what would have been saved. Inserted records get fake Ids, so relationships resolve, and `getInserted(SObjectType)` and the other getters return one type at a time |

| Test class | What it shows |
|---|---|
| `WDGT_UnitOfWorkTest` | The same method tested three ways: a mocked Unit of Work, an inert Unit of Work over `WDGT_InertDml`, and real DML and SOQL. Two more mocked tests verify the same calls with matchers, an argument captor, and in-order verification |
| `WDGT_InertDmlTest` | The inert IDML with several objects: a Contact linked to its Account through fake Ids, and records pulled back by type (standard Account and Contact; nothing is saved) |
| `WDGT_WidgetsServiceTest` | A Selector stubbed to throw; verifies nothing else is called |
| `WDGT_WidgetsSelectorTest` | Empty and null conditions. Two marked demonstrations: reading a field the Selector doesn't query (and how a mocked Selector hides it), and the hazard of tests that depend on DML |
| `WDGT_WidgetsTriggerHandlerTest` | Trigger coverage: disable the handler, save one widget |
| `WDGT_WidgetsUtilityTest` | GUID shape and randomness |

## Architecture notes

- **Composition:** `newInstance()` is the default way in. Constructors take collaborators, so tests can inject mocks. No `Application` factory, and no interfaces.
- **Stateful objects:** the Unit of Work is created inside the Service method, one per call, through `WDGT_UnitOfWork.newInstance()`. Tests set `WDGT_UnitOfWork.mock` to substitute it.
- **Selector tests** pass empty and null conditions only: they check that the query is valid and leave Salesforce's execution to Salesforce. A null set must be converted, because it throws in fflib's dynamic SOQL.
- **The trigger handler** only converts trigger specifics to general Apex and calls other logic. Its test switches the handler off with `fflib_SObjectDomain.getTriggerEvent(…).disableAll()` and saves one widget, for coverage only.
- **Tests** are named `method_WHEN_condition_EXPECT_result` and use the `Assert` class.

## Deploy the example

The Widgets example depends only on fflib (Apex Mocks and Apex Common). If you've followed the session README, it's already deployed with `force-app`; skip to [Grant access](#grant-access).

To deploy it on its own, from the session directory (`Sessions/FFLibSeries/Session005_MockingInApex`), clone fflib as shown in the session README's [Deploy fflib](../../README.md#deploy-fflib), then:

```bash
sf org create scratch --definition-file config/project-scratch-def.json --alias widgets-mfg
( cd /tmp/fflib-apex-mocks && sf project deploy start --source-dir sfdx-source/apex-mocks --target-org widgets-mfg --wait 15 )
( cd /tmp/fflib-apex-common && sf project deploy start --source-dir sfdx-source/apex-common --target-org widgets-mfg --wait 20 --ignore-warnings )
sf project deploy start --source-dir force-app/mocking-with-widgets --target-org widgets-mfg --wait 15
```

### Grant access

The Selector queries in user mode, and a fresh org gives the admin no access to the new Widget fields. Assign the permission set, or the Selector tests fail with "No such column":

```bash
sf org assign permset --name WDGT_Widgets --target-org widgets-mfg
```

## Run the tests

```bash
sf apex run test --class-names WDGT_UnitOfWorkTest --class-names WDGT_InertDmlTest --class-names WDGT_WidgetsServiceTest \
  --class-names WDGT_WidgetsSelectorTest --class-names WDGT_WidgetsTriggerHandlerTest \
  --class-names WDGT_WidgetsUtilityTest --target-org widgets-mfg --wait 20 --result-format human
```

Use `--target-org session005-mfg` instead if you deployed the whole session.

Each `WDGT_UnitOfWorkTest` test writes a `TIMING` line to its debug log (elapsed and CPU milliseconds, SOQL queries, DML statements), so the three approaches can be compared. Open the log in the Developer Console. Typical runs: mocked ≈10–35 ms with no SOQL or DML; inert ≈110–160 ms with one DML (the commit's savepoint); real DML and SOQL ≈2–2.7 s.

## Optional demo: a validation rule breaks DML-dependent tests

The `WDGT_MightBeRequired` validation rule requires **Might Be Required** and deploys inactive. In Setup, open Object Manager → **Widget** → Validation Rules, activate it, and rerun the tests. The tests that save widgets fail even though no Apex changed: `WDGT_WidgetsSelectorTest.insert_WHEN_widgetSaved_EXPECT_success`, the real DML and SOQL test in `WDGT_UnitOfWorkTest`, and the trigger coverage test. The mocked and inert tests still pass. Deactivate the rule afterwards.
