---
description: Create a technical implementation plan for a Linear ticket
---

Parse the input: `$ARGUMENTS`
- The first word is the **ticket ID** (e.g., `STU-15`)
- Everything after is **additional context** from the user (optional, e.g., constraints, preferences, scope notes)

You are planning the technical implementation for the ticket. If additional context was provided, factor it into your planning.

Follow these steps:

1. Move the ticket to "Planning" status using Linear MCP
2. Read the full ticket details from Linear, including any research comments
3. **Check existing learnings**: If `docs/learnings/` exists, scan all files for learnings relevant to this ticket's domain. Incorporate relevant gotchas, patterns, and decisions into your plan.
4. Create a detailed technical plan covering:
   - Files to be modified or created
   - API changes (if any)
   - Database/schema changes (if any)
   - Test strategy (unit tests, integration tests)
   - Potential breaking changes
   - **Relevant learnings** to keep in mind during implementation
5. Ask clarifying questions if you need decisions on:
   - Architecture choices
   - Implementation trade-offs
   - Scope clarifications
6. Document the technical plan as a comment on the ticket in Linear
7. Move the ticket to "Ready" status using Linear MCP

Be specific about what will change and how.
