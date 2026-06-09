# Code With Sally React App (TypeScript)

A small example React UI Bundle for the Salesforce platform, built with Vite, **TypeScript**, Tailwind, shadcn/ui, and the Salesforce UI Bundle SDK. It has a couple of real example pages - an **Accounts** table (read + inline edit via GraphQL) and a **Contact** form (creates a Lead via Apex REST) - plus a home page, nav, routing, and a 404.

This is the original, type-safe version. It also generates GraphQL operation types from your org's schema so queries and mutations are checked at compile time.

This UI Bundle lives inside an SFDX project. The project root is the directory that contains `force-app/` and `sfdx-project.json`. Run the commands in the sections below from the paths indicated.

## The three variants

The repo ships the same example app three ways so you can pick the right starting point:

| Bundle | Language | UI | Best for |
| --- | --- | --- | --- |
| **`CodeWithSallyReactApp`** ← _you are here_ | TypeScript (`.tsx`) | shadcn/ui + Tailwind | A type-safe starter with generated GraphQL types |
| `CodeWithSallyReactAppJS` | JavaScript (`.jsx`) | shadcn/ui + Tailwind | The same app without TypeScript or codegen |
| `CodeWithSallyReactAppSimple` | JavaScript (`.jsx`) | Plain HTML + light Tailwind | Learning the core concepts - Accounts & Contact stripped to the essentials |

All three share the **same data layer** (`src/api/*`) and the **same Salesforce wiring**. They differ only in language and how much UI scaffolding sits on top.

What's specific to this (TypeScript) variant:

- Source is `.ts` / `.tsx` with full type annotations.
- GraphQL **codegen** generates operation types into `src/api/graphql-operations-types.ts` from the org schema. Run `npm run graphql:schema` to download the schema; the Vite plugin then runs codegen on dev/build.
- `npm run build` runs `tsc -b` (type-check) before `vite build`.

## How it works

- **Entry & routing** - `index.html` loads `src/app.tsx`, which mounts React and renders the routes from `src/routes.tsx`. Pages live in `src/pages/`; shared UI is in `src/components/`.
- **Talking to Salesforce** - `src/api/graphqlClient.ts` calls `createDataSDK()` from `@salesforce/sdk-data`. The SDK hands you `data.graphql(...)` and `data.fetch(...)` already authenticated against the running org (it wires in the instance URL + session token). In local dev, `@salesforce/vite-plugin-ui-bundle` proxies any `/services/...` request to your default org.
- **Accounts page** - `src/api/accounts.ts` runs a GraphQL **query** (`getAccounts`) against the UI API to list accounts, and a GraphQL **mutation** (`updateAccount`) to save inline edits. `Accounts.tsx` keeps the rows in React state and patches a row locally after a successful save (no refetch).
- **Contact form** - `src/api/leads.ts` POSTs the form to a custom Apex REST endpoint (`/services/apexrest/lead`) via `data.fetch`, which creates a Lead. `Contact.tsx` manages the field state and submit status.

## Run (development)

From the UI Bundle directory (`force-app/main/default/uiBundles/CodeWithSallyReactApp`):

```bash
npm install
npm run graphql:schema   # optional: download org schema so codegen can run
npm run dev
```

This starts the Vite dev server (e.g. http://localhost:5173). Use `npm run dev:design` to run in design mode. Talking to a real org requires an authenticated default org (`sf org login web`).

## Build

From the UI Bundle directory:

```bash
npm install
npm run build
```

`npm run build` type-checks (`tsc -b`) and then builds with Vite. The production build is written to `dist/` inside the UI Bundle folder.

## Deploy

From the **SFDX project root** (the directory that contains `force-app/`):

1. Build the UI Bundle:

   ```bash
   cd force-app/main/default/uiBundles/CodeWithSallyReactApp && npm install && npm run build && cd -
   ```

2. Deploy the UI Bundle only:

   ```bash
   sf project deploy start --source-dir force-app/main/default/uiBundles --target-org <alias>
   ```

   Or deploy all metadata:

   ```bash
   sf project deploy start --source-dir force-app --target-org <alias>
   ```

   Replace `<alias>` with your target org alias.

## Test

From the UI Bundle directory:

```bash
npm install
npm run test       # unit tests (Vitest)
```

For end-to-end tests (Playwright), build with the E2E asset rewrite and then run Playwright:

```bash
npm run build:e2e
npx playwright test
```

Ensure Chromium is installed (`npx playwright install chromium` if needed).
