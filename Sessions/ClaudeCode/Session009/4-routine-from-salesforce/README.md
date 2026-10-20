# Salesforce → Claude Code routine (API trigger)

When an Account is created, a record-triggered Flow calls a Claude Code routine's API trigger with the Account's name, website and Id. The routine researches the company and posts a brief to Slack. This folder is the Salesforce half, retrieved from the demo org used in Claude with Sally, Part 9.

```
Account created → Flow (async path) → HTTP Callout (External Service) → Named Credential → POST /fire → Claude routine → Slack
```

## What's here

| Metadata | Name | What it does |
|---|---|---|
| External Credential | `Claude_Routine` | Holds the routine's token (principal `Token`) and adds three headers: `Authorization: Bearer <token>`, `anthropic-beta: experimental-cc-routine-2026-04-01`, `anthropic-version: 2023-06-01` |
| Named Credential | `Claude_Routine` | `https://api.anthropic.com`, using the External Credential. **Allow Formulas in HTTP Header** is on |
| External Service | `ClaudeRoutine` | One action, `fireRoutine`: POSTs `{"text": "..."}` to the routine's `/fire` path |
| Flow | `Account_Fire_Claude_Routine` | Record-triggered on Account create; async path builds the text and calls `fireRoutine` |
| Permission Set | `Claude_Routine_Access` | Grants access to the `Token` principal |

The token is not in this folder. Salesforce never exports credential secrets.

## Set it up in your org

1. **Create the routine** at claude.ai/code/routines with an **API** trigger. Copy its URL and generate a token (shown once).
2. **Point the External Service at your routine.** In `externalServiceRegistrations/ClaudeRoutine.externalServiceRegistration-meta.xml`, replace `trig_YOUR_ROUTINE_ID` in the path with your routine's ID.
3. **Deploy:** `sf project deploy start -o <your-org>`
4. **Add the token:** Setup → Named Credentials → External Credentials → `Claude Routine` → Principals → `Token` → Edit → add an authentication parameter named exactly `Token` with your routine's token as the value.
5. **Assign the permission set:** `sf org assign permset -n Claude_Routine_Access -o <your-org>`
6. **Test:** create an Account, then check the routine's runs on claude.ai.

The routine's prompt (research the company, post one brief to Slack) is in `account-research-routine-prompt.md`.

## Gotchas we hit

- **401 on every call:** turn on **Allow Formulas in HTTP Header** on the Named Credential. Without it, the `{!...}` header formula is sent as literal text, so no token reaches Anthropic.
- **No error anywhere:** the Flow's HTTP Callout treats any response, including a 401, as success. No flow error email arrives. Check the routine's run list, or test from Anonymous Apex and read the status code.
- **Callout from a trigger context:** the Flow uses an async path (`AsyncAfterCommit`) because callouts can't run in the same transaction as the save.
- **Fire text is untrusted:** the routine receives it wrapped as untrusted data, and the routine's prompt has to say to act on it. Send record IDs and public fields, not record content.
- **Rate limit:** 30 fires per routine per hour. A bulk insert of Accounts can exceed it.
