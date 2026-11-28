# Live Demo Issue: Account Name Prefix

Filed live in `cws-session10-a` as issue #21. The run started within seconds and finished in about two minutes.

**Title:** Account name trigger: pending review

**Body:**

```
Whenever a new account is created, add a "PENDING REVIEW: " prefix on the account name.
```

The issue doesn't say "trigger" or "flow". It describes the outcome and leaves the design to Claude.

## What came back

The routine posted "Reviewing the issue", edited that comment as it worked, then posted this final report and closed the issue:

> **What changed**
> - New `AccountTrigger` (before insert) and `AccountNamePrefixer` class: every new Account's name now starts with `PENDING REVIEW: `.
> - A name that already has the prefix doesn't get a second one. If adding the prefix pushes a name past 255 characters, the end is cut off. Renaming an existing Account doesn't add the prefix.
> - `AccountNamePrefixerTest` (5 tests) covers these cases.
>
> **Deploy**
> - Succeeded with RunSpecifiedTests (`GreeterTest`, `AccountNamePrefixerTest`).
> - Tests: 8 passed, 0 failed.
>
> Note: the trigger is now active in the org, so Accounts created there get the prefix before #22 is merged.

Then we created an Account called "Code with Bill" in the org, and it saved as **PENDING REVIEW: Code with Bill**.

The code it wrote (pull request #22) is in [`what-claude-built/`](what-claude-built/). It's arguably over-engineered for a one-line rule: a trigger plus a separate class. That's because the repo's `CLAUDE.md` asks for exactly that. The follow-up is in `../4-routine-issue-labeled/`.
