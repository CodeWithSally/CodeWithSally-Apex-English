# Code With Sally React App (Simple)

A simplified, **learner-focused** JavaScript / JSX version of the Code With Sally React App. It's the same app as `CodeWithSallyReactAppJS`, but the **Accounts** page and **Contact** form are rewritten with plain HTML elements and a little Tailwind (no shadcn/ui components), so the core concepts stand out without a design-system layer in the way:

- fetching data with the Salesforce UI Bundle SDK,
- a GraphQL query and mutation,
- an Apex REST form post, and
- React state (`useState` / `useEffect`).

Everything else (home, nav, routing, 404) is unchanged. Start here if you're learning how a UI Bundle talks to Salesforce.

This UI Bundle lives inside an SFDX project. The project root is the directory that contains `force-app/` and `sfdx-project.json`. Run the commands in the sections below from the paths indicated.

## The three variants

The repo ships the same example app three ways so you can pick the right starting point:

| Bundle | Language | UI | Best for |
| --- | --- | --- | --- |
| `CodeWithSallyReactApp` | TypeScript (`.tsx`) | shadcn/ui + Tailwind | A type-safe starter with generated GraphQL types |
| `CodeWithSallyReactAppJS` | JavaScript (`.jsx`) | shadcn/ui + Tailwind | The same app without TypeScript or codegen |
| **`CodeWithSallyReactAppSimple`** ← _you are here_ | JavaScript (`.jsx`) | Plain HTML + light Tailwind | Learning the core concepts - Accounts & Contact stripped to the essentials |

All three share the **same data layer** (`src/api/*`) and the **same Salesforce wiring**. They differ only in language and how much UI scaffolding sits on top.

What's specific to this (Simple) variant vs. `CodeWithSallyReactAppJS`:

- **`src/pages/Accounts.jsx`** uses a native `<table>` and `<input>` / `<button>` elements instead of the shadcn `Table`, `Input`, `Button`, and `Badge` components.
- **`src/pages/Contact.jsx`** uses a native `<form>` with `<input>` / `<textarea>` / `<button>` instead of the shadcn `Input` / `Button` and `StatusAlert`.
- Both pages use only a few readable Tailwind classes and include short teaching comments.
- The **data layer is identical** to the other variants - only the presentation changed. The rest of the app still uses the shadcn components.

## How it works

- **Entry & routing** - `index.html` loads `src/app.jsx`, which mounts React and renders the routes from `src/routes.jsx`. Pages live in `src/pages/`.
- **Talking to Salesforce** - `src/api/graphqlClient.js` calls `createDataSDK()` from `@salesforce/sdk-data`. The SDK hands you `data.graphql(...)` and `data.fetch(...)` already authenticated against the running org (it wires in the instance URL + session token). In local dev, `@salesforce/vite-plugin-ui-bundle` proxies any `/services/...` request to your default org.
- **Accounts page** - `src/api/accounts.js` runs a GraphQL **query** (`getAccounts`) against the UI API to list accounts, and a GraphQL **mutation** (`updateAccount`) to save inline edits. `Accounts.jsx` loads the rows into state with `useEffect`, lets you edit a row into a `draft`, then saves and patches that row locally.
- **Contact form** - `src/api/leads.js` POSTs the form to a custom Apex REST endpoint (`/services/apexrest/lead`) via `data.fetch`, which creates a Lead. `Contact.jsx` keeps one piece of `useState` per field plus a submit `status`.

> **Dependency note:** the `@salesforce/*` packages (`sdk-data`, `sdk-core`, `ui-bundle`, `vite-plugin-ui-bundle`) are **pinned to `1.120.6`** and must move together. `data.graphql()` changed from positional arguments to a single options object in newer versions, so bumping them piecemeal - or letting the lockfile float - breaks every GraphQL call. `@salesforce/sdk-core` is forced to `1.120.6` in the `overrides` block because it is a transitive dependency that otherwise floats.

## Run (development)

From the UI Bundle directory (`force-app/main/default/uiBundles/CodeWithSallyReactAppSimple`):

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
   cd force-app/main/default/uiBundles/CodeWithSallyReactAppSimple && npm install && npm run build && cd -
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
