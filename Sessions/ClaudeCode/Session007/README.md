# Session 007 — Quickly Build Salesforce Support Videos

**Series:** Claude with Sally (Code With Sally)
**Topic:** Empty terminal to finished video — install Playwright CLI and HyperFrames from nothing, learn the tool on a trivial animation, then capture a real Salesforce org and build a narrated support walkthrough. Almost all of it live in the terminal.

---

## What We Built

Two HyperFrames video projects, both created from an empty Salesforce project folder, both driven entirely by prompts:

| Project | What it is |
|---|---|
| `videos/simple-circle/` | The "Hello World" — a red circle crossing a sky-blue background, then holding, then coming back. Grew captions, then a per-line voiceover, then a Resource Hero brand palette, then a rendered MP4. |
| `videos/create-account-contact/` | The real thing — a ~50 second, 12-step narrated walkthrough of creating a Contact on an Account in Salesforce. Screenshots captured live from a real org by Playwright CLI, then composed into a captioned, voiced video with an animated cursor and highlight boxes on the click targets. |

The point of the pairing: learn the mechanics on something you can hold in your head, then apply the exact same mechanics to a production artifact.

---

## The Two Tools

### Playwright CLI — the capture half

A command-line browser-automation interface designed for coding agents. Token-efficient output and installable skills let an agent drive a browser without loading huge tool schemas into context.

```bash
npm install -g @playwright/cli@latest   # global — install once, works everywhere
playwright-cli install --skills
playwright-cli --help                   # confirm it worked
```

**Why not just use Claude's built-in browser access?** Because a skill built on Playwright CLI keeps working when you switch agents. If your company moves off Claude Code to Gemini, Codex, or anything else next quarter, the Playwright-based process comes with you. It also spans browsers — Chrome, Firefox, WebKit, Edge — so you're not locked to whatever browser the agent happens to embed.

**Authentication is not magic.** Claude runs the Salesforce CLI to mint a one-time login URL, then hands that URL to Playwright. Playwright just opens what it's told to open.

**Watching it work:** by default the browser is headless. Say "use a **headed** session" if you want to see the clicks happen.

### HyperFrames — the composition half

An open-source framework (from HeyGen, Apache 2.0) that turns HTML into video. There is no screen recorder and no video file until the very end — you describe what you want, the agent writes HTML/CSS/JavaScript, and a render pass turns that into an MP4.

```bash
npx skills add heygen-com/hyperframes --full-depth
npx hyperframes --help                  # confirm it worked
```

The installer walks a short wizard: **which skills** (Select All is fine — uncheck Figma if you'll never use it), **which agents** (Claude Code), **what scope**, and **copy vs. symlink** (symlink is the recommended default).

On scope, take a beat. Three reasonable answers:
- **Project level** — what we did here; drops into this folder only
- **Global** — available wherever you run Claude
- **One "marketing" directory** — Bill's actual setup: every marketing skill lives in one project folder, one place to upgrade, and output files get written elsewhere

**Everything in the project is source you can read and edit.** Timing lives in HTML data attributes:

```html
<img id="product-shot" class="clip"
     data-start="2" data-duration="3" data-track-index="1"
     src="./assets/product.png" />
```

That's an image starting at 2s, on screen for 3s, on track 1. Because time is part of the source, the renderer seeks to an exact timestamp rather than depending on live playback — the same project renders the same video every time.

**You don't need to know the skill names.** `/hyperframes` is the entry point; it reads your request and routes to the right workflow (product launch, faceless explainer, PR-to-video, slideshow, motion graphic, music-driven, Figma import, general video). Call a workflow directly only when you already know which one you want.

---

## How the Session Went

### 1. Simple circle — one prompt at a time

Each step was a plain-English prompt with no technical detail baked in:

| Prompt | What it added |
|---|---|
| "single scene… sky blue background… red circle on the left that moves all the way to the right over 5 seconds" | The scaffold — `videos/simple-circle/` with `index.html`, `hyperframes.json`, `meta.json`, and the GSAP tween doing the motion |
| "keep the circle in place for 2 seconds, fade its color to blue, then move back to the left" | A second and third beat inside the same scene |
| "add a captions bar at the bottom explaining what's happening at each step" | A caption track — and Claude *wrote the caption copy itself* from what it saw in the scene |
| "add a basic voice-over track that reads the captions" | Three separate WAV files under `assets/audio/`, one per line, via the bundled Kokoro TTS |
| "VO2 and VO3 are running into each other — add some time spacing" | Gap tuning between voice lines |
| "use the rh-brand directory as inspiration to update our colors and layout" | Recolored to the Resource Hero palette |
| "This looks great. Let's render!" | `renders/` gets the MP4 |

**One voiceover file per line, not one per video.** That's the detail that makes re-cuts cheap: extend a scene or reorder beats and you re-record one line, not the whole track.

**Preview before render.** `npx hyperframes preview` opens Studio — a local server where you can play the composition, click any element, and edit its code inline. Studio and VS Code are editing the *same* `index.html`; a change in one shows up in the other. (Gotcha we hit live: the preview's code panel caches — the playback updates immediately, but hard-refresh the tab to see the updated source.)

**Snapshots are the verification loop.** After each change Claude captures frames at chosen timestamps into `snapshots/` and checks that things are where they should be. The `contact-sheet.jpg` puts them all on one image so you can eyeball the whole video without opening a browser.

### 2. Capture — Playwright against a real org

One prompt, no HyperFrames involved yet:

> I want to create support documentation for salesforce users that walks them through how to create a new contact on an account. Open my default salesforce org using the playwright-cli, and capture screenshots of every step that takes them from the home screen, to an account, to the related tab, new contact button, etc. Let's capture every change in state so that we can use these screenshots in a future support video or animation. Make up some test data for the contact. Place all screenshots in the videos/create-account-contact/assets directory (create it if you need to). Make sure not to capture tooltips or other popups.

Out came 12 sequential screenshots — home → Accounts list → Burlington Textiles account → Related tab → Contacts related list → empty New Contact modal → name filled → details filled → complete form → save confirmation → contact in the related list → the new contact's detail page. Test data invented on the spot (Jordan Ellis, VP of Operations).

Two deliberate choices in that prompt:
- **"every change in state"** — capturing each field as it fills gives you more to animate against later, even if you end up using only a few of the frames
- **"no tooltips or popups"** — the agent hovers while it clicks, and a stray tooltip in frame ruins a screenshot

**Capture raw first, decorate later.** Highlights and cursors are added in the *composition*, not the screenshot. If you bake them into the capture and get one wrong, you re-shoot; if they live in the HTML, you just re-prompt.

### 3. Compose — screenshots into a narrated walkthrough

> This looks great. Now, using the lessons learned in the simple-circle video, let's create a HyperFrames video showing the process. Include captions.

Claude asked three questions before building: should each caption also get a voiceover (yes), storyboard or one-shot build (one-shot, for time), and aspect ratio (1920×1080, matching the capture). It wrote `BRIEF.md`, then 12 scenes with a caption bar and a synced Kokoro voice line each.

Then the enhancement pass:

> I want to make sure that we have a mouse pointer directing the user's focus, and we should highlight sections in some way so they know what we're speaking about, and a click animation. Don't render — let's make these changes, then preview. For now, focus only on steps 4 and 5.

Note what *wasn't* specified: cursor size, hand vs. arrow, highlight color, box vs. dim-the-screen. That's the iteration surface — nail your preferences once, then bank them.

**Honest result:** the highlight boxes landed cleanly on the Related tab and the New button. The mouse-click positions missed the mark. That's a normal correction round — "hey buddy, you missed the clicks" — not a failure of the approach.

---

## Why This Beats Recording a Zoom Walkthrough

If you only ever make the video once, screen-recording yourself is faster. The savings arrive on the **second, third, and fourth** time.

Salesforce renames Pardot to Marketing Cloud Account Engagement. Your app's button moves. The UI style shifts. With a Zoom recording, you re-shoot the whole thing, mouse fumbles and all. With a HyperFrames project, you open the folder and say: *"Salesforce renamed Pardot to Account Engagement — recapture the screens and re-render."* Playwright re-shoots to the same filenames, the composition doesn't change, and you get the same video beat-for-beat with fresh screenshots. If the captions and voiceover mention the old name, those regenerate too — and if the new name is longer, the scene stretches to fit the audio.

> **Documentation rots because the second pass costs as much as the first.** When the capture and the composition are files on disk, the re-shoot next release is nearly free.

---

## Storyboards — and Bill's Actual Workflow

A **storyboard** is a markdown file listing every scene: what's on screen, what animates, what the narration says. It's the cheap review pass — read a page of text and correct it in seconds, rather than waiting ten minutes for a render only to say "why did you do that in scene 2?" Ask for one when the video is long or the process is complex; skip it (as we did) for a short one-shot build.

The pipeline behind every Resource Hero feature sprint — one existing feature every two weeks, and each stage feeds the next:

1. **Write the support article first.** Nailing the steps and terminology *is* the storyboard's backbone. The doc is the script.
2. **Point Claude at the article.** It scrapes the click paths and generates the storyboard and VO script — and it can be aimed: "focus on the end-user perspective" vs. "focus on the admin perspective" produces genuinely different videos from the same page.
3. **One Playwright pass over a dedicated demo org** (product installed, test data seeded — the "screenshot org") grabs everything the storyboard calls for, including the product stills that go back into the article.
4. **Approve the VO script**, then hand off to HyperFrames and go work on something else while it builds.
5. **Two cuts from one capture** — a 2–3 minute narrated walkthrough for YouTube, and a 45–60 second silent short of the single best moment for LinkedIn.

Set your target resolution *before* the capture pass if the video is bound for a platform with specific requirements.

---

## Directory Map

| Path | What it is |
|---|---|
| `session-7-slides.html` | The presentation deck (13 slides). Open in a browser; arrow keys navigate. |
| `session-steps.md` | The prompt cheat sheet — install commands and every prompt used in the demos |
| `videos/simple-circle/` | The teaching video — circle, captions, voiceover, brand pass |
| `videos/create-account-contact/` | The Salesforce support walkthrough — 12 screenshots, 12 narrated scenes, cursor + highlights |
| `.claude/skills/` | The HyperFrames skill bundle installed at project scope |
| `.agents/skills/` | Same skills in the emerging cross-agent standard location |
| `.playwright-cli/` | Playwright session artifacts — console log and per-page accessibility snapshots from the capture run |
| `force-app/`, `config/`, `sfdx-project.json` | The stock SFDX scaffold this session started from |

### Inside a HyperFrames project

```
videos/create-account-contact/
├── BRIEF.md            what the video must communicate (workflow, aspect, assets, notes)
├── index.html          the composition — scenes, timing, motion. This IS the video.
├── hyperframes.json    project settings
├── audio_meta.json     TTS provider, voice id, per-line durations
├── assets/             the 12 Playwright screenshots + generated voice WAVs
├── snapshots/          verification frames + contact-sheet.jpg
└── renders/            finished MP4 lands here
```

`STORYBOARD.md`, `SCRIPT.md`, and `frame.md` show up too when the workflow calls for them. Only the composition source is essential — the planning files exist to preserve decisions across reviews and agent sessions.

---

## Questions From the Room

**Do I need to know HTML/CSS/JS?** No. Knowing it lets you tweak by hand, but you can do 100% of this through prompts. A useful middle path: screenshot the preview, mark it up with arrows and boxes in any paint tool, paste it into Claude, and say "move the arrow to where I circled."

**How hard are these tools to learn?** You need to know their names and what they do. That's it.

**Can I embed existing video?** Yes. There's also a HyperFrames skill that converts an existing video *into* an editable HyperFrames project.

**Is this safe to install?** Take the beat. Anthropic-marketplace plugins carry a different level of scrutiny than a random GitHub repo; for the latter, clone and read before you connect an agent to it. HyperFrames and Playwright are both open-source, widely used, and long-lived (Playwright is Microsoft's), which is different from trusting a trending repo from someone you've never heard of. Trust isn't binary — put a number on it. And regardless of source, any tool acting on your machine can change or destroy things, so think hard before pointing one at proprietary or confidential material.

**Can I use my own voice?** Yes — ElevenLabs (free to sign up) lets you clone a voice from a few minutes of recordings, or pick from thousands of stock voices, or use characters. Authenticate via API and Claude routes the TTS there instead of local Kokoro. Same WAV-per-line structure comes back. There are services that will build a video avatar of you, too.

**Sound effects and music?** Not bundled with HyperFrames as far as we found — ElevenLabs covers clicks, beds, and stings for a few dollars a month. HyperFrames does know how to duck a music bed under a voiceover, ramp in, and crescendo out.

**Can I schedule this — new content in, video auto-posted to YouTube?** Every piece exists: a scheduled Claude agent watching a page, the generation step we just demoed, and a YouTube API upload. Nobody on the call had wired the last leg end to end, but there's no obvious blocker. Add a Slack approval step in the middle.

**Experience Cloud portals?** If it opens in a browser, Playwright can drive it.

**Subagents?** A natural fit for the capture leg — let a subagent open the org, take all the screenshots, and validate them in its own context window, then hand the asset list back to the main session for composition.

**What's the `.agents` folder?** The emerging cross-agent standard for skills, so you don't recreate or symlink the same skill into `.claude`, `.codex`, and friends. For our purposes here it holds the same content as `.claude/skills`.

---

## Concepts Demonstrated

- **The second pass is the payoff** — automating capture + composition doesn't beat a screen recording the first time; it wins every time after
- **Capture and composition are separate stages** — raw screenshots first, cursors and highlights in the HTML afterward, so a bad highlight costs a prompt instead of a re-shoot
- **Time is part of the source** — `data-start` / `data-duration` / `data-track-index` in HTML make the render deterministic and the project diffable in git
- **One voice file per line** — granular audio is what makes re-cuts and renames cheap
- **Storyboard as the cheap review pass** — correct a page of markdown in seconds instead of a ten-minute render
- **The support article is the script** — write the doc first and the storyboard, the shot list, and the VO all fall out of it
- **Preview, don't render, while iterating** — render is the last step, not the feedback loop
- **Agent portability** — building on Playwright CLI instead of an agent's built-in browser keeps the process alive across agent switches
- **Bank your preferences** — after the first video, roll everything you nudged (voice gaps, highlight style, cursor treatment, caption placement, where renders go) into your own skill so the tenth video starts where the ninth ended

---

## Where You Take It Next

None of this is needed for your first video. Each one makes the tenth faster and more consistent than the first.

- **Better voice, and music beds** — swap Kokoro for ElevenLabs when the video is customer-facing, and lay a bed underneath
- **A brand folder** — colors, fonts, logo, and the rules for using them, sitting where the agent reads them, so you stop re-specifying your palette every prompt. No brand guide? Point Claude at your website and have it write one.
- **Your own skill** — house style, default length, caption treatment, highlight conventions, render destination
- **A reusable capture script** — the saved browser state plus the shot list *is* the asset; next release, re-run it and only the changed screens need attention
- **Publish and template it** — share a project by URL, and use variables to produce the same video for a different product, customer, or org

---

## Homework

- Start small — a basic example, because thinking and rendering both take real time
- Install both tools and make a circle move. Then give it a caption. Then give it a voice.
- Then capture something real from an org you have access to and narrate it
- Post what you make and tag Bill and Code With Sally — **extra credit for a heavy metal music bed**

---

## Resources

| | |
|---|---|
| Playwright CLI | [playwright.dev/agent-cli/introduction](https://playwright.dev/agent-cli/introduction) · [github.com/microsoft/playwright-cli](https://github.com/microsoft/playwright-cli) |
| HyperFrames | [hyperframes.heygen.com](https://hyperframes.heygen.com) · [github.com/heygen-com/hyperframes](https://github.com/heygen-com/hyperframes) (Apache 2.0) · [hyperframes.dev](https://hyperframes.dev) playground · [component catalog](https://hyperframes.heygen.com/catalog) |
| Claude Code | [code.claude.com/docs](https://code.claude.com/docs) |
| Voice & audio | [Kokoro-82M](https://huggingface.co/hexgrad/Kokoro-82M) — local TTS, free, what `hyperframes tts` runs · [elevenlabs.io](https://elevenlabs.io) — paid voice and music |

```bash
# the two installs, start to finish
npm install -g @playwright/cli  &&  playwright-cli install --skills
npx skills add heygen-com/hyperframes --full-depth
```
