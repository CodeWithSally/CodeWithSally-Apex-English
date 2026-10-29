# Apex Callouts Superbadge Cohort

A two-day, hands-on cohort hosted by **Code With Sally**. You earn the **Apex Callouts** superbadge by building it yourself, in small peer groups. Sally facilitates: she gives hints along the way, not answers.

| | Date | Time | Focus |
|---|---|---|---|
| **Day 1** | Saturday, November 14, 2026 | 12:00 to 2:30 PM EST | REST callouts (Challenges 1 and 2) |
| **Day 2** | Sunday, November 15, 2026 | 12:00 to 2:30 PM EST | SOAP callouts (Challenges 3 and 4) |

**Where:** Virtual, on Zoom. No registration needed. Use the same link both days: **[Join on Zoom](https://us06web.zoom.us/j/84239526681?pwd=0lpHsL7Gnzl7Rv7wNaCpTnu4MUPAJc.1)**

**Language:** English

---

## Before Day 1: prerequisites

Please do these before the first session, so we can start building right away.

### 1. Sign up for the superbadge org

You need a fresh Developer Edition org set up for this superbadge. Don't use an existing org.

Sign up here: **http://sfdc.co/ApexCalloutsDev**

- Use an email you can access, because you'll need to verify it.
- Your username must look like an email address, but it doesn't have to be a real inbox (for example `yourname.apexcallouts@example.com`).
- Write down your username and password. You'll log in to this org on both days.
- Connect the org to your Trailhead account from the superbadge page, so your challenge checks are recorded.

### 2. Fill in the pre-event survey

**[Pre-event survey](https://www.surveymonkey.com/r/ApexCallouts?cohort=ApexSally26)**

### 3. Get access to the cohort tracker

After you fill in the pre-event survey, [contact Sally](https://codewithsally.com/contact-sally/) to get access to the **[cohort tracker sheet](https://docs.google.com/spreadsheets/d/1CZIh_dgCLpXVLtKrLy5dhgzMgA13v4MlnKekwWgwIm0/edit?usp=sharing)**. There, you'll add your details and track your progress through the challenges.

### 4. Have your tools ready

- A browser you're logged in to Trailhead with
- The Developer Console in your org, or VS Code with the Salesforce Extension Pack if you prefer
- A working microphone so you can talk with your group, and a camera (turning it on is encouraged, since it makes group work much easier)

---

## Recommended learning

You don't need to be an expert. Doing some of this first will make the cohort much smoother.

### Trailhead

These are the two modules Trailhead recommends for this superbadge:

- **[Apex Integration Services](https://trailhead.salesforce.com/content/learn/modules/apex_integration_services):** integrate with external apps using Apex REST and SOAP services.
- **[Asynchronous Apex](https://trailhead.salesforce.com/content/learn/modules/asynchronous_apex):** write more efficient Apex code with asynchronous processing.

### Code With Sally videos

⭐ = a topic the superbadge uses directly. Watch these first.

**Callouts** (Challenges 1 and 3)
- ⭐ [Salesforce Apex Invocable Methods, Part 3: Screen Flow + Callout Demo | Real API Example](https://www.youtube.com/watch?v=6rwsQaqGwig)

**Interfaces** (Batchable, HttpCalloutMock and WebServiceMock are all interfaces you implement)
- ⭐ [Understanding 'implements' in Apex | Intro to Interfaces Before Queueable & Batchable](https://www.youtube.com/watch?v=edDf1_CBaX4)

**Batch Apex** (Challenge 1 makes its REST callout from a batch job)
- ⭐ [Batch Apex, Part 1](https://www.youtube.com/watch?v=rq8PD-2EGi4)
- ⭐ [Batch Apex, Part 2 | Unit Testing, Failed Batches & Stateful Demo](https://www.youtube.com/watch?v=mf7e2NSDpC0)
- ⭐ [Batch Apex, Part 3 | Chaining, Callouts, Snippets & Comparison](https://www.youtube.com/watch?v=iYhLE18rvAU)

**Future methods** (Challenge 3 makes its SOAP callout asynchronously from a trigger)
- ⭐ [Understanding Asynchronous Invocation with Future Methods](https://www.youtube.com/watch?v=7TfYHD5TaA4)
- ⭐ [Future Methods (Part 2): Trigger Callouts, JSON, API & Testing](https://www.youtube.com/watch?v=4MZ_DzRvDo8)

**Apex testing and mocking** (Challenges 2 and 4 are all about tests with mock callouts)
- ⭐ [Introduction to Apex Unit Tests, Part 1: Test Classes & Assertion](https://www.youtube.com/watch?v=Dkk_A5ciAxY)
- ⭐ [Running Unit Tests & Code Coverage Essentials, Part 2](https://www.youtube.com/watch?v=FhF1IuP6OG4)
- ⭐ [testSetup, Test Data Factory & Bulk Testing, Part 3](https://www.youtube.com/watch?v=diHYKbHvZqc)
- ⭐ [Exception Testing, Test.startTest & System.runAs, Part 4](https://www.youtube.com/watch?v=RAVHQ0FzwEM)

**Also useful** (not required for the superbadge)
- [Queueable Apex (Part 1): Syntax, Use Cases & Passing Data](https://www.youtube.com/watch?v=qu64UAoWDR4): an alternative to future methods for async callouts
- [Queueable Apex (Part 2): Chaining, Callouts & Testing](https://www.youtube.com/watch?v=1oHimqDoLz0)
- [Scheduled Apex, Part 3: Schedule Apex & Batch Jobs + Unit Testing Best Practices](https://www.youtube.com/watch?v=lV6f_idx2Mk)

More on the [Code With Sally YouTube channel](https://www.youtube.com/@CodeWithSally).

---

## What to expect

**This is a build-it-yourself cohort.** It's not a follow-along where someone codes and you copy.

- **You work in small peer groups.** Each group reads the challenge requirements together, plans the solution, and builds it in their own orgs.
- **Sally gives hints, not answers.** When your group is stuck, she'll point you toward the right question to ask, the right doc to read, or the error message to look at closely.
- **There's a short intro to each topic.** Each day opens with a plain-English walkthrough of the concept (REST on Day 1, SOAP on Day 2) before the groups start building.
- **Mistakes are part of it.** Failed challenge checks and confusing errors are where most of the learning happens. Share them with your group.

### The four challenges

| # | Challenge | Day |
|---|---|---|
| 1 | Configure a Rewards Management Callout (REST callout from a batch job) | Day 1 |
| 2 | Test the Rewards Callout Service (HttpCalloutMock) | Day 1 |
| 3 | Make a SOAP Callout for Accessibility Project Billing (WSDL2Apex) | Day 2 |
| 4 | Test the Billing Callout Service (WebServiceMock) | Day 2 |

If you don't finish everything during the sessions, that's fine. Keep going afterwards, and bring your questions to Day 2.

### After the cohort

Fill in the **[post-event survey](https://www.surveymonkey.com/r/ApexCalloutsPostSurvey?cohort=ApexSally26)**.

---

## Win a free certification exam voucher

**A Code With Sally giveaway.** This giveaway is from Code With Sally and is not sponsored by Salesforce.

To qualify for the random draw:

1. Attend at least one of the two sessions.
2. Fill in the [pre-event survey](https://www.surveymonkey.com/r/ApexCallouts?cohort=ApexSally26).
3. Fill in the [post-event survey](https://www.surveymonkey.com/r/ApexCalloutsPostSurvey?cohort=ApexSally26).
4. Finish the superbadge with the cohort.
5. Share your Trailhead profile link and confirm steps 2 to 4 in the [cohort tracker sheet](https://docs.google.com/spreadsheets/d/1CZIh_dgCLpXVLtKrLy5dhgzMgA13v4MlnKekwWgwIm0/edit?usp=sharing). [Contact Sally](https://codewithsally.com/contact-sally/) for access after you fill in the pre-event survey.

**The draw is on Tuesday, November 17, 2026.** Sally will contact the winner directly.

---

## Questions?

[Contact Sally](https://codewithsally.com/contact-sally/) through Code With Sally.

See you in the cohort!
