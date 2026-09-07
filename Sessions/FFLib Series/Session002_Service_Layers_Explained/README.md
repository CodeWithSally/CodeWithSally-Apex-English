# Session 002 — Service Layers Explained

This session is about the Service layer and Unit of Work ([slides](slides/presentation.html)). Warehouse Operations is the desk: Fulfillment, Dispatch, and Maintenance are named for the process; Domain classes are named for the object. The sample uses fflib. Activating and testing the Warehouse Fulfillment agent is not covered in the presentation; the steps below are a bonus demonstration for anyone interested.

One package directory: `force-app` (app in `main`, Apex tests in `test`), plus the Warehouse Fulfillment employee agent.

Use a scratch org from `config/project-scratch-def.json` (Einstein / Agentforce enabled). Alias used below is `session002-mfg`.

## Deploy the app

### Create a scratch org

```bash
sf org create scratch --definition-file config/project-scratch-def.json --alias session002-mfg
```

### Deploy fflib

The sample depends on Apex Mocks and Apex Common. Clone them once, then deploy from inside each clone.

```bash
git clone --depth 1 https://github.com/apex-enterprise-patterns/fflib-apex-mocks.git /tmp/fflib-apex-mocks
git clone --depth 1 https://github.com/apex-enterprise-patterns/fflib-apex-common.git /tmp/fflib-apex-common
```

```bash
( cd /tmp/fflib-apex-mocks && sf project deploy start --source-dir sfdx-source/apex-mocks --target-org session002-mfg --wait 15 )
( cd /tmp/fflib-apex-common && sf project deploy start --source-dir sfdx-source/apex-common --target-org session002-mfg --wait 20 --ignore-warnings )
```

### Deploy force-app

```bash
sf project deploy start --source-dir force-app --target-org session002-mfg --wait 15 --ignore-errors
```

`--ignore-errors` is only needed on a brand-new org. `WarehouseOperations` grants Agent Access to `WarehouseFulfillment`, and that Bot does not exist until you publish. Without `--ignore-errors` Salesforce rolls back the whole deploy — app and tests.

## Load sample data

```bash
./bin/data.sh -o session002-mfg
```

Creates North Hub, Picker 100, Atlas / Bolt / Ember, the original High ticket (three pending lines), and extra draft orders so three idle robots cannot cover every line in one dispatch.

To delete warehouse sample objects and reload:

```bash
./bin/data.sh -cleanup -o session002-mfg
```

## Run Apex tests

```bash
sf apex run test --test-level RunLocalTests --target-org session002-mfg --wait 20 --result-format human
```

## Warehouse Fulfillment agent (bonus)

Activating and testing the agent below is not covered in the presentation. It is included as a bonus demonstration for anyone interested.

```bash
sf agent publish authoring-bundle --api-name WarehouseFulfillment \
  --skip-retrieve --target-org session002-mfg

sf agent activate --api-name WarehouseFulfillment --target-org session002-mfg --json
```

`--skip-retrieve` keeps generated Bot / planner metadata out of the repo. Source of truth is `force-app/main/aiAuthoringBundles/WarehouseFulfillment/`.

From the utility bar, say **Process North Hub** — the desk action takes the warehouse name.

Run the same package deploy again so the permission set can resolve the Bot:

```bash
sf project deploy start --source-dir force-app --target-org session002-mfg --wait 15

sf org assign permset --name WarehouseOperations --target-org session002-mfg
sf org assign permset --name UseSetupWithAgentforce --target-org session002-mfg
```

### Test the agent

```bash
./scripts/agent/warehouse-fulfillment.sh -o session002-mfg
```

Reloads the warehouse fixtures, runs a live `sf agent preview` session against the authoring bundle, and SOQL-asserts extra robots were created and that one dispatch assigned every pending North Hub line.

The agent looks up North Hub by name with `GetWarehouseDesk`, creates robots through the Create Robot flow, and calls `ReleaseOrders` and `DispatchWarehouse` with record names. Do not add generated Bot or planner metadata to the repo; publish with `--skip-retrieve`.

To deploy, publish, activate, then test in one step:

```bash
./scripts/agent/warehouse-fulfillment.sh -o session002-mfg --deploy
```

A passing preview looks like this. Draft order names are auto-numbers, so later runs may show `FO-00002` instead of `FO-00014`.

```
Agent: I can review warehouse robots against pending fulfillment work, create robots when you are short, release draft orders, and run one dispatch. What would you like to do?

You:   Process North Hub orders optimally with one dispatch and create robots if necessary. Do this now. Do not ask for confirmation.

Agent: I created 8 robots (North Spare 1 through North Spare 8), released draft orders FO-00001, FO-00014, FO-00015, and FO-00016, and ran one dispatch at North Hub. Would you like to process another warehouse or check the status of your robots?
```
