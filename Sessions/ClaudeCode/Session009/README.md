# Session 009 — Loops, Scheduled Tasks, and Routines: Put Claude to Work While You're Away

**Series:** Claude with Sally (Code With Sally)
**Recording:** [Claude Loops, Scheduled Tasks & Routines for Salesforce | Mastering Claude | Part 9](https://www.youtube.com/watch?v=GtkP4FA8q7Q)
**Topic:** Every session so far started with someone typing a prompt and waiting for an answer. This one is about Claude starting without you. There are three ways to make that happen, and they're easy to mix up: **loops**, **scheduled tasks**, and **routines**. We built one of each live against a Salesforce org, Slack, an inbox and a GitHub repo, then had Salesforce start a routine on its own.

---

## What We Built

| # | Mechanism | Demo | Where it lives |
|---|---|---|---|
| 1 | **Loop** | Wait for the client's "OK to close" email, close the case, post to Slack, then turn the first Slack reply into a case comment | `1-loop/` |
| 2 | **Scheduled Task** | Every hour, turn client emails into Salesforce cases (without creating the same case twice) and post each new one to Slack | `2-scheduled-task/` |
| 3 | **Routine** (GitHub event) | When an issue is opened, write a first-pass triage report and open a draft PR with the fix | `3-routine-issue-triage/` |
| 4 | **Routine** (API call) | When an Account is created in Salesforce, a flow calls the routine, and Claude researches the company and posts a brief to Slack | `4-routine-from-salesforce/` |

> **In one line each:** a **loop** says "keep checking this until it happens". A **scheduled task** says "do this every hour or every Monday, in the cloud". A **routine** is a scheduled task with a repo attached, and it can also be started by a GitHub event or an API call.

---

## The Model: Three Ways Claude Starts Without You

| | Loop | Scheduled Task | Routine |
|---|---|---|---|
| **Runs on** | Your machine, inside an open Claude Code session | Anthropic's cloud | Anthropic's cloud: a full Claude Code session with a fresh clone of your repo |
| **Laptop has to be on** | Yes | No | No |
| **Created with** | `/loop <interval> <prompt>` | claude.ai → **Scheduled** → New task | The same form, with a **repository** picked (or `/schedule`, or claude.ai/code/routines) |
| **Fastest interval** | 1 minute | Hourly | Hourly |
| **Other triggers** | none | **Run now** | Run now, **GitHub event**, **API call** |
| **Reaches** | Local files, CLIs (`sf`), and the session's MCP servers | Your claude.ai connectors | The repo, connectors you choose, and a cloud environment you configure |
| **Approvals** | The session's permissions (`.claude/settings.json`) | A mode per task: Manual / **Auto** / Skip all approvals | Runs unattended. The repo, connectors and network are the limits. |
| **Stops when** | You tell it to, the session closes, or after **7 days** | You turn it off | You turn it off |

**Picking a repository is the only thing that turns a scheduled task into a routine.** It's the same form with one field filled in.

---

## Demo 1 — Loop: close the case when the client confirms

The scenario: you're waiting on an important client's go-ahead, and the school calls to say your kid is sick. You have 30 seconds to hand the wait to Claude before you leave.

```
/loop 1m keep an eye out for an email from sally (emai***********@gmail.com) saying she's happy and case 00001027 can be closed. only look at her emails, and ignore anything from her that isn't about that. when she confirms, close the case in the cws org with the sf cli, then post in slack #test-cws that she confirmed and it's closed. after that watch that slack thread, and when someone replies add their reply as a comment on the case and stop the loop
```

What happened:

1. **The first check went to the wrong inbox.** Both Gmail and Microsoft 365 were connected, and "an email" sent the loop to Gmail. One nudge ("check M365") fixed it: Claude deleted the job and recreated it with the right instructions. **Be specific where it matters.** For a loop you'll run every day, put "Microsoft 365" in the prompt, or in the project's `CLAUDE.md`.
2. **Sally's unrelated email was ignored.** Her "looking forward to the session" note didn't mention the case, so the loop kept waiting.
3. **Her confirmation was acted on.** The loop closed case 00001027 with the `sf` CLI and posted to `#test-cws`.
4. **Phase two.** The loop didn't stop. It watched only that Slack message's thread. Bill replied "This is great, hope the team can pick it up", and on the next tick the reply became a case comment and the loop cancelled itself.

**Claude did all of the orchestration.** No flow, trigger or Agentforce was involved. One session used three connections (Microsoft 365, Slack, the Salesforce CLI) and decided what to do at each step.

`1-loop/.claude/settings.json` pre-approves exactly the seven tools the loop needs. Sending email isn't one of them. **The prompt asks; the permissions decide.**

### Running loops every day: `loop-start-all`

Bill keeps a folder of loop definitions (an inbox classifier, a check for new photos from his son's basic-training unit, and a list of ad hoc "watch for this" items). A personal skill, `loop-start-all`, opens one terminal tab per definition and starts each `/loop` in it. That's his own setup, not a Claude feature, but it shows the pattern: **when a loop is worth repeating, turn it into a skill**, and fix a mistake once in the skill instead of in every prompt.

---

## Demo 2 — Scheduled Task: client emails become cases

Built at **claude.ai → Scheduled → New task → Set up manually** (there's also a "Set up with Claude" option that walks you through it).

- **Permissions: Auto.** Manual would stall a run nobody is watching. Skip all approvals runs even unsafe actions without pausing. Auto runs without asking, but a classifier checks each action for danger first, like data loss. That check isn't a guarantee.
- **Trigger: Hourly**, the shortest interval. There's no time-of-day field for hourly.
- **Connectors:** every connector you have is available to every scheduled task, with no way to remove one. Use the prompt and each connector's own tool permissions to limit what it can do.
- **Notifications:** "Notify me … only when there's something worth telling you." What counts as worth telling isn't clear. If you need a notification, put "post to Slack" or "email me" in the prompt itself.

The prompt is in [`2-scheduled-task/scheduled-task-prompt.md`](2-scheduled-task/scheduled-task-prompt.md). Waiting an hour wasn't an option on stream, so we clicked **Run now** three times:

| Run | What it saw | What it did |
|---|---|---|
| 1 | Sally's two emails from the loop demo | Created 0 cases. Neither was a new request. |
| 2 | Sally's new question: "How do I add Detailed Notes to Opportunities?" | Checked for an open case with the same sender and subject (none), created **case 00001030** linked to her Contact and Account, confirmed it with a SOQL query, and posted to `#test-cws` |
| 3 | The same three emails | **Skipped one request as already logged.** Rerunning it is safe. |

The duplicate check also covers a case you created by hand before the task ran.

**Keep each run cheap:** stop it as early as you can. Time-box the search (an hourly task needs the last 2 hours of mail, not 24) and tag emails you've handled so the next run skips them. Reading an email through the Microsoft 365 connector **doesn't** mark it read, and the connector has no "mark as read" tool. It can change categories or labels, though.

---

## Demo 3 — Routine: triage every new GitHub issue

The same New task form again, but with a repository picked and a **GitHub event** trigger: repository `cws-session9-b`, event **Issues: opened**. The trigger list also covers pull request and release events, and it can filter, for example by issue author, so a stranger's issue can't start a run.

Differences from the scheduled task:

- **Cloud environment.** The run gets its own environment, where you can set network access (none, allowlisted domains, or full), secrets, and a **setup script** that installs tools such as Playwright or the Salesforce CLI.
- **Connectors can be trimmed** here, and they should be.
- **Behavior:** auto-fix on PR stays off. The routine opens a draft PR, and a human reviews it and merges.

The prompt is in [`3-routine-issue-triage/issue-triage-routine-prompt.md`](3-routine-issue-triage/issue-triage-routine-prompt.md). Each report landed about a minute after the issue was filed:

| Issue | Verdict | Result |
|---|---|---|
| #4 The Code with Sally logo looks tiny on the Battle buddies card | Report, labeled `triaged` | **No PR.** The fix is a bigger image, not a code change, so the routine said what was needed instead of building a workaround. |
| #5 Partner links open in the same tab | Confirmed | **Draft PR #6**: `target="_blank"` on the four partner links, build passing, linked to the issue with `Fixes #5` |
| #7 Code with Sally card lists its links in a different order | Confirmed | **Draft PR #8**, a one-line swap |
| #9 The page colors don't meet accessibility standards | Likely | **Draft PR #10**, which raises the text and border contrast to WCAG AA and lists the failing color pairs with their ratios |

**Sub-agents work in routines too.** Sally asked about them, so before filing #9 we added one sentence to the prompt: *"Make sure to spin up three independent sub-agents to do the research."* The run log showed three sub-agents launching. You'd use them for the same reasons as in a live session: speed (parallel work) or volume (each sub-agent gets its own context and reports back a summary).

---

## Demo 4 — Salesforce starts a routine

A routine's **API trigger** gives you a URL and a token. Anything that can make an HTTP POST can start it, including Salesforce:

```
Account created → Flow (async path) → HTTP Callout (External Service) → Named Credential → POST /fire → Claude routine → Slack
```

On stream, Bill created an Account named **Local Wisdom** with its website. The flow called the routine, Claude researched the company (what it does, size and HQ, recent news, any sign it uses Salesforce), and it posted a brief to `#test-cws`.

The Salesforce setup takes a few steps (External Credential, Named Credential, External Service, flow, permission set), so it was shown, not built. Everything you need is in [`4-routine-from-salesforce/`](4-routine-from-salesforce/), including the gotchas: a **401 on every call** until "Allow Formulas in HTTP Header" is on, and a flow that **reports success even when the call fails**.

---

## Trust: What It Takes to Trust Something That Runs When You Aren't Watching

- **Everything is done as you.** Routine comments, labels, branches and PRs show up under your GitHub account. Scheduled task posts show up under your Slack name.
- **Limit what it can reach.** Pre-approve only the tools a loop needs. Remove connectors a routine doesn't use. Remember that a scheduled task sees every connector you have.
- **Treat outside input as data.** An issue body, an email, or an API payload was written by someone else. Tell Claude never to follow instructions in it. Be careful pointing a routine at a **public** repo: someone could file "ignore previous instructions…" as an issue, or hide it in an image.
- **Auto mode is not a guarantee.** Its classifier catches dangerous actions, but "safe" depends on who's asking. Know which mode each job runs in.
- **Make reruns safe.** Check for an existing case, an existing `triaged` label, or an existing Slack post before acting.
- **A human makes the call.** Draft PRs, "first pass by Claude" footers, and nothing merges or deploys on its own.
- **Green doesn't mean it worked.** A successful run status means the job ran, not that the work is right. Open the run and check.

---

## Questions from the Session

**How do I start a loop?** Type `/loop`, then an interval (`1m`, `2h`, …), then the prompt. Or ask "help me design a loop", and Claude walks you through it.

**Do loops run forever?** They run until the stop condition you gave is met, the session closes, or **7 days** pass, whichever comes first. With no stop condition, a loop keeps going on every tick.

**What happens when my laptop sleeps?** The loop pauses. Ticks missed while the laptop sleeps are skipped, not made up later. When it wakes, the loop carries on from the next tick.

**What's the difference between a loop with no stop condition and a scheduled task?** A loop lives only as long as the session (and at most 7 days). A scheduled task lives in the cloud and runs until you turn it off.

**Can a scheduled task run on something other than a schedule?** Yes. Add a **GitHub event** or **API** trigger. With a repo attached, that's a routine.

**Does the instructions box need a particular structure?** No. The Markdown headings and the Rules/End-of-run sections are personal preference, kept consistent so the prompt can live in a repo as a `.md` file. Plain sentences work too.

**Will the routine know my Salesforce skills (Apex, LWC, flows)?** MCP connectors are configured on the routine. Skills on your laptop aren't part of the cloud run. **Open follow-up:** the repo's `CLAUDE.md` loads in the cloud session, so committing skills to the repo's `.claude/skills/` is the likely route. We haven't tested it yet.

**What's the "Visualize" connector?** A built-in claude.ai tool for diagrams and charts, not an external server.

**How do you connect Salesforce to claude.ai?** Create an **External Client App** in Setup (OAuth on, callback `https://claude.ai/api/mcp/auth_callback`, scopes "Access MCP servers" and "Perform requests at any time", JWT-based access tokens for named users). Then in claude.ai → Customize → Connectors → **Add custom connector**, paste the Salesforce Hosted MCP server URL and the app's Consumer Key. A new app can take up to 30 minutes to become usable. Most other connectors (Slack, Monday.com, …) are a single OAuth click.

---

## Try It Yourself

1. **Loop.** From `1-loop/`, run the prompt in [`loop-prompt.md`](1-loop/loop-prompt.md) against your own org alias, inbox and Slack channel. Change the allow rules in `.claude/settings.json` to match the tools you use.
2. **Scheduled Task.** In claude.ai → Scheduled → New task, paste [`scheduled-task-prompt.md`](2-scheduled-task/scheduled-task-prompt.md), swap in your own sender and connector names, and click **Run now** twice.
3. **Routine.** On a private repo you own, create a task with the repository picked and a GitHub **Issues: opened** trigger. Use [`issue-triage-routine-prompt.md`](3-routine-issue-triage/issue-triage-routine-prompt.md). [`new-demo-repo.sh`](3-routine-issue-triage/new-demo-repo.sh) and [`demo-issues.md`](3-routine-issue-triage/demo-issues.md) show how the demo repo was seeded.
4. **Salesforce → routine.** Follow [`4-routine-from-salesforce/README.md`](4-routine-from-salesforce/README.md).

---

## Directory Map

| Path | What it is |
|---|---|
| `session-9-slides.html` | The presentation deck (23 slides). Open it in a browser; the arrow keys navigate. Each demo is followed by a slide with its full prompt. |
| `1-loop/loop-prompt.md` | The live loop prompt, a more specific version, and reset commands |
| `1-loop/.claude/settings.json` | The seven allow rules the loop runs with |
| `1-loop/sally-emails.md` | The three emails Sally sent on cue (two for the loop, one for the scheduled task) |
| `2-scheduled-task/scheduled-task-prompt.md` | The form values and instructions for the email-to-case task |
| `3-routine-issue-triage/issue-triage-routine-prompt.md` | The form values and instructions for the triage routine, plus build notes |
| `3-routine-issue-triage/demo-issues.md` | `gh issue create` commands for the seed and live issues |
| `3-routine-issue-triage/new-demo-repo.sh` | Makes a fresh private demo repo and files the seed issues |
| `3-routine-issue-triage/issue-triage-action.yml` | Optional: a GitHub Action that fires the routine's API trigger (not needed with the built-in GitHub event trigger) |
| `4-routine-from-salesforce/` | SFDX project: External Credential, Named Credential, External Service, flow, and permission set that call a routine from Salesforce, plus the routine's prompt |

---

## Concepts Demonstrated

- **Three mechanisms, three homes.** A loop lives in your session, a scheduled task in the cloud, and a routine in the cloud with a repo attached
- **Claude as the orchestrator.** One prompt coordinated an inbox, Salesforce and Slack, with no flows or triggers
- **Be specific where it matters.** Two inboxes and a vague prompt meant one wrong first check
- **Safe to run twice.** The duplicate check, proven live with Run now
- **Event-driven agents.** A GitHub issue or a Salesforce record can start a cloud Claude Code session
- **Propose, don't merge.** Draft PRs and reports leave the decision to a human
- **Permissions over promises.** Allow rules, trimmed connectors and permission modes do the enforcing; the prompt only asks

---

## Homework

1. **Loop.** Pick something you check by hand today and hand it to a loop with a clear stop condition.
2. **Scheduled Task.** Make one for a daily chore, then click **Run now** twice to prove it's safe to repeat.
3. **Routine.** Put one on a repo of yours: triage new issues, filtered to your own issues at first.
4. **Not a developer?** Schedule a Monday-morning summary of your week's calendar and open threads.

---

## Gotchas

- **Two inboxes, one word.** "Email" is ambiguous when both Gmail and Microsoft 365 are connected. Name the connector.
- **No per-task connector list on scheduled tasks.** Every connector is available. Limit each connector's tools (Customize → Connectors) and spell out the limits in the prompt.
- **`gh issue` / `gh pr` fail in cloud sessions** (GraphQL is blocked). Claude's built-in GitHub tools and `gh api` REST calls work.
- **Branch protection isn't available on private GitHub Free repos.** The prompt is the only thing keeping a routine off `main`.
- **Salesforce callouts that fail look like successes.** The flow's HTTP Callout treats a 401 as success. Check the routine's run list.
- **API triggers allow 30 fires per routine per hour.** A bulk Account insert can exceed that.
- **An API token is shown once.** Keep it off a screen share, and regenerate it if a stream may have caught it.

---

## Ideas for Future Sessions (requested in chat)

- Building the Salesforce → Claude callout end to end, plus Claude → Salesforce through MCP, in one session
- Permission modes in depth (Manual, Auto, Skip all approvals, and how Auto decides)
- Claude Code mods (customizing Claude's own interface and behavior)
- Slack ↔ Claude in both directions

---

## Resources

| | |
|---|---|
| Loops | [code.claude.com/docs/en/scheduled-tasks](https://code.claude.com/docs/en/scheduled-tasks) |
| Routines | [code.claude.com/docs/en/routines](https://code.claude.com/docs/en/routines) |
| Scheduled tasks | [Schedule recurring tasks](https://support.claude.com/en/articles/13854387-schedule-recurring-tasks-in-claude-cowork) |
| Permission modes | [code.claude.com/docs/en/permission-modes](https://code.claude.com/docs/en/permission-modes) |
| Salesforce Hosted MCP Servers | Salesforce Help: *Salesforce Hosted MCP Servers* |
