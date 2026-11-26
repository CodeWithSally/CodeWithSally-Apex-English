# cws-session10-a: the Demo Salesforce Project

This is a copy of the private GitHub repo `cws-session10-a`, the repository connected to the cloud environment and to every routine in this session. It shows the repo at the start of the session, before anything was fixed. `Greeter.greet` still has the seeded "Helo" typo.

## What makes it work in the cloud

| File | Role |
|---|---|
| `.claude/settings.json` | A **SessionStart hook** that runs a login script before Claude starts each cloud session |
| `scripts/cloud-sf-login-simple.sh` | The version used live: pipes `$SFDX_AUTH_URL` into `sf org login sfdx-url` and sets alias `cws` as the default org |
| `scripts/cloud-sf-login.sh` | The same login with safety checks: it skips when there's no token (so it does nothing on your laptop), skips when `sf` is missing, and hides the CLI output, because a failed login prints the auth URL back |
| `CLAUDE.md` | The org rules a cloud session can't know on its own: deploy with `RunSpecifiedTests`, state and country picklists, permission sets for new fields, one trigger per object with the logic in a class |
| `force-app/main/default/classes/Greeter*.cls` | The seeded bug used in the first demo |

To use the safer script, point the hook's `command` at `scripts/cloud-sf-login.sh`.

## Why the CLAUDE.md matters

A cloud session loads the repo's `CLAUDE.md`. Nothing from your laptop's settings comes along. In rehearsal, the same feature issue failed three deploys without it (missing country, `VA` instead of `Virginia`, a field the tests couldn't see) and passed on the second deploy with it.

It also held during the live session. When a comment on issue #21 asked to move the logic into the trigger, the routine declined and quoted the "one trigger per object, with the logic in a class" rule. See `../4-routine-issue-labeled/`.

## Demo 1: an interactive fix

In a session on this environment we asked Claude to "run the Greeter.greet method". It spotted the typo, and when asked to "fix the typo, deploy, and run all Apex tests and report the results" it changed `Greeter` and tightened `GreeterTest`. It then deployed, ran the tests (3 of 3 passed) and pushed the fix to a new branch. It didn't touch `main`.
