---
name: theme-researcher-subagent
description: Use this skill whenever the user provides source material (text files, books, documents) and a theme, topic, or concept they want explored across that material. Like theme-researcher but delegates the close-reading and analysis phase to a subagent — useful when the source material is large, when multiple files should be analyzed in parallel, or when you want to keep the main context clean. Produces a structured research report synthesizing how the theme appears, develops, and functions throughout the texts. Trigger on phrases like "research this theme", "trace this idea", "what does this book say about X", "summarize the theme of X", "analyze X across these files", or any time someone has texts and wants thematic analysis rather than a general summary. Prefer this over theme-researcher when the material is long or spans multiple files.
---

# Theme Researcher (Subagent Edition)

You are conducting thematic research across source texts. Instead of doing the close reading yourself, you delegate the analysis to a subagent — one per file if there are multiple files — then synthesize their findings into a final report.

## Step 1: Confirm inputs

You need two things: (a) one or more file paths to read, and (b) a theme to research. If either is missing, ask before proceeding.

## Step 2: Spawn analysis subagent(s)

For each file, spawn a subagent with this prompt (fill in the placeholders):

---
**Subagent prompt template:**

You are doing close thematic analysis of a text file. Your job is to read the full file carefully and extract everything relevant to the given theme.

File to read: `<FILE_PATH>`
Theme to research: `<THEME>`

Instructions:
1. Read the file fully — use multiple Read calls for large files (>800 lines), tracking your position so you cover the entire text.
2. As you read, take running notes on passages, arguments, and moments that relate to the theme. Capture: location (line numbers or section), who is speaking, what the surrounding argument is, whether this is a central point or a passing mention.
3. The goal is not keyword matching. Read closely enough to understand *how* the theme functions — is it central? Ironic? Absent where you'd expect it?
4. After reading, identify the key through-lines:
   - What is the text's dominant relationship to the theme?
   - What is the most important tension or contradiction, if any?
   - What 2–3 specific passages best anchor the analysis?
5. Return a structured analysis with:
   - **Dominant stance**: one sentence on the text's overall relationship to the theme
   - **Key passages**: 2–3 specific moments (with location and brief context)
   - **Tensions or surprises**: anything that complicates the dominant reading
   - **Distinctive angle**: what makes this text's treatment of the theme notable

Return only the structured analysis — no preamble.

---

If there are multiple files, spawn all subagents in parallel so they run concurrently.

## Step 3: Synthesize

Once all subagents return, review their structured analyses and synthesize into a single paragraph (4–8 sentences) for the user.

The paragraph should give someone who hasn't read the material a real sense of how the theme functions across it. Cover: the overall stance or treatment of the theme, the main way it manifests or develops, any significant tension or surprise, and what makes this material's take distinctive. Ground the paragraph in at least one specific passage or moment from the text — paraphrase rather than quote at length.

If there are multiple files, weave them together — note similarities, contrasts, or progressions across texts.

Do not use headers, bullet points, or sections in the final paragraph.

## Quality standards

- Every claim should be traceable to specific passages from the subagent analyses
- Synthesis should explain *how* the theme functions, not just list where it appears
- Avoid plot summary; focus on thematic analysis
- The paragraph should stand alone — someone unfamiliar with the text should gain real insight from it
