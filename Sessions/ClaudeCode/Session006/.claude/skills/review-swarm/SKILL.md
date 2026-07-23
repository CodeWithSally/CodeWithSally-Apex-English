---
name: review-swarm
description: Review one or more files by running three independent parallel subagents, each with a narrow lens — security holes, test-quality (do the tests actually assert anything?), and design-correctness (logic bugs a static analyzer can't catch). Use whenever the user asks for a "review swarm," a multi-angle or parallel code review, or invokes /review-swarm with file paths. Also reach for it when the user wants a fast, blind, multi-perspective second opinion on a diff or file beyond what a single review pass would catch.
---

# Review Swarm

Run three independent reviewers over the same file(s) at once, each blind to
the other two. Isolation is the point: a reviewer told to hunt for security
holes and test weaknesses in the same pass tends to under-focus on both. Three
narrow, separately-briefed passes surface more than one broad pass would, and
because they run in parallel the wall-clock cost is one review, not three.

## When invoked

The user will name one or more files (or a directory/diff) via `/review-swarm
<path...>` or plain language ("run a review swarm on auth.py"). If no target
is given, ask which file(s) to review rather than guessing.

## Steps

1. **Resolve the target.** Confirm the file(s) exist (Read or Glob as
   needed). Note the absolute path(s) — each subagent needs them, since
   subagents don't inherit your conversation context.

2. **Launch all three subagents in a single message** using the Agent tool,
   one tool call per lens, so they run concurrently. This is the part that
   must not be serialized — sending them one at a time defeats the purpose.
   Each lens is its own agent definition under `.claude/agents/`, so its
   focus, model, and tools can be tuned independently without touching this
   skill:

   - `subagent_type: review-swarm-security`
   - `subagent_type: review-swarm-test-quality`
   - `subagent_type: review-swarm-design-correctness`

   All three are read-only (`tools: Read, Glob, Grep` in their frontmatter —
   no Edit/Write/Bash), so none of them can modify the files they're
   reviewing. Each agent definition already carries its own lens brief (what
   to look for) in its system prompt — it does not know the output format.
   The output format is a property of this skill, not of any one lens, so it
   lives here and gets appended to every Agent call's prompt verbatim: the
   target file path(s) to Read, plus the block below.

   **Append this to every subagent's prompt, unchanged across all three:**

   > Report your findings as JSON only — no prose before or after, no
   > markdown code fence. Match this shape exactly:
   >
   > ```json
   > {
   >   "verdict": "pass" | "concerns" | "fail",
   >   "findings": [
   >     {
   >       "severity": "low" | "medium" | "high" | "critical",
   >       "issue": "what's wrong, including file:line",
   >       "recommendation": "what to do about it"
   >     }
   >   ]
   > }
   > ```
   >
   > `verdict` is your overall call for this lens: "pass" if you found
   > nothing worth flagging, "concerns" if you found low/medium issues,
   > "fail" if you found anything high or critical. `findings` is `[]` when
   > `verdict` is "pass". Do not propose fixes beyond a one-line
   > recommendation — this is a review, not a patch.

   Do **not** paste the other two lenses' briefs into any agent's prompt,
   and do not let them share a scratchpad or see each other's output —
   that's what keeps the three passes independent instead of converging on
   the same handful of obvious issues.

3. **Wait for all three to return**, then parse each one's JSON. If a
   subagent's output doesn't parse as valid JSON matching the shape above,
   treat that as its own finding ("this reviewer's output was malformed")
   rather than silently dropping it or guessing at its intent, and treat
   that lens as a "fail" for reconciliation purposes below — a malformed
   response is not evidence of a clean bill of health.

4. **Reconcile the three verdicts into one overall call: GO, CAUTION, or
   STOP.** Map each lens verdict to a tier — `pass` → GO, `concerns` →
   CAUTION, `fail` → STOP.

   - If all three lenses land on the same tier, that tier is the overall
     verdict — no further work needed.
   - If they disagree, don't just take the worst (or the majority) and
     move on. Disagreement between three independent reviewers of the same
     code is itself a signal that something's ambiguous, so **re-read the
     source file(s) yourself** before ruling — specifically the lines cited
     in the findings behind the more severe verdict(s). Check whether what
     you see in the code actually supports the finding. Then rule based on
     what you found, not on which subagent shouted loudest:
     - If your read confirms the finding, the overall verdict reflects it
       (STOP if the confirmed issue is high/critical, CAUTION otherwise).
     - If your read rules the finding out (e.g. the flagged input can't
       actually reach that code path), say so explicitly in the report and
       downgrade the overall verdict accordingly — but still show the
       original finding and why you dismissed it, don't just delete it.
     - If you genuinely can't tell from reading the source, default to the
       more severe verdict — a false alarm costs a re-read; a missed issue
       costs more.

5. **Present the report**, in this order:
   - **Overall verdict** (GO / CAUTION / STOP) with a one-line reason. If
     resolving a disagreement required re-reading the source, say what you
     checked and what you concluded, right here.
   - **Findings, combined across all three lenses and sorted by severity**
     (critical → high → medium → low; within a tier, order doesn't matter).
     Each finding shows its severity, issue, recommendation, and which lens
     raised it — combine into one sorted list rather than three separate
     ones, since severity is what the user needs to triage on, not which
     reviewer happened to notice it first. Still make the source lens
     visible per finding so nothing is anonymized.
   - Skip lenses that returned `findings: []` entirely rather than
     including a "no issues" line for each — the findings list already
     shows everything that needs attention.
