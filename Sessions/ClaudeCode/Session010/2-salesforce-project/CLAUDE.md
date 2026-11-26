# cws-session10-a

A small Salesforce DX project used to demonstrate Claude Code working unattended in a cloud environment. Source is in `force-app/`, API version 68.0.

## The org

There is one org, a shared Developer Edition org, and it is already the CLI's default. Never pass `--target-org`, and never create scratch orgs.

The org holds other people's code. That has two consequences:

- **Deploy with `RunSpecifiedTests`**, naming every test class under `force-app/`. `RunLocalTests` runs the whole org's tests and fails on org-wide coverage.
- **Deploy only `force-app/`.** Don't retrieve, change or delete anything this repo doesn't own, apart from the page layouts described below.

## Things about this org that break deploys

These have each failed a deploy here. Check your change against them before the first attempt.

- **State and country picklists are on.** An address with a state must also have a country, and both must be values from the picklists: `BillingCountry = 'United States'`, `BillingState = 'Virginia'`. The abbreviation `'VA'` is rejected in `BillingState`. The code fields work too: `BillingCountryCode = 'US'`, `BillingStateCode = 'VA'`.
- **A new field is invisible until a permission set grants it.** Fields deployed from source get no field-level security on any profile, including System Administrator. Ship a permission set with every new field.
- **User-mode code can't see a new field in tests.** Anything using `WITH USER_MODE`, `as user` or `AccessLevel.USER_MODE` fails with "No such column" or "fields being inaccessible" unless the test runs as a user who has the permission set. Either assign it inside the test (`System.runAs` with a test-only `PermissionSetAssignment`) or, for background automation that fills in a field no user typed, write in system mode.
- **Don't assign permission sets to real users** as a way to get tests passing. Fix the test.

## Conventions

- **New fields go on the page layout.** Retrieve the object's main layout fresh from the org (for Account: `sf project retrieve start --metadata "Layout:Account-Account Layout"`), add the field to a sensible section, and deploy it with the rest. Always retrieve before editing, even if a copy is already in the repo, so you don't overwrite someone else's layout change.
- **Callouts go through a named credential** stored in `force-app/`, never a hard-coded URL. Mock every callout in tests.
- **Callouts triggered by a record save run asynchronously.**
- One trigger per object, with the logic in a class.
- Tests assert exact values, not `contains`.
