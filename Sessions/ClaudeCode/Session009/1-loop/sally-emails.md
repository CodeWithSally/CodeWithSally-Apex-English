# Emails Sally sent on stream

**From:** `emai***********@gmail.com`
**To:** Bill's Microsoft 365 inbox

Sally sent these on cue, in this order. Emails 1 and 2 are for the loop; email 3 is for the scheduled task (`../2-scheduled-task/`). Only email 3 is a new request, so the Scheduled Task should turn only that one into a case.

---

## Email 1 - Unrelated (loop section)

The loop should see this and ignore it.

**Subject:** Looking forward to the session

```
Hi Bill,

Just a quick note to say the audience is excited about today's session on loops and scheduled tasks. I've shared the link in the community group as well.

See you on stream!

Sally
```

---

## Email 2 - Case closing confirmation (loop section)

The loop should close case 00001027 and post to #test-cws.

**Subject:** Re: Case 00001027 - Detailed Notes not saving on Case page

```
Hi Bill,

I tested Detailed Notes on the Case page this morning and everything is saving correctly now. I'm really happy with how quickly your team fixed it.

You can go ahead and close the case. Thank you!

Sally
```

---

## Email 3 - New question (Scheduled Task section)

The Scheduled Task should create a new case and post to #test-cws. Run it a second time and it should skip this email because the case already exists.

**Subject:** How do I add Detailed Notes to Opportunities?

```
Hi Bill,

Now that Detailed Notes are working on Cases, our sales team wants to use them on Opportunities too. How do we add the Detailed Notes component to the Opportunity record page? Do we need any extra permissions for the sales users?

Thanks,
Sally
```
