# Session 008 — Build an Automated Regression Test Suite with Claude and Playwright

**Series:** Claude with Sally (Code With Sally)
**Topic:** Take a Salesforce component nobody has tested and give it a real regression suite: Jest and Apex unit tests, then end-to-end tests where Claude clicks through the real UI with the Playwright CLI, checks the record with the Salesforce CLI, and confirms a message landed in Slack. Finish with a pass/fail report you can read at a glance.

---

## What We Built

A calculator, built twice on the same design, and a suite that tests it:

| Component | What it is |
|---|---|
| `regressionCalculator` (LWC) | A four-function calculator: digit pad, decimal point, ÷ × − +, C and =. Pressing = saves a `Calc_History__c` record through Apex and shows the answer, or an error if the save was rejected. |
| `Calculator_Screen_Flow` (Screen Flow) | The same logic as screens: Number 1, an operation, Number 2, the answer. It saves with a standard Create Records element (no Apex), and failures land on a friendly error screen. |
| `regression-calculator-ui-test` (skill) | One prompt, "run the regression suite", runs every tier and adds the run to a shared report. |

Two switches make the tests worth watching:

- **`Block_Answer_67`** is a validation rule that rejects any record whose answer is 67 (yes, the "6-7" meme). It ships **inactive**. Turn it on and the 67 test goes red, even though no code changed.
- **`Calc_History_67_Slack_Alert`** is a record-triggered flow that posts `6🤷7` to Slack whenever a 67 record saves. That's the "did it reach outside Salesforce?" check. It ships in **Draft**. Run one switch at a time, because a record the rule blocks never reaches the flow.

> **Someone changed the org, and the suite caught it before a user did.** Unit tests guard your code. End-to-end tests guard everything else.

---

## The Model: Two Tiers of Testing

| Tier | Test | What it answers | Tool |
|---|---|---|---|
| **Unit** — in isolation, fast, before deploy | Jest | Does the LWC logic work: the math, input handling, error messages? | `sfdx-lwc-jest` |
| | Apex | Does the server logic work: does the record insert? | `sf apex run test` |
| **End to end** — against a running org, proves the pieces connect | UI | Did the screen show it? | Playwright CLI |
| | Backend data | Did the record save? | Salesforce CLI |
| | Other systems | Did it reach outside? | Slack |

**Unit tests check each piece on its own. They can't show the pieces work together.** Follow one user action, 60 + 7, all the way through: the screen shows 67, a `Calc_History__c` record has `Answer__c` = 67, and a `6🤷7` post lands in `#calc-history`. That's one end-to-end scenario.

---

## The Tools

### Jest — the component tier

Salesforce's `sfdx-lwc-jest` runs Jest against the LWCs in an SFDX project. It runs locally with no browser and no org, and Apex calls are mocked. Salesforce's own advice: use Jest to unit test individual components, and UI testing tools only for end-to-end tests.

```bash
npm install          # a generated SFDX project already includes sfdx-lwc-jest
npm run test:unit    # add :watch for instant feedback
```

Use the Node.js LTS release. (`sf force lightning lwc test setup` and `lwc test create` crash on Node 26. A generated project doesn't need them.)

### Apex tests — the server tier

Test methods call your classes directly, create their own records, and save nothing. Salesforce requires tests that cover at least 75% of your Apex code, and pass, before you can deploy it.

```bash
sf apex run test -o <alias> --class-names CalcHistoryControllerTest --code-coverage --result-format human
```

### Playwright CLI — the end-to-end tier

A browser Claude drives from the command line, one step at a time. `snapshot` reads the page and gives each element a ref, and `click` and `fill` act on those refs. Every step is a shell command, so every step shows up in the transcript. Login comes from the Salesforce CLI, so no password is stored.

```bash
npm install -g @playwright/cli
sf org open -o <alias> --url-only     # a one-time login URL
playwright-cli open "<login URL>"
playwright-cli snapshot
playwright-cli click e15
playwright-cli close
```

---

## The Report: Why HTML

A test run is only useful if someone reads it, so the suite adds each run to an HTML report. Markdown gives you a list per run and one long file to scroll. HTML can give you a runs-by-suites grid where red jumps out, tabs per suite, a click to expand any test, and a link you can send.

> "…the real reason I use HTML instead of Markdown is that it helps me feel much more in the loop with Claude." — Thariq Shihipar, [Using Claude Code: The unreasonable effectiveness of HTML](https://claude.dev/blog/using-claude-code-the-unreasonable-effectiveness-of-html/)

The path goes from a `.md` file per run, to a local HTML page, to a shared link, to a live team dashboard. Settle the shape of the run data once, and the rest is plumbing.

---

## Try It Yourself

1. **Deploy and grant access**

   ```bash
   sf project deploy start --source-dir force-app --target-org <alias>
   sf org assign permset --name CWS_Regression_Testing --target-org <alias>
   ```

   Open the **Calculator** app for the Calc LWC, Calc Flow and Calc History tabs.

2. **Point it at your own Slack and report.** The Slack flow needs the Slack app for Salesforce connected to your org. The Slack app, workspace and channel IDs in `Calc_History_67_Slack_Alert.flow-meta.xml`, and the channel ID and report link in the test skill, belong to the session's workspace. Swap in your own, or skip the Slack check.

3. **Run it.** Ask Claude Code to "run the regression suite". The skill runs Jest and Apex, then clicks through the Calc LWC tab:
   - **Scenarios:** 60 + 7 = 67, 9 − 4, 6 × 7, 8 ÷ 2, 10 ÷ 3 (rounds to 3.33), 5 ÷ 0 (an error, nothing saved), and 5 + C 3 (Clear drops the pending operation)
   - **Backend:** confirms each save returned a record, and opens one record page to check the values
   - **Slack:** reads the channel and looks for the 67 post, retrying for a couple of minutes because the flow runs after the save commits
   - **Cleanup:** deletes the records it created

4. **Break it.** Activate `Block_Answer_67` (Setup → Object Manager → Calc History → Validation Rules) and run again. The 67 scenario fails. Deactivate it, activate the Slack flow, and run again to see the Slack check pass.

---

## Directory Map

| Path | What it is |
|---|---|
| `session-8-slides.html` | The presentation deck (10 slides). Open in a browser; arrow keys navigate. |
| `force-app/main/default/` | The object, fields, validation rule, Apex class and test, LWC and Jest tests, both flows, pages, tabs, app and permission set |
| `.claude/skills/regression-calculator-ui-test/` | The full regression run |
| `.claude/skills/playwright-cli/` | Browser automation commands for `playwright-cli` |
| `.claude/skills/platform-*`, `automation-flow-generate` | The [forcedotcom/sf-skills](https://github.com/forcedotcom/sf-skills) metadata-generation bundle (versions pinned in `skills-lock.json`) |
| `.playwright/cli.config.json` | Tells `playwright-cli` to use Chromium |
| `config/`, `sfdx-project.json`, `package.json`, `jest.config.js` | The SFDX project scaffold, set up for Jest |

---

## Concepts Demonstrated

- **Two tiers, different questions** — unit tests prove each piece works; end-to-end tests prove the pieces work together
- **Check where the result lands, not just what the screen says** — every UI scenario is paired with a backend check, and the 67 scenario with a Slack check
- **Tests catch org changes, not just code changes** — flip a validation rule and the suite goes red with no commit in sight
- **Clean up after yourself** — end-to-end tests create real records, so the run deletes what it made
- **The report is part of the suite** — a pass/fail page someone actually opens beats a log nobody reads
- **Wrap it in a skill** — the whole suite becomes one prompt anyone on the team can run after a deploy

---

## Homework

1. **Pick a target** — one screen or flow your users rely on every day
2. **Write the scenarios** — one that should pass and one that should fail, in plain English
3. **Test it, then break it** — have Claude check the UI and the record, then confirm the report goes red

---

## Gotchas

- **Full-width App Pages.** The page template for a single full-width region is `flexipage:defaultAppHomeTemplate`. Salesforce doesn't list valid template names through the API, so the reliable way to find one is to build a page in Lightning App Builder and retrieve it into source.
- **`automation-flow-generate` needs an MCP server.** That sf-skills skill depends on a metadata MCP server. Without it, you can hand-write flow XML using `platform-metadata-api-context-get` as the schema reference and check it with a real deploy, which is how the flows here were built.

---

## Resources

| | |
|---|---|
| Claude Code | [code.claude.com/docs](https://code.claude.com/docs) |
| Playwright CLI | [github.com/microsoft/playwright-cli](https://github.com/microsoft/playwright-cli) |
| Jest for LWC | [LWC testing guide](https://developer.salesforce.com/docs/platform/lwc/guide/testing.html) · [sfdx-lwc-jest](https://github.com/salesforce/sfdx-lwc-jest) · [lwc-recipes](https://github.com/trailheadapps/lwc-recipes) |
| Apex testing | Apex Developer Guide: *Testing and Code Coverage* and *Understanding Test Data* |
| HTML reports | [Using Claude Code: The unreasonable effectiveness of HTML](https://claude.dev/blog/using-claude-code-the-unreasonable-effectiveness-of-html/) |
