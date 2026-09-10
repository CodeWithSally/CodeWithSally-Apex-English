<!-- ============================================================= -->
<!-- LOGO: replace the placeholder path below with your image file. -->
<!-- Put the image in this repository, for example assets/code-with-sally-logo.png. -->
<!-- ============================================================= -->

<h1 align="center">Use Coding Agents to Build with Trusted Metadata Context</h1>

<p align="center">
  <strong>Dreamforce 2026</strong><br/>
  Presented by <strong>Gonzalo Gambino</strong> and <strong>Sally ElGhoul</strong>
</p>

---

## Official Salesforce resources

Start here to install the developer tooling, configure Salesforce MCP servers, and explore the available server capabilities.

- **[Salesforce Developer Plugin](https://developer.salesforce.com/blogs/2026/08/headless-development-with-skills-and-a-claude-code-plugin)**  
  Learn how to use Salesforce Skills and the Claude Code plugin for headless development.

- **[Salesforce Hosted MCP Servers Get Started](https://developer.salesforce.com/docs/platform/hosted-mcp-servers/guide)**  
  Follow the official setup guide for Salesforce Hosted MCP Servers.

- **[Salesforce Provided MCP Servers](https://developer.salesforce.com/docs/platform/hosted-mcp-servers/guide/servers-reference.html)**  
  Review the available Salesforce-provided MCP servers and their capabilities.

---

## Welcome

AI agents are most useful when they understand the real context of your Salesforce org. In this session, we explored how trusted metadata context helps coding agents discover what exists, understand dependencies, take action safely, and verify the result.

The goal is not simply to replace clicks or generate code faster. It is to help admins and developers move from a business outcome to a trusted result while keeping a human in control of important decisions.

> **Coming soon:** Session slides, demo assets, prompts, and recording.

---

## What we demonstrated

### Admin scenario  Employee offboarding

Sarah is leaving Pronto. The admin needs to onboard her replacement, Marcus, transfer her work and responsibilities, and safely deactivate her account.

Using natural language from Claude Desktop, the agent:

- Investigated Sarah's access, permission sets, groups, queues, role, and owned records.
- Checked related approvals, flows, sharing rules, scheduled jobs, Omni-Channel configuration, dashboards, reports, and other dependencies.
- Examined 11 areas of the org without navigating Salesforce Setup screens.
- Uncovered existing issues that were not part of the original request.
- Paused for human review and confirmation before important changes.
- Created and configured Marcus, transferred all 78 records, removed Sarah's access, and safely deactivated her.
- Verified the final result.

#### What the admin demo proved

1. **Accelerate time to value**  
   Turn a multi-step request into a completed outcome faster. In the demo, one conversation orchestrated the workflow with zero Setup screens.

2. **Find what else matters**  
   Use live org context to surface related access, data, automation, and dependencies before they become problems.

3. **Act with confidence**  
   Ground each change in the current org, explain the plan, ask for confirmation, and verify the result before moving forward.

### Developer scenario  Bug investigation and fixing

A developer receives a short bug ticket: selecting a category on Pronto's menu page no longer filters the menu after the page loads.

The developer starts with:

- Only the business symptom.
- No component name.
- No detailed reproduction steps.
- An empty local project with nothing to search.

Using Claude Code and trusted org context, the developer can begin with the symptom, locate the relevant metadata and code, understand the surrounding dependencies, investigate the root cause, implement a fix, and verify the result.

---

## Core principles

### Direct the outcome

Describe what must happen in plain English instead of manually specifying every Setup screen, object, field, or implementation step.

### Ground every decision

Use live Salesforce metadata and org context instead of relying only on generic assumptions. Inspect the real access model, automation, code, relationships, and dependencies before acting.

### Keep the human in the loop

The agent can investigate, recommend, coordinate, and verify, but the human remains responsible for validating the information and approving important decisions and changes.

### Verify the result

Do not stop when an action reports success. Confirm that access, records, metadata, code, and expected behavior match the intended outcome.

---

## Use AI across the software development lifecycle

AI can support more than code generation:

- **Discover:** Ask the org what already exists, understand the business context, and identify reuse opportunities.
- **Design:** Compare approaches, trace dependencies, evaluate tradeoffs, and document the decision.
- **Implement:** Build faster while following Salesforce best practices and team-agreed patterns.
- **Review:** Challenge the implementation or design against the original requirements and identify gaps.
- **Test:** Generate unit tests and support regression testing across related functionality.
- **Document:** Create useful code comments, ticket documentation, release notes, screenshots, and recorded walkthroughs.

AI can help us think and work faster, but it remains our responsibility to validate its output and make the final decision.

---

## Code With Sally

**Code With Sally** is a free Salesforce learning initiative founded by Sally ElGhoul. It shares practical technical sessions, demos, and learning resources in English and Arabic to help Salesforce professionals learn and grow.

- **YouTube:** [youtube.com/@CodeWithSally](https://www.youtube.com/@CodeWithSally)
- **Website:** [codewithsally.com](https://codewithsally.com/)
- **WhatsApp community:** [Join the community](https://chat.whatsapp.com/EDfyHKY9eO53uzqqyMulhP?mode=gi_t)
- **Slack community:** [Join the workspace](https://join.slack.com/t/codewithsally/shared_invite/zt-1u7djwtms-F~9c67~XDxI3B3a~KRJcoQ)
- **LinkedIn page:** [Code With Sally](https://www.linkedin.com/company/codewithsally/)
- **Sally ElGhoul:** [LinkedIn](https://www.linkedin.com/in/sallyelghoul/)
- **Trailblazer Community Group:** [Join the group](https://trailhead.salesforce.com/trailblazer-community/groups/0F9KX000000irsF0AQ)

---

<p align="center">
  <em>Start with the outcome. Ground every decision. Keep the human in control.</em>
</p>

<p align="center">
  Made with 💙 by <strong>Code With Sally</strong>
</p>
