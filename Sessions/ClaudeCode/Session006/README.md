# Session 006 — Subagent Swarms: Build a Review Swarm from Scratch

**Series:** Claude with Sally (Code With Sally)
**Topic:** Going from one subagent to a *swarm* of them — build a `review-swarm` skill live from a single prompt, improve it one prompt at a time, then learn when *not* to reach for it and how to trust what it returns.

---

## What We Built

A **`review-swarm` skill** that reviews one or more files by fanning out three independent subagents at once — each with a narrow lens, each blind to the other two — then reconciles their findings into a single **GO / CAUTION / STOP** verdict.

The three lenses:

| Lens | Kind | Looks for |
|---|---|---|
| `review-swarm-security` | deterministic-leaning | injection, auth/authz gaps, secrets, unsafe deserialization, SSRF, path traversal |
| `review-swarm-test-quality` | reasoner | tests that assert nothing load-bearing, tautological assertions, over-mocking, missing edge cases |
| `review-swarm-design-correctness` | reasoner | logic bugs a static analyzer misses — off-by-one, wrong operators, bad control flow, edge cases |

Everything the demo accreted (v2–v5) is captured in one skill file, ready to run next time as a single command. The `DetailedNoteController` Apex class from earlier sessions is the artifact the swarm reviews.

---

## What We Covered

### 1. Why many beats one — and the two shapes

Ask one generalist to "review this" and you get a shallow-but-wide pass. Ask a security person, a testing person, and a design person and you get three genuinely different sets of findings. Run them all at once, each blind to the others — that's a **swarm**. It comes in two shapes:

- **Panel** — same input, many lenses → *resolves* to one verdict. Scale by adding viewpoints. *(This is what we built.)*
- **Sweep** — many inputs, same job → *aggregates* into a brief. Scale by adding searchers. *(e.g. a morning brief over Slack + email + cases.)*

Both are **blind** by design: reviewers never see each other's work, so they can't converge — you keep the diversity you came for. Straight from the docs: *"Subagents only report results back to the main agent and never talk to each other."*

Because the three run in parallel, total wall-clock is the *slowest* subagent — not the sum. A serial loop would burn ~3× the time for the same findings.

### 2. Build it one prompt at a time

We started from a blank file and improved the skill incrementally:

| Version | What it added |
|---|---|
| **v1** | Scaffold from one prompt — three subagents, each a different lens, report what each found. No JSON, no verdict yet. |
| **v2** | Split each lens into its own file under `.claude/agents/` so model, effort, and tools tune independently — and lock them **read-only** via `tools:` (a tool restriction, not a "please don't edit" instruction). |
| **v3** | Give every subagent a **shared JSON envelope** — verdict + findings (severity, issue, recommendation) — so three opinions become something you can sort, gate, and de-dupe. |
| **v4** | Pull the repeated setup into **one shared preamble**; keep only each agent's lens focus different — and never tell an agent it has colleagues (it hedges if it thinks it's on a panel). |
| **v5** | **Synthesize one verdict.** Gate to GO/CAUTION/STOP, sort by severity, and **re-read the source on any disagreement** before ruling — adjudication, not formatting. |

### 3. When *not* to swarm

The honest beat — and this very demo makes the case against itself:

- The artifact is small — one strong checklist pass holds the whole thing
- Cost or latency is the binding constraint — N agents is roughly N× the tokens
- The concerns interact — one agent holding the whole picture reasons about tradeoffs better
- Middle ground: one agent, sequential passes — ~1× cost, but loses independence

> The 40-line `DetailedNoteController` is itself a "skip the swarm" case — you'd checklist it in real life. We swarmed it so the machinery fits on screen. The pattern is the point, not the class.

### 4. How to trust it — structure is not accuracy

A schema makes results *collatable*, not *true*. Three reviewers who each hallucinate confidently just give you three tidy hallucinations. So a **separate agent grades the swarm's output** — maker-checker, the plain name for adversarial verification. Make the check objective where you can (*"fails WITH USER_MODE"* is checkable; *"risky"* is not); where you can't, validate the verifier itself.

### 5. Where the pattern goes next

The swarm is one rung. The same idea, turned up and turned sideways:

- **Pipeline** — agents as stages, each feeding the next (sequential, refines)
- **Debate** — let reviewers see each other and argue (trade independence for pressure-testing)
- **Nesting** — a reviewer fans out further; subagents spawn subagents (up to 4 levels)
- **Agent teams** — teammates share a task list and talk (experimental; many more tokens)
- **Dynamic workflows** — a script orchestrating agents at scale (16 concurrent / 1,000 per run)

---

## Directory Map

| Path | What it is |
|---|---|
| `session-6-slides.html` | The full presentation deck (32 slides). Open in a browser; arrow keys navigate. |
| `.claude/skills/review-swarm/SKILL.md` | The swarm orchestrator — resolves targets, fans out the three agents, reconciles to one verdict |
| `.claude/agents/review-swarm-*.md` | The three lens definitions (security, test-quality, design-correctness), each read-only |
| `.claude/statusline.js` | Custom 4-row status line: context/rate-limit gauges, token counts, model/effort/duration, and location |
| `.claude/settings.json` | Wires the status line command |
| `force-app/main/default/classes/` | `DetailedNoteController` + its test class — the Apex artifact the swarm reviews |
| `sfdx-project.json` / `.forceignore` | SFDX project scaffolding |

---

## Key Files

```
session-6-slides.html                                        Presentation deck

.claude/skills/review-swarm/SKILL.md                         The swarm skill (fan out → JSON → verdict)
.claude/agents/review-swarm-security.md                      Lens 1 — security holes (read-only)
.claude/agents/review-swarm-test-quality.md                  Lens 2 — do the tests assert anything? (read-only)
.claude/agents/review-swarm-design-correctness.md            Lens 3 — logic bugs a linter misses (read-only)
.claude/statusline.js                                        Custom 4-row status line
.claude/settings.json                                        Status-line wiring

force-app/main/default/classes/DetailedNoteController.cls    The artifact under review
force-app/main/default/classes/DetailedNoteControllerTest.cls
```

---

## Running the Swarm

```
# From this directory, in Claude Code:
/review-swarm force-app/main/default/classes/DetailedNoteController.cls
```

The skill spins up all three lenses in a single message (so they run in parallel), collects one JSON envelope per lens, re-reads the source on any disagreement, and returns one **GO / CAUTION / STOP** verdict with findings sorted by severity.

---

## Concepts Demonstrated

- **Panel vs. sweep** — two shapes of the same blind-parallel idea; pick by whether you have many lenses on one thing or many things each covered once
- **Blindness is structural** — subagents never see each other's work, so they can't converge; that's what preserves the diversity
- **Read-only by tool restriction** — `tools:` in agent frontmatter, not a prompt asking nicely — if an agent *can* touch data, assume it will
- **Shared envelope + preamble** — a common JSON shape and one preamble make N reviews commensurable, so synthesis can compare them
- **Synthesis is adjudication** — reconcile, don't collate; re-read the cited lines on any dispute before ruling
- **Structure is not accuracy** — verify the swarm's output with a separate grader; a schema makes hallucinations tidy, not true
- **Know when to skip it** — small artifact, cost/latency-bound, or interacting concerns → checklist it, or one agent with sequential passes

---

## Homework

- Build a 3-reviewer swarm for something you actually review — a PR, a piece of Apex, or a non-technical document (a proposal, a job posting, an SOP)
- Pick three lenses that genuinely disagree — run the *"would I lose findings nobody else would catch?"* test on each
- Run it. Note one thing a single reviewer would have missed — and be honest about whether the artifact was big enough to need the swarm
- **Bonus:** add a fourth reviewer and see if the synthesis changes the verdict
