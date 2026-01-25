---
description: Research a Linear ticket and document findings
---

Parse the input: `$ARGUMENTS`
- The first word is the **ticket ID** (e.g., `STU-15`)
- Everything after is **additional context** from the user (optional, e.g., areas to focus on, specific concerns)

You are researching the ticket. If additional context was provided, incorporate it into your research focus.

Follow these steps:

1. Move the ticket to "In Research" status using Linear MCP
2. Read the full ticket details from Linear using Linear MCP
3. **Check existing learnings**: If `docs/learnings/` exists, scan all files for learnings relevant to this ticket's domain. These may inform your research and save time.
4. Research the codebase to understand the best approach for implementing this ticket
5. Ask clarifying questions if you need more information about:
   - Requirements or acceptance criteria
   - Technical constraints or preferences
   - Priority or timeline considerations
6. Document your research findings as a comment on the ticket in Linear, including:
   - Summary of the current state
   - Proposed approach(es)
   - Potential risks or considerations
   - Any dependencies identified
   - **Relevant learnings** from `docs/learnings/` if any apply
7. Move the ticket to "Ready to Plan" status using Linear MCP

Be thorough but concise in your research documentation.
