---
name: grill-me-local
description: Interview the user thoroughly about a plan or design, one question at a time, and capture the whole session as a durable "cooked idea" artifact in a local cooked-ideas folder. Use when the user wants to stress-test a plan, pressure-test a design, get grilled, says "grill me", "interview me on this", "poke holes in my plan", or wants help thinking through a decision before building. Resolves each branch of the decision tree and leaves behind a saved record of every question, recommendation, and decision.
---

# Grill Me

Interview the user thoroughly (but not pedantically) about every meaningful aspect of their plan, walking down each branch of the decision tree and resolving dependencies between decisions one at a time. The goal is shared understanding plus a durable record you can hand to implementation later.

The output of a session is a **cooked idea** — a markdown artifact saved locally that captures the context, every question/recommendation/decision, and a distilled list of resolved decisions. You maintain it *as you go*, not at the end, so an interrupted session is never lost.

## Core behaviors

- **One question at a time.** Never dump multiple questions. Sequence them so each answer can inform the next.
- **Every question ships with your recommended answer.** Don't just ask — take a position. Recommend, then let the user confirm or redirect.
- **Explore instead of asking when you can.** If a question can be answered by reading available context, go find the answer rather than spending the user's attention on it.
- **Thorough but not pedantic.** Cover the branches that actually matter. Don't manufacture trivial questions to keep the interview going — convergence governs when you stop (see below), not a quota.

## Session flow

1. **Determine the topic.** Take it from the invocation args if given; otherwise ask one question: "What are we cooking up?"
2. **Orient.** Review any context the user has shared (files, descriptions, prior conversation) so your questions and recommendations are grounded, not generic.
3. **Restate your understanding** of the plan or problem in 2-3 sentences, and **create the artifact file** (see below) with that as the Context section.
4. **Grill**, one question at a time, recording each Q/A to the artifact immediately after the user answers.
5. **Converge and hand off** when the tree is exhausted or the user calls it.

## The artifact

**Location:**
`cooked-ideas/YYYY/YYYY-MM/YYYY-MM-DD-<topic-slug>.md`

This path is relative to the current working directory. Create the directory if it doesn't exist. If a file for the same topic and day already exists, append `-2`, `-3`, etc. Write to this path unless the user instructs otherwise for the session.

**Structure:**

```markdown
---
title: <topic>
date: YYYY-MM-DD
topic: <short topic phrase>
status: in-progress
tags: [cooked-idea]
---

# Cooked Idea: <topic>

## Context
<2-3 sentence restatement of the plan/problem being grilled>

## Decisions
<running, distilled answer key — the resolved decisions, kept current>

## Q&A Log
### Q1: <question>
**Recommendation:** <your recommended answer>
**Decision:** <the user's answer>
```

- **Decisions** is the distilled outcome you actually reuse later — keep it current as things firm up.
- **Q&A Log** is the append-only audit trail of every question.

**Write mechanics:** Use the Write tool to create the file at session start with frontmatter + empty Context/Decisions/Q&A Log sections. After each answer, use the Edit tool to append the new Q&A block to the log and update the Decisions section when a decision firms up. Write after *every* answer, before asking the next question. Always Read the file before editing it to get current content.

## Handling terse answers

The user accepts recommendations cheaply, so read their replies generously — but never turn a soft answer into a fabricated decision:

- Explicit answer → record their answer.
- "yes" / "sounds good" / "go with that" → record **your recommendation** as the decision.
- Vague or partial → record what's settled, and either fold the gap into a follow-up question or flag it as open in the Decisions section. Don't silently invent the rest.

## Converging and handing off

End when the decision tree is exhausted (no unresolved branches or dependencies) or the user says they're done. On ending:

1. Do a final clean pass on the **Decisions** section so it's complete and self-contained.
2. Flip frontmatter `status` to `resolved`.
3. Give a one-line summary plus the file path.
4. Offer a **numbered handoff menu** so the user can pick a next step with a single number. Default options:

   ```
   Cooked idea resolved → <file path>

   What next?
     1. Write an implementation plan
     2. Start building now
     3. Hand to the brainstorming skill for deeper design exploration
     4. Nothing — I'm done
   ```

   Keep it short, but add topic-specific options when the discussion surfaced an obvious next step. Offer, don't auto-execute.
