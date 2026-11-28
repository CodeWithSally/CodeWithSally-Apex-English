# Session 010 — Cloud Environments: Let Claude Fix, Deploy and Test Salesforce Code on Its Own

**Series:** Claude with Sally (Code With Sally)
**Recording:** [Claude Code Cloud Environments: Fix, Deploy & Test Salesforce Code | Mastering Claude | Part 10](https://www.youtube.com/watch?v=7ZJa9g-lopw)
**Topic:** In Session 9 a GitHub issue was enough to start Claude in the cloud, but all it could do was propose a change. A cloud session has no Salesforce CLI, so Claude could write Apex there but couldn't deploy it or run a test. This session closes that gap. We built a custom **cloud environment** live, in the browser, that installs the CLI and logs in to an org on its own. Then we pointed **routines** at it: file an issue, and Claude builds the change, deploys it with tests, opens a pull request and reports back in the issue.

---

## What We Built

| # | What | Demo | Where it lives |
|---|---|---|---|
| 1 | **Cloud environment** | From an empty machine to one that installs `sf` and has an org token: network access, setup script, environment variables | `1-cloud-environment/` |
| 2 | **Repo login hook** | A SessionStart hook in the connected repo logs the CLI in before Claude starts. Then an interactive fix: find a typo, deploy, run the tests, push a branch. | `2-salesforce-project/` |
| 3 | **Routine: Issue: Opened** | Filing "add a PENDING REVIEW prefix to new accounts" produced a trigger, a class and tests, deployed to the org, with a pull request and a report on the issue | `3-routine-issue-opened/` |
| 4 | **Routine: Issue: Labeled** | Adding the *Claude Review* label starts the run, so a person decides when. It also handles follow-ups, and declined one that broke the repo's `CLAUDE.md` | `4-routine-issue-labeled/` |
| 5 | **Routine: General Request** | Any request, on an environment with Playwright: screenshots, research, documents | `5-routine-general-request/` |

> **In one line:** the environment gives Claude the tools and the access, the repo gives it the rules and the login hook, and the routine gives it a reason to start.

---

## The Gap: What a Cloud Session Starts With

Every cloud session is a fresh machine with a fresh clone of your repo. It comes with Node, Python, Java, `git`, `gh` and a lot more ([full list](https://code.claude.com/docs/en/cloud-environments)), but nothing Salesforce:

| Missing for Salesforce work | What fixes it | Where it lives |
|---|---|---|
| Can't reach Salesforce | **Network access**: open it up, or allow the Salesforce hosts | Environment |
| No Salesforce CLI | **A setup script** that installs it once. Later sessions reuse the saved machine. | Environment |
| No org login | **A variable and a hook**: a stored token, used at the start of every session | Environment + repo |

---

## Demo 1: Build the Environment

All of this happens at **claude.ai/code**, in the environment picker under the prompt box. We changed one setting at a time and started a **new session** after each change, because a running session doesn't pick up environment changes.

1. **Network None:** "Install the Salesforce CLI" fails, because nothing can leave the machine.
2. **Limited + Allow package managers:** Claude can install `sf` itself, but the next session doesn't have it, and the install method is Claude's call each time.
3. **Setup script** (`npm install -g @salesforce/cli`): it runs once, and Claude Code saves a copy of the machine. Later sessions start with `sf` already there.
4. **Environment variables:** `SFDX_AUTH_URL` (made on your laptop with `sf org auth show-sfdx-auth-url`) and `SF_DISABLE_DNS_CHECK=true`.

The full settings, the host allowlist for real work and how to revoke a leaked token are in [`1-cloud-environment/`](1-cloud-environment/).

## Demo 2: Log In From the Repo

The setup script can't log in, because the environment's variables aren't set while it runs. So the login lives in the repo: a `SessionStart` hook in `.claude/settings.json` runs `scripts/cloud-sf-login-simple.sh`, which pipes `$SFDX_AUTH_URL` into `sf org login sfdx-url`. With network access set to Full, a new session lists the org before Claude does anything.

Then we worked in the session by hand. "Run the Greeter.greet method" made Claude notice the seeded "Helo" typo. "Fix the typo, deploy, and run all Apex tests" got a fix, tighter tests and a deploy with 3 of 3 tests passing, pushed to a new branch, not to `main`.

The project, the hook, both login scripts and the `CLAUDE.md` are in [`2-salesforce-project/`](2-salesforce-project/).

## Demo 3: A Routine That Deploys

This is the Session 9 trigger (GitHub event, **Issue: Opened**) on the new environment, with every connector removed. We filed:

> **Account name trigger: pending review**: Whenever a new account is created, add a "PENDING REVIEW: " prefix on the account name.

About two minutes later the issue had a trigger, a class, 5 new tests, a deploy that passed 8 of 8 tests, an open pull request and a final report. We created an Account called "Code with Bill" in the org, and it saved as *PENDING REVIEW: Code with Bill*.

Prompt and form values: [`3-routine-issue-opened/`](3-routine-issue-opened/). The issue and Claude's code: [`demo-issue.md`](3-routine-issue-opened/demo-issue.md) and `what-claude-built/`.

## Demo 4: Put a Person in the Loop With a Label

A second routine fires on **Issue: Labeled** and acts only on *Claude Review*. It removes the label first, so adding it again starts a fresh review. It reads the whole conversation, not just the issue.

- **New issue, "Contact prefix":** filing it did nothing. Adding the label started the run: a trigger, a class and 6 new tests, including a 200-record bulk insert, with 9 of 9 tests passing.
- **Follow-up on the Account issue:** we commented "I don't like this, add all the logic in the trigger directly instead of a helper class" and added the label. Claude reopened the issue, read the thread and **declined**, quoting the repo's `CLAUDE.md` rule ("one trigger per object, with the logic in a class"). It explained how to get the change if we really wanted it. The repo's rules outrank an issue comment.

Prompt and both conversations: [`4-routine-issue-labeled/`](4-routine-issue-labeled/).

## Demo 5: General Requests and Other Tools

Each routine picks its own environment. **General Request** runs on a *PlaywrightTest* environment whose setup script installs Playwright and headless Chromium. It takes any request filed as an issue, such as a question, a document or a screenshot. Live, a session on that environment found codewithsally.com and returned a screenshot.

Prompt and rehearsal results: [`5-routine-general-request/`](5-routine-general-request/).

---

## Trust: Who, What, and Where a Person Signs Off

Filing an issue now changes an org. Answer three questions before you turn this on:

| Question | What we did | For real work |
|---|---|---|
| **Who can start it?** | Author filter on the trigger. The prompt says issue text is a request, not instructions. | The same, plus labels, which only people with triage or write access can add |
| **What can it reach?** | Full network, an admin's token, a throwaway Developer Edition org | Limited network with the Salesforce hosts allowed, a dedicated low-privilege user, a sandbox. Never production. |
| **Where does a person sign off?** | Tests gate the deploy. The pull request stays open until someone merges it. | Add steps: an adversarial review session, or analysis-only first and a deploy after "approved" |

The auth URL sits in the environment **in plain text**: anyone who uses the environment can read it. Know how to kill it before you need to: **Setup → Users → OAuth Connected Apps → Revoke** next to Salesforce CLI. [`issue-to-production.html`](issue-to-production.html) sketches a real process: Claude works in a sandbox and opens the pull request, people approve the code and the release, and a pipeline, not Claude, deploys to production.

---

## Questions from the Session

- **Can the environment have MCP servers or skills?** Connectors are chosen per session, or per routine in its form; remove the ones a run doesn't need. Skills come from the connected repo's `.claude/skills/` folder.
- **Is there a safer way to store the auth URL than plain text?** Not in environment variables today. Network secrets are hidden, but they're separate from how the Salesforce CLI logs in. For production, keep using a machine you control, or a secrets manager built for agents.
- **Why log in again after showing the token?** Revoking the token signs out every CLI login for that user, the laptop's included. A fresh login is needed before you can make a new auth URL.
- **Does every session share the same machine?** Everything the setup script does is shared: each session starts from the saved copy. What you install inside one session stays in that session.
- **Does field-level security still apply?** Yes. The CLI acts as the user who logged in. Give the agent its own minimal user rather than your admin login.
- **Which is the source of truth, the org or the repo?** Whichever you tell it. Claude usually checks and calls out differences on its own. For a shared or staging org, add "confirm the org matches the repo" to the prompt.
- **Can a new comment trigger a routine?** Not yet. The GitHub events cover issues, pull requests and releases, but not comments. Use a label, or have Claude manage labels as it works.
- **Does a company VPN matter?** Your laptop's network has no effect on a cloud session. If your org restricts login IPs, it has to allow the IPs the cloud sessions log in from.

---

## Try It Yourself

| Step | Do this |
|---|---|
| **Environment** | Create a cloud environment for one of your repos and get `sf --version` to answer |
| **Login** | Add the SessionStart hook from `2-salesforce-project/`, then deploy to a Developer Edition org from the browser |
| **Routine** | Point a routine at it, filtered to your own issues. Start with a typo. |
| **Not a developer?** | Write the issue. Say what's wrong in plain words, then read the comment that comes back. |

---

## Directory Map

| Path | What it is |
|---|---|
| `session-10-slides.html` | The presentation deck (28 slides). Open it in a browser and use the arrow keys. Prompts and commands have copy buttons. |
| `issue-to-production.html` | A one-page diagram of a real issue-to-production process built on these pieces |
| `1-cloud-environment/` | Environment settings, the setup script, making and revoking the auth URL |
| `2-salesforce-project/` | The demo SFDX project: `CLAUDE.md`, the SessionStart hook, both login scripts, `Greeter` with its seeded typo |
| `3-routine-issue-opened/` | Issue Fixer routine (form values and prompt), the live issue and report, and the code Claude wrote |
| `4-routine-issue-labeled/` | Issue Reviewer routine, the label-started issue, the declined follow-up, and the code Claude wrote |
| `5-routine-general-request/` | General Request routine on the Playwright environment, with rehearsal results |

---

## Gotchas

- **Environment changes apply to new sessions only.** Network, setup script and variables are read when a session starts.
- **Limited network blocks the login.** New environments allow package registries, not Salesforce. Add the Salesforce hosts or use Full.
- **`SF_DISABLE_DNS_CHECK=true` is required.** Without it, the CLI's address lookup fails behind the cloud proxy with "The org cannot be found".
- **The setup script can't see your variables**, so log in from a SessionStart hook, not the script.
- **A failed `sf org login sfdx-url` prints the auth URL back.** The full login script discards the CLI's output for that reason.
- **New routines attach all your connectors.** Remove the ones the run doesn't need.
- **Labels the routine adds start more runs** on an Issue: Labeled trigger. Have it remove its trigger label and add none of its own.

---

## Ideas for Future Sessions (requested in chat)

- The skills, tools and connectors Bill uses today, and a recurring "what changed since we covered it" refresher
- A chain of routines: issue → triage → build → adversarial review → staging deploy
- A dedicated low-privilege Salesforce user for agents

---

## Resources

- [Claude Code on the web: cloud environments](https://code.claude.com/docs/en/cloud-environments)
- [Routines (scheduled tasks)](https://code.claude.com/docs/en/routines)
- [Hooks: SessionStart](https://code.claude.com/docs/en/hooks)
- [`sf org login sfdx-url`](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference_org_commands_unified.htm)
- Session 9 (triggers, `gh api`, the first issue routine): [`../Session009/`](../Session009/)
