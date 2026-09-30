---
name: regression-calculator-ui-test
description: Run the full Regression Calculator test suite — Jest (LWC), Apex, and browser UI tests of the Calc LWC tab with playwright-cli — then add the run to the shared "Calculator Test Runs" report artifact. Use when asked to "run the calculator UI test", "run the regression suite", "run all the calculator tests", "UI test the regression calculator", or to check the calculator works in the org after a deploy.
allowed-tools: Bash(playwright-cli:*) Bash(sf:*) Bash(npx:*) Bash(jq:*) Bash(git:*) Bash(date:*) Bash(mktemp:*) mcp__claude_ai_Slack__slack_read_channel
---

# Regression Calculator Test Run

Runs three suites against the `regressionCalculator` LWC, then records the run in the
shared report:

| Suite | What it covers | Runs where |
|---|---|---|
| Jest (LWC) | Calculator logic, rounding, errors, Clear; Apex mocked | Locally |
| Apex | All local Apex tests in the org, incl. `CalcHistoryControllerTest` | The org |
| UI (browser) | The LWC on the real Calc LWC tab, real saves, record page | The org, via `playwright-cli` |

**Report:** https://claude.ai/artifact/6rxAKeu1A93q2qqhcDzboK ("Calculator Test Runs").
Each run is one document in its `runs` collection; the page lists them newest first.

Run from the project root (the folder with `sfdx-project.json`). Use the `playwright-cli`
skill's commands for the browser. Don't install packages or write test files.

## Inputs

- **Org:** the sf CLI default org unless the user names one. If they do, add
  `-o <alias>` to every `sf` command.
- **Headed:** only if the user asks to watch; add `--headed` to `playwright-cli open`.
- **Notes:** anything the user says about why this run happened (optional, goes in the report).

## 0. Start the run

```bash
RUN_DIR=$(mktemp -d)
RUN_ID=$(date -u +%Y-%m-%dT%H-%M-%SZ)
STARTED=$(date -u +%Y-%m-%dT%H:%M:%SZ)
ORG=$(sf config get target-org --json | jq -r '.result[0].value')
COMMIT=$(git rev-parse --short HEAD)
DIRTY=$([ -n "$(git status --porcelain)" ] && echo true || echo false)
```

Carry these values through every step (shell variables don't persist between Bash
calls, so reuse the literal values).

## 1. Jest (LWC)

```bash
npx sfdx-lwc-jest -- --json --outputFile=$RUN_DIR/jest.json
jq '{key:"jest", name:"Jest (LWC)", command:"npx sfdx-lwc-jest",
  status:(if .success then "passed" else "failed" end),
  passed:.numPassedTests, failed:.numFailedTests, skipped:(.numPendingTests + .numTodoTests),
  durationSec:((([.testResults[].endTime] | max) - .startTime) / 1000),
  tests:[.testResults[] | .assertionResults[] | {
    group:((if (.ancestorTitles | length) > 1 then .ancestorTitles[1:] else .ancestorTitles end) | join(" › ")),
    name:.title, durationMs:.duration,
    status:(if .status=="passed" then "passed" elif .status=="failed" then "failed" else "skipped" end),
    detail:((.failureMessages // []) | join("\n") | .[0:2000])}]}' \
  $RUN_DIR/jest.json > $RUN_DIR/suite-jest.json
```

A non-zero exit from Jest just means a test failed; keep going.

## 2. Apex

```bash
sf apex run test --test-level RunLocalTests -c -r json -w 10 > $RUN_DIR/apex.json
jq '.result as $r | ($r.tests | map(.Outcome)) as $o | {key:"apex", name:"Apex",
  command:"sf apex run test --test-level RunLocalTests -c",
  status:(if ($o | map(select(. == "Fail" or . == "CompileFail")) | length) == 0 then "passed" else "failed" end),
  passed:($o | map(select(. == "Pass")) | length),
  failed:($o | map(select(. == "Fail" or . == "CompileFail")) | length),
  skipped:($o | map(select(. == "Skip")) | length),
  durationSec:(($r.summary.testTotalTime | sub(" ms";"") | tonumber) / 1000),
  coverage:([$r.coverage.coverage[] | select(.name=="CalcHistoryController") | {label:.name, pct:.coveredPercent}] | first),
  tests:[$r.tests[] | {group:.ApexClass.Name, name:.MethodName, durationMs:.RunTime,
    status:(if .Outcome=="Pass" then "passed" elif (.Outcome=="Fail" or .Outcome=="CompileFail") then "failed" else "skipped" end),
    detail:([.Message, .StackTrace] | map(select(. != null)) | join("\n"))}]}' \
  $RUN_DIR/apex.json > $RUN_DIR/suite-apex.json
```

Counts come from the listed test results: the CLI's summary `testsRan` can be one higher
than the tests it lists.

## 3. UI tests (browser)

### 3a. Open the Calc LWC tab

Use a named session so this doesn't disturb any other browser that's open:

```bash
URL=$(sf org open --url-only --path /lightning/n/Calculator_Testing --json | jq -r .result.url)
playwright-cli -s=calc-ui open "$URL"
```

`sf org open --url-only` returns a one-time login link. Don't print it, because it
contains a session token.

### 3b. Smoke check

```bash
playwright-cli -s=calc-ui run-code "async page => {
  const root = page.locator('c-regression-calculator');
  await root.locator('[data-id=\"screen\"]').waitFor({ timeout: 60000 });
  return {
    title: (await root.getByRole('heading').first().textContent()).trim(),
    screen: (await root.locator('[data-id=\"screen\"]').textContent()).trim(),
    buttons: await root.locator('button').count(),
    error: await root.locator('[data-id=\"error-message\"]').count()
  };
}"
```

**Pass:** title `Regression Calculator`, screen `0`, `17` buttons, error `0`.

### 3c. Calculation scenarios

Run each scenario with the script below. Set `KEYS` to the button `data-id`s in order.
The script presses Clear first, then clicks the keys, and returns the screen, the error
message, and the result of any Apex save call.

Button `data-id`s: `digit-0` … `digit-9`, `decimal-button`, `add-button`,
`subtract-button`, `multiply-button`, `divide-button`, `equals-button`, `clear-button`.

```bash
KEYS='["digit-6","digit-0","add-button","digit-7","equals-button"]'
playwright-cli -s=calc-ui run-code "async page => {
  const keys = $KEYS;
  const root = page.locator('c-regression-calculator');
  if (!page.url().includes('/lightning/n/Calculator_Testing')) {
    await page.goto(page.url().match(/^https?:\/\/[^/]+/)[0] + '/lightning/n/Calculator_Testing');
  }
  await root.locator('[data-id=\"screen\"]').waitFor({ timeout: 60000 });
  await root.locator('[data-id=\"clear-button\"]').click();
  const saves = [];
  const onResponse = r => {
    if (r.url().includes('ApexAction.execute') && (r.request().postData() || '').includes('CalcHistoryController')) saves.push(r);
  };
  page.on('response', onResponse);
  for (const id of keys) await root.locator('[data-id=\"' + id + '\"]').click();
  await page.waitForTimeout(3000);
  page.off('response', onResponse);
  const apex = [];
  for (const r of saves) {
    const action = ((await r.json()).actions || []).find(a => a.state) || {};
    apex.push({ state: action.state, recordId: action.returnValue && action.returnValue.returnValue });
  }
  const err = root.locator('[data-id=\"error-message\"]');
  return {
    screen: (await root.locator('[data-id=\"screen\"]').textContent()).trim(),
    error: (await err.count()) ? (await err.textContent()).trim() : null,
    apex
  };
}"
```

Keep every `recordId` returned, for 3d and cleanup.

| # | Scenario | Keys | Pass when |
|---|---|---|---|
| 1 | Add saves | 6 0 + 7 = | screen `67`, no error, one Apex call with state `SUCCESS` and a `recordId` |
| 2 | Subtract saves | 9 − 4 = | screen `5`, one `SUCCESS` save |
| 3 | Multiply saves | 6 × 7 = | screen `42`, one `SUCCESS` save |
| 4 | Divide saves | 8 ÷ 2 = | screen `4`, one `SUCCESS` save |
| 5 | Rounding | 1 0 ÷ 3 = | screen `3.33`, one `SUCCESS` save |
| 6 | Divide by zero | 5 ÷ 0 = | screen `0`, error `That calculation did not produce a valid number.`, **no** Apex call |
| 7 | Clear drops pending op | 5 + C 3 = | screen `3`, no error, **no** Apex call |

### 3c-2. Check the Slack post for 67

When a Calc History record with Answer 67 is created, the "Calc History 67 Slack Alert"
flow posts to `#calc-history` (channel `C0C5Z228W0Y`). The post runs after the save
commits, so it arrives a few seconds later. It looks like:

```
6:shrug:7  (60 Add 7 = 67, record a0YNS00000DdOML2A3)
```

After scenario 1, wait 30 seconds, then read the channel with the Slack connector's
`slack_read_channel` tool (`channel_id: C0C5Z228W0Y`, `limit: 5`,
`response_format: concise`; load it with ToolSearch if needed).

**Pass:** a message contains scenario 1's `recordId` and `60 Add 7 = 67`. If it isn't
there yet, check again every 30 seconds for up to 2 minutes before calling it a failure.
If scenario 1 saved no record, this check fails too; say so in its `detail`.

Deleting the record in 3e doesn't remove the Slack message. Each run leaves one post in
the channel, which is expected.

### 3d. Check a saved record in the UI

Open scenario 1's record page:

```bash
playwright-cli -s=calc-ui run-code "async page => {
  const origin = page.url().match(/^https?:\/\/[^/]+/)[0];
  await page.goto(origin + '/lightning/r/Calc_History__c/<recordId>/view');
  const items = page.locator('records-record-layout-item');
  await items.filter({ hasText: 'Answer' }).first().waitFor({ timeout: 60000 });
  const fields = {};
  for (const text of await items.allInnerTexts()) {
    const lines = text.split('\n').map(l => l.trim()).filter(Boolean);
    if (lines.length >= 2) fields[lines[0]] = lines[1];
  }
  return fields;
}"
```

**Pass:** `Number 1` = `60.00`, `Number 2` = `7.00`, `Operation` = `Add`, `Answer` = `67.00`, and
`Calc History Name` looks like `CH-0000`.

On any failed check, take `playwright-cli -s=calc-ui screenshot` before moving on.

### 3e. Clean up

The UI tests create real records, so delete each one they saved, then close the browser:

```bash
sf data delete record -s Calc_History__c -i <recordId>
playwright-cli -s=calc-ui close
```

### 3f. Write the UI suite result

Write `$RUN_DIR/suite-ui.json` with one test per check (10 in all), filling every field
for every test, passed or failed, so the report shows what each one did:

- `group`: `Page load` (smoke), `Calculations that save` (scenarios 1–5),
  `Calculations that must not save` (6–7), `Slack alert` (3c-2), or `Saved record` (3d).
- `name`: the scenario name with its sum, for example `Add saves: 60 + 7 = 67`.
- `steps`: the buttons pressed, starting with the Clear press, for example `C 6 0 + 7 =`.
- `expected` / `actual`: the screen, the error message and the save outcome.
- `detail`: only when needed, for example the server error behind a failure, or why a
  check ran differently from the instructions.

```json
{
  "key": "ui", "name": "UI (browser)", "command": "playwright-cli -s=calc-ui",
  "status": "passed", "passed": 10, "failed": 0, "skipped": 0, "durationSec": 130,
  "tests": [
    { "group": "Page load", "name": "Calc LWC tab renders the calculator", "status": "passed",
      "steps": "Open /lightning/n/Calculator_Testing",
      "expected": "Title \"Regression Calculator\", screen 0, 17 buttons, no error",
      "actual": "Title \"Regression Calculator\", screen 0, 17 buttons, no error" },
    { "group": "Calculations that save", "name": "Add saves: 60 + 7 = 67", "status": "passed",
      "steps": "C 6 0 + 7 =", "expected": "Screen 67, no error, one save that succeeds",
      "actual": "Screen 67, saved CH-0032" }
  ]
}
```

`status` is `failed` if any test failed. `durationSec` runs from 3a through 3e.

## 4. Add the run to the report

Build the run document:

```bash
FINISHED=$(date -u +%Y-%m-%dT%H:%M:%SZ)
jq -s --arg id "$RUN_ID" --arg started "$STARTED" --arg finished "$FINISHED" \
  --arg org "$ORG" --arg commit "$COMMIT" --argjson dirty $DIRTY --arg notes "<notes or empty>" \
  '{runId:$id, startedAt:$started, finishedAt:$finished, org:$org, gitCommit:$commit, gitDirty:$dirty,
    durationSec:(($finished | fromdateiso8601) - ($started | fromdateiso8601)),
    status:(if any(.[]; .status == "failed") then "failed" else "passed" end),
    totals:{passed:(map(.passed) | add), failed:(map(.failed) | add), skipped:(map(.skipped) | add)},
    notes:$notes, suites:.}' \
  $RUN_DIR/suite-jest.json $RUN_DIR/suite-apex.json $RUN_DIR/suite-ui.json > $RUN_DIR/run.json
```

Then write it with the `ArtifactData` tool (load it with ToolSearch if needed):

- `action`: `set`
- `url`: `https://claude.ai/artifact/6rxAKeu1A93q2qqhcDzboK`
- `collection`: `runs`
- `doc_id`: the `RUN_ID` value
- `file_path`: `$RUN_DIR/run.json` (the literal path)

Every run is a new document, so no `if_version` is needed. Never edit or delete earlier
runs unless the user asks.

## 5. Report back

Reply with a short table: one row per suite with passed/failed/skipped, then any failing
tests with expected and actual values, the number of Calc History records cleaned up,
and the report link.

## Troubleshooting

- **Screen never appears:** the page is still loading, or the LWC isn't on the Calc LWC
  tab. Take a `playwright-cli -s=calc-ui snapshot` and check it.
- **Save expected but no Apex call:** the 3-second wait may be too short on a slow org.
  Rerun the scenario before calling it a failure.
- **`URL is not defined` in run-code:** the `run-code` sandbox has no `URL` global.
  Parse URLs with a regex, as the scripts above do.
- **An answer of 67:** the "Block Answer 67" validation rule blocks the save when it's
  switched on, so scenario 1 and the Slack check both fail. The "Calc History 67 Slack
  Alert" flow must be active for the Slack check to pass. Check either one with
  `sf data query --use-tooling-api` on `ValidationRule` (`Active`) or `FlowDefinition`
  (`ActiveVersionId`).
