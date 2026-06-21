# Code With Sally React App (JavaScript)

The **JavaScript / JSX** version of the Code With Sally React App - the same example UI Bundle as the TypeScript original, with the types removed. Built with Vite, Tailwind, shadcn/ui, and the Salesforce UI Bundle SDK. It has a couple of real example pages - an **Accounts** table (read + inline edit via GraphQL) and a **Contact** form (creates a Lead via Apex REST) - plus a home page, nav, routing, and a 404.

Use this if you want the full app and UI but would rather not deal with TypeScript or GraphQL codegen.

This UI Bundle lives inside an SFDX project. The project root is the directory that contains `force-app/` and `sfdx-project.json`. Run the commands in the sections below from the paths indicated.

## The three variants

The repo ships the same example app three ways so you can pick the right starting point:

| Bundle | Language | UI | Best for |
| --- | --- | --- | --- |
| `CodeWithSallyReactApp` | TypeScript (`.tsx`) | shadcn/ui + Tailwind | A type-safe starter with generated GraphQL types |
| **`CodeWithSallyReactAppJS`** ← _you are here_ | JavaScript (`.jsx`) | shadcn/ui + Tailwind | The same app without TypeScript or codegen |
| `CodeWithSallyReactAppSimple` | JavaScript (`.jsx`) | Plain HTML + light Tailwind | Learning the core concepts - Accounts & Contact stripped to the essentials |

All three share the **same data layer** (`src/api/*`) and the **same Salesforce wiring**. They differ only in language and how much UI scaffolding sits on top.

What's specific to this (JavaScript) variant vs. the TypeScript original:

- Source is plain `.js` / `.jsx` - no type annotations.
- **No GraphQL codegen** and no generated types file. Queries are just strings; the codegen tooling, `tsconfig`, and `*.d.ts` files are gone.
- `npm run build` is just `vite build` (no `tsc -b`).
- Everything else - pages, shadcn/ui components, styling, routing - matches the TypeScript version.

## How it works

- **Entry & routing** - `index.html` loads `src/app.jsx`, which mounts React and renders the routes from `src/routes.jsx`. Pages live in `src/pages/`; shared UI is in `src/components/`.
- **Talking to Salesforce** - `src/api/graphqlClient.js` calls `createDataSDK()` from `@salesforce/sdk-data`. The SDK hands you `data.graphql(...)` and `data.fetch(...)` already authenticated against the running org (it wires in the instance URL + session token). In local dev, `@salesforce/vite-plugin-ui-bundle` proxies any `/services/...` request to your default org.
- **Accounts page** - `src/api/accounts.js` runs a GraphQL **query** (`getAccounts`) against the UI API to list accounts, and a GraphQL **mutation** (`updateAccount`) to save inline edits. `Accounts.jsx` keeps the rows in React state and patches a row locally after a successful save (no refetch).
- **Contact form** - `src/api/leads.js` POSTs the form to a custom Apex REST endpoint (`/services/apexrest/lead`) via `data.fetch`, which creates a Lead. `Contact.jsx` manages the field state and submit status.

> **Dependency note:** the `@salesforce/*` packages (`sdk-data`, `sdk-core`, `ui-bundle`, `vite-plugin-ui-bundle`) are **pinned to `1.120.6`** and must move together. `data.graphql()` changed from positional arguments to a single options object in newer versions, so bumping them piecemeal - or letting the lockfile float - breaks every GraphQL call with "Must provide a Query" / "GraphQL response is undefined". `@salesforce/sdk-core` is forced to `1.120.6` in the `overrides` block because it is a transitive dependency that otherwise floats.

## Run (development)

From the UI Bundle directory (`force-app/main/default/uiBundles/CodeWithSallyReactAppJS`):

```bash
npm install
npm run dev
```

This starts the Vite dev server (e.g. http://localhost:5173). Use `npm run dev:design` to run in design mode. Talking to a real org requires an authenticated default org (`sf org login web`).

## Build

From the UI Bundle directory:

```bash
npm install
npm run build
```

The production build is written to `dist/` inside the UI Bundle folder. Deploy using the steps in [Deploy](#deploy).

## Deploy

From the **SFDX project root** (the directory that contains `force-app/`):

1. Build the UI Bundle:

   ```bash
   cd force-app/main/default/uiBundles/CodeWithSallyReactAppJS && npm install && npm run build && cd -
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
