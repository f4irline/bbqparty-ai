---
description: Create a technical implementation plan for a Linear ticket
---

Parse the input: `$ARGUMENTS`
- The first word is the **ticket ID** (e.g., `STU-15`)
- Everything after is **additional context** from the user (optional, e.g., constraints, preferences, scope notes)

You are planning the technical implementation for the ticket. If additional context was provided, factor it into your planning.

Follow these steps:

1. Read the full ticket details and all comments from Linear using Linear MCP
2. **Check for existing plan**: Look for a comment that contains a technical plan (typically marked with a heading like "## Technical Plan" or similar structure with files to modify, test strategy, etc.)

### If NO existing plan comment exists:

3. Move the ticket to "Planning" status using Linear MCP
4. Read any research comments to understand the proposed approach
5. **Check existing learnings**: If `docs/learnings/` exists, scan all files for learnings relevant to this ticket's domain. Incorporate relevant gotchas, patterns, and decisions into your plan.
6. Create a detailed technical plan covering:
   - Files to be modified or created
   - API changes (if any)
   - Database/schema changes (if any)
   - Test strategy (unit tests, integration tests)
   - Potential breaking changes
   - **Relevant learnings** to keep in mind during implementation
7. Ask clarifying questions if you need decisions on:
   - Architecture choices
   - Implementation trade-offs
   - Scope clarifications
8. Document the technical plan as a **new comment** on the ticket in Linear
9. Move the ticket to "Ready" status using Linear MCP

### If an existing plan comment exists:

3. Read all comments that came **after** the plan comment — these contain user feedback
4. Analyze the feedback to understand what needs to be adjusted
5. Do additional research if the feedback requires changes to the approach
6. **Update the existing plan comment** (edit, don't create a new one) to address the feedback:
   - Revise the approach based on feedback
   - Add missing details that were requested
   - Clarify points that were unclear
   - Adjust scope, files, or strategy as directed
7. If status is not already "Ready", move it there using Linear MCP

Be specific about what will change and how.
