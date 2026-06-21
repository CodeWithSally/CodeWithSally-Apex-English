# Code With Sally - React UI Bundles

This project contains **three versions of the same React app**, built as Salesforce UI Bundles. They all do the same thing - an **Accounts** page (list + inline-edit accounts via GraphQL) and a **Contact** form (creates a Lead via Apex REST) - but each version is aimed at a different audience.

Pick the one that fits how you want to work. They all live under `force-app/main/default/uiBundles/`.

| Version | Folder | Language | UI |
| --- | --- | --- | --- |
| [TypeScript](#1-typescript-version) | `CodeWithSallyReactApp` | TypeScript (`.tsx`) | shadcn/ui + Tailwind |
| [JavaScript](#2-javascript-version) | `CodeWithSallyReactAppJS` | JavaScript (`.jsx`) | shadcn/ui + Tailwind |
| [Simple](#3-simple-version) | `CodeWithSallyReactAppSimple` | JavaScript (`.jsx`) | Plain HTML + light Tailwind |

All three share the **same data layer** (`src/api/*`) and the **same Salesforce wiring** - they differ only in language and how much UI scaffolding sits on top.

---

## 1. TypeScript version

**Folder:** `force-app/main/default/uiBundles/CodeWithSallyReactApp`

The original, **type-safe** version. Source is `.ts` / `.tsx` with full type annotations, and it uses GraphQL **codegen** to generate operation types from your org's schema, so queries and mutations are checked at compile time. The build type-checks (`tsc -b`) before bundling.

**Use this if** you want types and the extra safety of generated GraphQL types.

---

## 2. JavaScript version

**Folder:** `force-app/main/default/uiBundles/CodeWithSallyReactAppJS`

The **same app with TypeScript removed** - plain `.js` / `.jsx`, no type annotations, no GraphQL codegen, and no `*.d.ts`/`tsconfig`. The pages, shadcn/ui components, styling, and routing are otherwise identical to the TypeScript version. The build is just `vite build`.

**Use this if** you want the full app and UI but would rather not deal with TypeScript or codegen.

---

## 3. Simple version

**Folder:** `force-app/main/default/uiBundles/CodeWithSallyReactAppSimple`

A **stripped-down, learner-focused** JavaScript version. It's the same app as the JavaScript version, but the **Accounts** page and **Contact** form are rewritten with plain HTML elements (`<table>`, `<input>`, `<form>`, `<button>`) and only a little Tailwind - no shadcn/ui components. That keeps the core concepts front and center: the SDK call, a GraphQL query + mutation, an Apex REST form post, and React state. The rest of the app is unchanged.

**Use this if** you're learning how a UI Bundle talks to Salesforce and want the least UI noise.

---

## How they work (all three)

- **Entry & routing** - `index.html` loads `src/app` (`.jsx`/`.tsx`), which mounts React and renders the routes in `src/routes`. Pages live in `src/pages/`.
- **Talking to Salesforce** - `src/api/graphqlClient` calls `createDataSDK()` from `@salesforce/sdk-data`, which provides `data.graphql(...)` and `data.fetch(...)` already authenticated against the running org. In local dev, `@salesforce/vite-plugin-ui-bundle` proxies `/services/...` requests to your default org.
- **Accounts page** - `src/api/accounts` runs a GraphQL **query** (`getAccounts`) to list accounts and a GraphQL **mutation** (`updateAccount`) to save inline edits.
- **Contact form** - `src/api/leads` POSTs the form to a custom Apex REST endpoint (`/services/apexrest/lead`) to create a Lead.

## Getting started

Each bundle is a self-contained npm project. From its folder:

```bash
npm install
npm run dev      # Vite dev server, e.g. http://localhost:5173
```

See each bundle's own `README.md` for full run / build / deploy / test instructions.

> **Note (JavaScript & Simple versions):** the `@salesforce/*` packages are pinned to `1.120.6` and must move together - `data.graphql()` changed signature in newer releases, so don't bump them piecemeal.
