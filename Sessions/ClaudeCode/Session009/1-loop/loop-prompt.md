# Loop: Close the case when the client confirms

**Run from:** this folder (`1-loop/`), so `.claude/settings.json` applies.
**Command:** `/loop 1m` followed by the prompt.
**Tools:** Microsoft 365 search, Slack (post and read thread), and the local `sf` CLI against the demo org (alias `cws`).

## The prompt we ran live

Typed the way you would before rushing out the door (or dictated):

```
/loop 1m keep an eye out for an email from sally (emai***********@gmail.com) saying she's happy and case 00001027 can be closed. only look at her emails, and ignore anything from her that isn't about that. when she confirms, close the case in the cws org with the sf cli, then post in slack #test-cws that she confirmed and it's closed. after that watch that slack thread, and when someone replies add their reply as a comment on the case and stop the loop
```

**What went wrong on stream:** two email accounts were connected (Gmail and Microsoft 365), and "an email" sent the loop to Gmail first. One follow-up, "check M365", fixed it: Claude deleted the job and recreated it. For a one-off loop that's fine. For a loop you run every day, write "in Microsoft 365" into the prompt, or into the project's `CLAUDE.md`.

## What keeps it safe

- `.claude/settings.json` pre-approves only the seven tools the loop needs. Sending email isn't one of them, so the loop would stop and ask before sending one. **The prompt asks; the permissions decide.**
- The sender address keeps the search to Sally's mail.
- A Slack allow rule can't be limited to one channel, so the prompt names the channel.

## A more specific version

The detailed form of the same loop. It's slower to write, but it leaves less to guess:

```
/loop 1m We're waiting for Sally ElGhoul to confirm that case 00001027 can be closed. Each time you run:

1. Check the case status: sf data query -o cws -q "SELECT Status FROM Case WHERE CaseNumber = '00001027'"

2. If the case is NOT Closed, watch for Sally's confirmation:
   - Search Microsoft 365 for emails from emai***********@gmail.com received today. Search by that sender only. Never list, read or summarize any other mail.
   - Decide whether any of her emails says she is happy with the fix and that the case can be closed. An email about anything else does not count. Ignore it and keep waiting.
   - If there is no confirmation, reply with one line, "Still waiting on Sally.", and end this run.
   - If she has confirmed:
     a. Close the case with sf data update record (Status='Closed').
     b. Only after the close succeeds, post one message to Slack #test-cws: Sally confirmed she's happy with the fix for case 00001027, so the case is now closed. Quote her one-line confirmation. Remember the message's timestamp.
     c. Do not stop the loop. The next run moves to step 3.

3. If the case IS Closed and you posted the close message earlier in this session, watch for a follow-up:
   - Read the replies in the thread under your Slack message.
   - If there are no replies, reply with one line, "No follow-up yet.", and end this run.
   - If someone replied, add their reply to the case as a CaseComment ("Slack follow-up from <name>: <reply text>"), then stop this loop.

4. If the case is Closed but you did not close it in this session, stop the loop and tell me.

Rules: touch only case 00001027. Post only to #test-cws. Never send, reply to or draft an email.
```

Close before posting, so Slack never claims a close that failed.

## Reset between runs

```bash
sf data update record -o cws -s Case -w "CaseNumber='00001027'" -v "Status='Working'"
sf data query -o cws -q "SELECT Id FROM CaseComment WHERE Parent.CaseNumber = '00001027'"
sf data delete record -o cws -s CaseComment -i <Id>   # for each comment returned
```

Also delete the loop's Slack messages and the test emails, so the next run starts clean.
