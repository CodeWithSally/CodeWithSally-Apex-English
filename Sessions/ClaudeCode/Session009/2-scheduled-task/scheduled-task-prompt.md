# Scheduled Task: Turn client emails into Salesforce cases

Created at **claude.ai > Scheduled > New task > Set up manually**.

| Field | Value used live |
|---|---|
| Name | Turn client emails into Salesforce cases |
| Permissions | **Auto**. Manual would stall an unattended run, and Skip all approvals removes the safety check for no gain. |
| Model | Opus 5.5 |
| Trigger | Schedule, **Hourly** (the shortest interval; there's no time-of-day or window field) |
| Advanced > Repository / Project | none. Picking a repository makes this a Claude Code task, i.e. a routine. |
| Advanced > Connectors | All of your connectors, with no way to deselect any. Limit risk with each connector's own tool permissions (Customize > Connectors) and with the prompt. |

Connectors used: **Microsoft 365**, **Slack**, and **CWS - All** (a Salesforce Hosted MCP server connected to the demo org).

## Instructions

```
You turn client emails into Salesforce cases. Run these steps every time.

1. **Find the emails.** Use Microsoft 365 to search for emails from `emai***********@gmail.com` received in the last 24 hours. Search by that sender only. Do not list, read or summarize any other mail.

2. **Keep only real requests.** For each email, decide whether the sender is asking a question or asking for help. Skip anything that is not a new request: thank-you notes, confirmations that an issue is resolved, and general chat.

3. **Check for an existing case.** For each request, use CWS - All to look for an open case with the same sender email (the Web Email field, `SuppliedEmail`) and the same subject. If there is one, it is already logged. Skip it.

4. **Create the case.** If no case exists, create one in CWS - All:
   - Subject: the email subject
   - Description: the email body as plain text
   - SuppliedEmail: the sender's address
   - SuppliedName: the sender's name
   - Origin: Email
   - Status: New
   - Priority: Medium
   - ContactId and AccountId: from the Contact whose Email matches the sender, if there is one

5. **Tell the team.** For each case you created, post one message to Slack channel `#test-cws`:
   `New case <CaseNumber> from <sender name>: <subject>`
   Post only for new cases. Never post for skipped ones.

## Rules

- Only create Cases. Never update or delete any record.
- Never send, reply to or draft an email.
- Never post to any Slack channel other than `#test-cws`.
- If anything fails, stop and report the error. Do not retry by creating records again.

## End of run

Finish with one line: emails checked, cases created, requests skipped as already logged.
```

The sender filter is only there so a demo doesn't turn real customer mail into test cases. Drop it for real use.

## Cheaper runs (tips from the session)

- **Time-box it.** A task that runs hourly only needs the last two hours of mail, not 24.
- **Tag what you've handled.** Reading an email through the Microsoft 365 connector doesn't mark it read, and the connector has no "mark as read" tool. It can change categories or labels, though. Tag each processed email and exclude tagged mail next run, so each run looks at less.
- Stop each run as early as you can. Every email it doesn't open is tokens it doesn't spend.
