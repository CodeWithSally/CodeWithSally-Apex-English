# CLAUDE.md vs agents.md
*Decision interview — 2026-06-16*

---

**Q1: What are you actually trying to configure — behavior for *you* working in this repo, or behavior for autonomous agents running tasks in this repo?**
*Claude's take: `CLAUDE.md` is for priming interactive sessions with repo context and conventions for the human-in-the-loop workflow. `agents.md` is scoped to what autonomous sub-agents should know when spawned. If the goal is "I want Claude to know things about my project when I work with it," that's `CLAUDE.md`.*
**Answer:** Both — behavior for interactive sessions AND for autonomous agents running tasks.

---

**Q2: Is the content you want to put in these files the same, or different?**
*Claude's take: This is the crux. If the content is identical, you might be tempted to just use one file — but that's usually the wrong call. Interactive-session instructions often include things like "explain your reasoning" or "ask before deleting" that make no sense for a sub-agent. Agent instructions often include things like "output structured JSON" or "don't ask clarifying questions" that would be annoying in a conversation. If you find yourself writing the same thing twice, it's probably a shared *fact* (repo structure, conventions) that belongs in `CLAUDE.md` — which agents inherit anyway.*
**Answer:** Mostly the same content.

---

**Q3: What's in the "not same" part — what would differ between the two?**
*Claude's take: That delta is the whole justification for a separate agents.md. If it's small or nonexistent, you almost certainly just want CLAUDE.md.*
**Answer:** Not much would differ between the two.

---

**Q4: Do you already have content written somewhere, or are you starting fresh?**
*Claude's take: If you're starting fresh, just put everything in CLAUDE.md and be done with it. If you already have an agents.md with content, the question becomes whether it's worth migrating — usually yes, since a single source of truth is easier to maintain.*
**Answer:** Starting fresh — no existing content in either file.

---

## Summary

**Decision: Use `CLAUDE.md`. Don't create `agents.md`.**

Key findings from the interview:
- The goal covers both interactive sessions and agent tasks, but the content would be nearly identical for both
- There's no meaningful differentiation between what agents vs. the interactive session need to know
- Starting fresh removes any migration cost — this is a clean slate

**Why `CLAUDE.md` wins here:** Agents in Claude Code inherit `CLAUDE.md` automatically. A separate `agents.md` only pays for itself when agents need materially different instructions (e.g., "never ask questions", "output JSON only") that would be wrong or annoying in an interactive session. That case doesn't apply here.

**When to revisit:** If you later find yourself writing agent-specific instructions that would break your interactive sessions, *then* create `agents.md` for just that delta. Don't create it speculatively.

