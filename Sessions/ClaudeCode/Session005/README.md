# Claude with Sally — Part 5: Skills and Subagents

**Bill Kuehler · Resource Hero · 2026**

---

## Part 4 Recap

**What We Covered Last Time**

- Controlled what Claude can do with hooks: a `settings.json` deny list to block git commits and stray `sf deploy`s (deny always beats allow)
- Hookify for the nuanced rules — "block `sf deploy` unless everything's committed" — the kind of guardrail a single command can't express
- UI testing with the Playwright CLI: drove a real browser, navigated the org, and tested the live component end to end

---

## Before We Start · Saw This Today

**Hooks, Taken Too Far**

Someone wired a Claude Code hook to a webcam squat counter. Your prompt will not send until you do 6 squats on camera. The hook holds your input hostage until the reps hit 6.

> **Callback to Part 4** — Same mechanism we used last time: a hook intercepts an action, runs a check, decides whether to let it through. Then it blocked a stray `sf deploy`. Here it blocks *you*.

`github.com/BotchetDig/workout-gate`

*"Claude, mid-squat: 'Slower than my inference, somehow.'"*

---

## Part 5 Agenda

**What We'll Cover**

- Skill mechanism refresher — anatomy of a skill file and how Claude reads it
- Build grill-me — an interactive skill that thinks with you, not just for you
- Finding and adapting skills others have already built
- Use grill-me to design a new skill
- Managing context with subagents

---

## 01 · Skill Mechanism Refresher

*What a skill file actually is — and how Claude reads it*

---

### Anatomy of a Skill File

```
---
name: grill-me
description: Interview me about
  any problem -- one
  question at a time...
---

## Steps

1. Ask one question
2. Recommend an answer
3. Document the decision
```

| Section | What it does |
|---|---|
| **Frontmatter** | Name, description, and trigger hints. Claude reads the description to decide when to use the skill. |
| **Body** | Plain markdown — steps, checklists, tool use, output format. Claude follows it like a runbook. |
| **Invocation** | `/skill-name` — Claude reads the file and follows it. That is the whole mechanism. |

---

### Beyond `name` & `description`

All optional — reach for them when a skill needs to do more than just exist.

```
---
name: deploy
description: Ship to prod
when_to_use: after tests pass
disable-model-invocation: true
allowed-tools: Bash(git *) Read
context: fork
agent: Explore
model: opus
---
```

**Discovery & triggering**
- `when_to_use` — extra trigger phrases for auto-load
- `paths` — globs — only load for matching files
- `argument-hint` — autocomplete hint, e.g. `[issue]`
- `arguments` — name positional args for `$name`

**Who can run it & with what**
- `disable-model-invocation` — only you — `/deploy`
- `user-invocable: false` — only Claude — bg knowledge
- `allowed-tools` — pre-approve tools, no prompt
- `disallowed-tools` — remove tools while active

**Where & how it runs**
- `context: fork` — run in an isolated subagent
- `agent` — which subagent — Explore, Plan, custom
- `model` / `effort` — override model & reasoning depth
- `hooks` / `shell` — lifecycle hooks; bash or powershell

Full reference: `code.claude.com/docs/en/skills#control-who-invokes-a-skill`

---

### Where Skills Live

```
# Project-level (this project only)
.claude/
  skills/
    grill-me/
      SKILL.md
    theme-researcher/
      SKILL.md

# User-level (every project)
~/.claude/
  skills/
    session-wrapup/
      SKILL.md
```

- Project-level skills live in `.claude/skills/` — scoped to that repo only
- User-level skills live in `~/.claude/skills/` — available in every project
- Each skill is a folder with a `SKILL.md` inside
- Claude Code discovers them automatically — no registration needed

---

### Turn Skills On and Off

```
# Manage every skill from one menu
/skills

  grill-me            [on]
  theme-researcher    [on]
  session-wrapup      [off]
  data-sync-sf        [on]

# space toggles · enter saves
```

**How** — Run `/skills`, arrow to any skill, toggle it. Project-level and user-level skills both show up in the list.

**Why disable one** — Every enabled skill's description rides along in context. Switch off the ones you are not using to keep context lean — and to stop Claude auto-invoking a skill you do not want right now.

---

## 02 · Build the Grill-Me Skill

*The most important skill you can write — and it is not about code*

---

### What Grill-Me Actually Does

> **The prompt that built it:**
> `> Use skill-creator to build a skill called grill-me — interview me about any decision one question at a time, recommend an answer each time, wait for my reply, and log every decision to a note as we go.`

- Asks you one question at a time about any problem or decision
- Recommends an answer with each question — you react, you do not originate
- Documents every decision as it is made — produces a cooked-idea artifact
- Works for features, APIs, business decisions, process design — anything

*"Most skills tell Claude to do something for you. Grill-me tells Claude to think with you."*

> **Callback to Session 3** — You used the Superpowers brainstorming plugin in Session 3 — grill-me takes that idea much further, building documentation as you go.

---

### DEMO: Build Grill-Me

Write the grill-me skill from scratch with Claude. Start with blank frontmatter — build the behavior live — run it on a real decision to see it work.

---

## 03 · Finding Skills Online

*You do not have to build from scratch every time*

---

### Where to Look

- **Matt Pocock's GitHub** — `github.com/mattpocock/skills` — real skills from a working developer, ready to read and adapt
- **Nate Herk on YouTube** — `@nateherk` — video walkthroughs of skill patterns in action
- **Superpowers skill library** — curated, well-documented, ready to adapt

> **The Adaptation Pattern** — Read it. Strip what does not fit. Add what does. Keep the shape, swap the content.

> **The Point** — Find one close to what you need — adapting is faster than authoring from zero.

> **Read before you run** — A skill is instructions Claude will follow — a found one can hide prompt injection: buried directions to leak data, run destructive commands, or call tools you never intended. Review every skill you download before enabling it, the same way you would read code before running it.

---

### Drop It In — or Make It Yours

> **The prompt that adapts it:**
> `> I want to leverage the skill Nate Herk built, here: github.com/nateherk/skills. Run /grill-me on how we could tweak it for my use case and style, then use /skill-creator:skill-creator to build my version.`

- Dropping a found skill in as-is works — it will run
- But it encodes someone else's workflow and voice, not yours
- `/grill-me` interviews you on what to change for your use
- `/skill-creator:skill-creator` turns those decisions into your own version

> **Why bother tweaking** — A skill is only as good as how well it fits your habits. The adaptation is where a generic skill becomes yours.

> **Full circle** — The grill-me skill we just built is now the tool we use to adapt every other skill we find.

---

## 04 · The Research Skill

*Design it with grill-me, build v1, then watch the context window*

---

### Design It with Grill-Me

> **Eating our own cooking:**
> `> /grill-me — I want a skill that traces one theme across several books and writes a single synthesis. Help me spec it.`

**What it surfaced:**
- Inputs — file paths to read + the theme to trace
- Output — one synthesis paragraph, no headers or bullets
- Depth — skim for keywords, or read for how the theme functions?
- One book or many — does more than one change the approach?

> **The Moment** — We used the skill we just built to design the next one — every decision documented as we went.

> **The Seed of v2** — That last question — "what if there are many books?" — is exactly what pushes us to subagents next.

---

### What v1 Does

- Three books on disk: *A Christmas Carol*, *Jekyll & Hyde*, *The Metamorphosis*
- One theme to trace across all of them: **transformation**
- v1 reads each book in full, end to end, then writes a single synthesis paragraph
- No subagents, no MCP — just the skill reading files in your main conversation

> **How v1 Works** — Every book gets read inline in the main conversation — the full text lands directly in context.

> **Why It Matters** — Whole books are big — this is the most visceral way to watch context fill up in real time.

---

### DEMO: Build and Run v1

Build and run the research skill — inline in the main conversation. Watch the context window — scroll through what it consumed.

---

### The Problem with v1

- The research ran — all three books, every chapter, every line — landed in context
- Every token of every book lives in the conversation now
- That context rides along for every message that follows
- The skill worked. The context cost is the problem.

> **The Lesson** — Inline research pollutes context for everything that follows. There is a better way.

*"Every book you read inline stays in context forever — until you start a new conversation."*

---

## 05 · V2: Add Subagents

*Same research — much lighter context footprint*

---

### What a Subagent Is

- A separate Claude instance spun up to do one job and return a summary
- It has its own context — all the heavy research happens there, not in yours
- When it finishes, it hands back a summary — just the findings, not the full working detail
- Your main context only sees the summary — not the work that produced it

> **The Key Principle** — Subagents do the work in their own context and hand back a summary — the full detail never enters your main conversation.

---

### v1 vs v2 — What Lives in Context

**v1 — Inline Research**

```
[ A Christmas Carol ]  [ Jekyll & Hyde ]  [ The Metamorphosis ]
        ↓                     ↓                     ↓
┌─────────────────────────────────────────────────────────────┐
│  MAIN CONTEXT                                               │
│  All three books land here in full                          │
│  conversation + every book read inline                      │
│  + your messages + Claude responses                         │
│                                                             │
│  Tokens: A + X + Y + Z                                      │
│  paid on every subsequent message                           │
└─────────────────────────────────────────────────────────────┘
```

**v2 — Subagents**

```
┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐
│  subagent    │  │  subagent    │  │  subagent            │
│  X (full)    │  │  Y (full)    │  │  Z (full)            │
│  A Christmas │  │  Jekyll &    │  │  The Metamorphosis   │
│  Carol       │  │  Hyde        │  │                      │
└──────┬───────┘  └──────┬───────┘  └──────────┬───────────┘
       │                 │                       │
  [Xsummary]        [Ysummary]             [Zsummary]
       │                 │                       │
       └─────────────────┴───────────────────────┘
                         ↓
              ┌──────────────────────────┐
              │  MAIN CONTEXT            │
              │  A + Xsummary +          │
              │  Ysummary + Zsummary     │
              │  summaries only —        │
              │  detail stayed in        │
              │  subagents               │
              └──────────────────────────┘
```

---

### DEMO: Build and Run v2

Rebuild the skill with one subagent per book. Run v2 — then compare context size side by side with v1.

---

### What v2 Showed Us

- Same research — all three books — each read in full and summarized
- Each book ran in its own subagent context — heavy lifting happened there
- Main conversation received summaries only — a fraction of the token cost
- Everything that follows is lighter — research is done, not dragging along

> **The Lesson** — Subagents let you go wide without paying the context cost — they compress the work before it reaches you.

> **When to Use Subagents** — Any time a task pulls from multiple sources — research, multi-file analysis, cross-system lookups.

---

## Part 5 Wrap-Up

**What We Built**

| | |
|---|---|
| **Grill-Me Skill** | A skill that interviews you — one question at a time, recommends answers, documents decisions as you go |
| **theme-researcher v1** | Reads all three books inline, traces one theme, writes a synthesis — designed by running grill-me first |
| **theme-researcher v2** | Same research, one subagent per book — summaries only reach main context, tokens stay manageable |

---

## Homework

**Your Turn**

- Adapt grill-me to a decision you are actually facing right now — not a tech decision, anything: a process change at work, a big purchase, what to build next on a side project
- Run it. See what it surfaces that you had not thought of.
- Find one skill online — on GitHub or Superpowers — and adapt it to your own workflow. Strip what does not fit. Add what does.
- **Bonus:** take a skill you already use that pulls from multiple sources and split it across subagents

---

## Part 6 Preview

- Details to follow — keep an eye out before next session
- Keep exploring skills — the more you use them, the clearer the patterns get
- Questions, observations, and skill ideas welcome in the meantime

*"Skills are how you make Claude Code yours. The tool ships generic. You make it specific."*
