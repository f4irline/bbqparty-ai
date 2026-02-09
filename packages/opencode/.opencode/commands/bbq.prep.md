---
description: Create a technical implementation plan for a Linear ticket
---

Parse the input: `$ARGUMENTS`
- The first word is the **ticket ID** (e.g., `STU-15`)
- Everything after is **additional context** from the user (optional, e.g., constraints, preferences, scope notes)

You are planning the technical implementation for the ticket. If additional context was provided, factor it into your planning.

Before planning, check if `.opencode/HOUSE_RULES.md` exists:
- If it exists, read it first and treat it as mandatory constraints.
- Use it to shape the design, test strategy, and governance notes.
- If it does not exist, continue with the default planning workflow.

Follow these steps:

1. Read the full ticket details from Linear using Linear MCP
2. **Check the ticket description** for an existing "Technical Plan" section (look for `---` horizontal rule followed by `## Technical Plan`)

### If NO existing plan section exists in the description:

3. Move the ticket to "Planning" status using Linear MCP
4. Read the Research section in the ticket description (if present) to understand the proposed approach
5. **Check existing learnings**: If `docs/learnings/` exists, scan all files for learnings relevant to this ticket's domain. Incorporate relevant gotchas, patterns, and decisions into your plan.
6. Create a detailed technical plan covering:
   - Files to be modified or created
   - API changes (if any)
   - Database/schema changes (if any)
   - Infra changes (if any)
   - House Rules constraints and any required exception approvals
   - Local development considerations (env vars, services, seeds, scripts)
   - Test strategy (unit tests, integration tests)
   - Potential breaking changes
   - **Relevant learnings** to keep in mind during implementation
7. Ask clarifying questions if you need decisions on:
   - Architecture choices
   - Implementation trade-offs
   - Scope clarifications
8. **Update the ticket description** by appending a plan section at the end:
   ```markdown
   ---

   ## Technical Plan

   **Status:** Planned on YYYY-MM-DD

   ### Files to Modify/Create
   - [ ] `path/to/file.ts` — description of changes
   - [ ] `path/to/new-file.ts` — new file for X

   ### API Changes
   [Describe API changes or "None"]

   ### Database/Schema Changes
   [Describe changes or "None"]

   ### Infra/Terraform Changes
   [Describe changes or "None"]

   ### Documentation to Update
   Describe changes or "None"

   ### Local Development Considerations
   [Env vars, local services, fixtures/seeds, scripts, or "None"]

   ### Test Strategy
   - Unit tests: [what to test]
   - Integration tests: [what to test]

   ### Breaking Changes
   [List any breaking changes or "None"]

   ### House Rules Alignment
   [How this plan follows `.opencode/HOUSE_RULES.md`, required exceptions with rationale, or "No HOUSE_RULES file found"]

   ### Learnings to Apply
   [Relevant learnings from docs/learnings/ or "None identified"]
   ```
9. Move the ticket to "Ready" status using Linear MCP

### If an existing plan section exists in the description:

3. Read any unresolved comments on the ticket — these may contain user feedback on the plan
4. Analyze the feedback to understand what needs to be adjusted
5. Do additional research if the feedback requires changes to the approach
6. **Update the plan section in the ticket description** to address the feedback:
   - Revise the approach based on feedback
   - Add missing details that were requested
   - Clarify points that were unclear
   - Adjust scope, files, or strategy as directed
   - Re-check House Rules alignment and update exceptions/approvals if needed
   - Update the "Status" date to reflect the revision
7. If status is not already "Ready", move it there using Linear MCP

Be specific about what will change and how. Preserve the original ticket description and research section above the plan.
