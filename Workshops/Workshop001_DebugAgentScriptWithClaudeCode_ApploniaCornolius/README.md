# Workshop — Debug Agent Script with Claude Code

**Presenter:** Applonia Cornolius · **Host:** Code With Sally · **When:** November 12, 2026, YouTube Live

A 30-minute hands-on lab. You get an Agentforce Agent Script that will not compile. It has three defects, in increasing order of difficulty — the first one the compiler practically solves for you, the third one it tells you almost nothing about. You'll use the Salesforce CLI and Claude Code to find and fix all three, then watch the agent run.

**This is hands-on.** If you want to follow along live rather than watch, complete the prework below *before* the session. The org sign-up is the slow part, so don't leave it for the day of.

---

## Prework checklist

Budget about 45 minutes, most of it waiting for emails and installers.

- [ ] 1. Get a Developer Edition org with Agentforce
- [ ] 2. Turn on Einstein and Agentforce in the org
- [ ] 3. Install the Salesforce CLI
- [ ] 4. Authorize your org with the alias `mydemo`
- [ ] 5. Install Claude Code and sign in
- [ ] 6. Download the broken script
- [ ] 7. Run the checkpoint

---

## 1. Get a Developer Edition org with Agentforce

Sign up for a free Developer Edition org here: **https://developer.salesforce.com/signup**

Developer Edition orgs now ship with Agentforce included. If you have an old Developer Edition org from before 2025, it may not have Agentforce — sign up for a fresh one rather than fighting with it.

1. Fill in the form. Use a real email address (you'll need the activation email) and a unique username (it looks like an email, but doesn't have to be a real mailbox).
2. Open the activation email and click **Verify Account**. It can take a few minutes to arrive — check spam.
3. Set your password and security question.
4. Save your username, password, and login URL somewhere safe. You'll need them in step 4.

## 2. Turn on Einstein and Agentforce in the org

Log in to your new org, then:

**Einstein first** (Agentforce won't appear until this is on):

1. Click the gear icon (top right) → **Setup**.
2. In the Quick Find box, type `Einstein Setup` and open it.
3. Make sure **Turn on Einstein** is On.

**Then Agentforce:**

1. In Quick Find, type `Agent` and select **Agentforce Agents**.
2. Turn on **Agentforce**.
3. Refresh the page. You should now see a **New Agent** button.

If you don't see the Agentforce Agents page, try Quick Find → `Salesforce Go`, search features for `Agentforce`, select **Agentforce (Default)** → **Get Started** → **Turn On** → **Confirm**.

## 3. Install the Salesforce CLI

Follow the official install guide for your operating system:
**https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_install_cli.htm**

Open a terminal (Terminal on Mac, PowerShell on Windows) and confirm it works:

```
sf --version
```

Then confirm the agent commands are available — this should print help text, not an error:

```
sf agent --help
```

If you already had the CLI installed, run `sf update` so you're on a current version. The `sf agent` commands are newer than many people's installs.

## 4. Authorize your org with the alias `mydemo`

Every command in the session uses the alias **`mydemo`**. Use exactly that name, or you'll be translating commands on the fly while everyone else moves on.

```
sf org login web --alias mydemo --set-default
```

A browser window opens. Log in with the username and password from step 1, click **Allow**, and close the window.

Confirm it worked:

```
sf org display --target-org mydemo
```

You should see your username, org ID, and `Connected Status: Connected`.

## 5. Install Claude Code and sign in

Claude Code is the AI coding tool we'll use to diagnose the script. It runs in your terminal. You need a Claude subscription (Pro, Max, or Team) or an Anthropic Console account to sign in.

Install guide: **https://code.claude.com/docs/en/overview**

**macOS / Linux / WSL:**

```
curl -fsSL https://claude.ai/install.sh | bash
```

**Windows PowerShell:**

```
irm https://claude.ai/install.ps1 | iex
```

The installer shows no progress while it downloads — that's normal. When it finishes, **open a new terminal window** and run:

```
claude --version
```

A version number means you're set. If you get "command not found", see https://code.claude.com/docs/en/troubleshoot-install.

Now sign in. Run `claude` from any folder, follow the login prompt in your browser, then type `/exit` to quit. You only have to do this once.

**Windows users:** install [Git for Windows](https://git-scm.com/downloads/win) too. Claude Code uses it for shell commands, and step 2 of the session uses `git clone`. WSL users already have git.

## 6. Download the broken script

The exercise file is in this folder: [`Summit_Service_Agent.agent`](./Summit_Service_Agent.agent)

1. Click the file name above.
2. Click the **Download raw file** button (the down-arrow icon at the top right of the file view).
3. Make sure it lands in your Downloads folder as `Summit_Service_Agent.agent`.

Two things to watch:

- If you download it twice, your browser will name the second copy `Summit_Service_Agent(1).agent`. Delete it and keep the clean name.
- **Don't open it and start fixing things.** The whole point of the session is finding the defects together. Resist.

## 7. Run the checkpoint

All three of these should succeed before the session:

```
sf org display --target-org mydemo
claude --version
ls ~/Downloads/Summit_Service_Agent.agent
```

(Windows PowerShell: use `ls $HOME\Downloads\Summit_Service_Agent.agent` for the last one.)

If all three work, you're ready. Bring your terminal and your org login, and we'll do the rest live.

---

## Optional (nice to have, not required)

- **VS Code** with the **Salesforce Extension Pack** gives you Agent Script syntax highlighting while you work. We'll be in the terminal for the session, so this is purely for your comfort: https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode

---

## What happens in the session

| Minutes | What we do |
|---|---|
| 00–08 | Connect Claude Code to your org and add the Agentforce skills |
| 08–12 | Scaffold an authoring bundle, drop in the broken script, run `sf agent validate` |
| 12–24 | Fix three defects with Claude Code, re-validating after each |
| 24–28 | Watch the agent run in preview |
| 28–30 | Debrief |

The full participant guide with the step-by-step commands will be shared at the start of the session.

---

## Reference docs

Salesforce:

- Agent Script overview — https://developer.salesforce.com/docs/ai/agentforce/guide/agent-script.html
- Agent Script language characteristics — https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-lang.html
- Agent metadata and authoring bundles — https://developer.salesforce.com/docs/ai/agentforce/guide/agent-dx-metadata.html
- Set up your Agentforce DX environment — https://developer.salesforce.com/docs/ai/agentforce/guide/agent-dx-set-up-env.html
- Agentforce skills for AI coding tools — https://github.com/forcedotcom/sf-skills

Claude Code:

- Overview and install — https://code.claude.com/docs/en/overview
- Quickstart — https://code.claude.com/docs/en/quickstart
- Installation troubleshooting — https://code.claude.com/docs/en/troubleshoot-install

---

## Common prework snags

**"I turned on Agentforce but don't see the New Agent button."** Refresh the page. If it's still missing, confirm Einstein is on (step 2) — Agentforce depends on it.

**`sf agent` says "command not found" or "not a sf command".** Your CLI is out of date. Run `sf update`, then try again.

**`sf org login web` opens the browser but nothing happens afterward.** Make sure you clicked **Allow** on the permissions screen, then check `sf org list` — your org should appear with the `mydemo` alias.

**`claude` isn't recognized after installing.** Open a *new* terminal window first. If it still fails, the install folder isn't on your PATH yet: https://code.claude.com/docs/en/troubleshoot-install#command-not-found-claude-after-installation

**The downloaded file opens as a web page instead of saving.** Right-click **Download raw file** and choose "Save link as…", or use "Raw" view and save the page with the `.agent` extension.
