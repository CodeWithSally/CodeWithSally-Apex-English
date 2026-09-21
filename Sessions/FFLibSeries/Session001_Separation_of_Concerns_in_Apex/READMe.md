# Session 001 — Separation of Concerns in Apex

This session is about giving business logic a stable home in Apex ([slides](slides/presentation.html)). We start from anti-patterns — controllers, LWCs, and invocables owning SOQL, DML, and rules — then walk Service, Domain, and Selector so the same operations stay client-agnostic for UI, REST, batch, Flow, and Agentforce. The sample in this repo does not use fflib. That is deliberate: the focus is SoC itself, not a library. Later sessions introduce fflib on top of this sample. Activating and testing the Opportunity Operations agent is not covered in the presentation; the steps below are a bonus demonstration for anyone interested.

Two package directories. The default is `force-app.with-soc` so `sf agent publish` can find the authoring bundle.

- `force-app.with-soc` — `main` (app) and `test` (Apex tests), plus the Opportunity Operations employee agent
- `force-app.without-soc` — controllers and invocables own the SOQL and DML (`sf project deploy start --source-dir force-app.without-soc`)

Use a scratch org from `config/project-scratch-def.json` (Einstein / Agentforce enabled). Alias used below is `session001-soc`.

## Deploy the with-soc app

One deploy of the package directory. That includes Apex in `main` and tests in `test`.

```bash
sf org create scratch --definition-file config/project-scratch-def.json --alias session001-soc

sf project deploy start --source-dir force-app.with-soc --target-org session001-soc --wait 15 --ignore-errors
```

`--ignore-errors` is only needed on a brand-new org. `ApexEnterprisePatternsSampleApp` grants Agent Access to `OpportunityOperations`, and that Bot does not exist until you publish. Without `--ignore-errors` Salesforce rolls back the whole deploy — app and tests.

## Activate the agent

Activating and testing the agent below is not covered in the presentation. It is included as a bonus demonstration for anyone interested.

```bash
sf agent publish authoring-bundle --api-name OpportunityOperations \
  --skip-retrieve --target-org session001-soc

sf agent activate --api-name OpportunityOperations --target-org session001-soc --json
```

`--skip-retrieve` keeps generated Bot / planner metadata out of the repo. Source of truth is `force-app.with-soc/main/aiAuthoringBundles/OpportunityOperations/`.

On an Opportunity record page the agent reads External `currentRecordId`. From the CLI you can simulate that with `--context-variables currentRecordId=<opportunityId>`.

Run the same package deploy again so the permission set can resolve the Bot:

```bash
sf project deploy start --source-dir force-app.with-soc --target-org session001-soc --wait 15

sf org assign permset --name ApexEnterprisePatternsSampleApp --target-org session001-soc
sf org assign permset --name UseSetupWithAgentforce --target-org session001-soc
```

## Run Apex tests

```bash
sf apex run test --test-level RunLocalTests --target-org session001-soc --wait 20 --result-format human
```

## Load sample data

```bash
./bin/data.sh -o session001-soc
```

Creates accounts, products, opportunities, and line items. Two opportunities are Ready to invoice.

## Test the agent

```bash
./scripts/agent/opportunity-operations.sh -o session001-soc
```

Creates fixture opportunities, runs a live `sf agent preview` session against the authoring bundle, and SOQL-asserts a 10% discount and a created invoice.

To deploy, publish, activate, then test in one step:

```bash
./scripts/agent/opportunity-operations.sh -o session001-soc --deploy
```
