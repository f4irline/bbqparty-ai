---
description: Research a Linear ticket and document findings
---

Parse the input: `$ARGUMENTS`
- The first word is the **ticket ID** (e.g., `STU-15`)
- Everything after is **additional context** from the user (optional, e.g., areas to focus on, specific concerns)

You are researching the ticket. If additional context was provided, incorporate it into your research focus.

Follow these steps:

1. Read the full ticket details and all comments from Linear using Linear MCP
2. **Check for existing research**: Look for a comment that contains research findings (typically marked with a heading like "## Research" or similar structure with proposed approaches)

### If NO existing research comment exists:

3. Move the ticket to "In Research" status using Linear MCP
4. **Check existing learnings**: If `docs/learnings/` exists, scan all files for learnings relevant to this ticket's domain. These may inform your research and save time.
5. Research the codebase to understand the best approach for implementing this ticket
6. Ask clarifying questions if you need more information about:
   - Requirements or acceptance criteria
   - Technical constraints or preferences
   - Priority or timeline considerations
7. Document your research findings as a **new comment** on the ticket in Linear, including:
   - Summary of the current state
   - Proposed approach(es)
   - Potential risks or considerations
   - Any dependencies identified
   - **Relevant learnings** from `docs/learnings/` if any apply
8. Move the ticket to "Ready to Plan" status using Linear MCP

### If an existing research comment exists:

3. Read all comments that came **after** the research comment — these contain user feedback
4. Analyze the feedback to understand what needs to be adjusted
5. Do additional research if the feedback requires it
6. **Update the existing research comment** (edit, don't create a new one) to address the feedback:
   - Revise approaches based on feedback
   - Add missing information that was requested
   - Clarify points that were unclear
   - Remove or adjust rejected approaches
7. If status is not already "Ready to Plan", move it there using Linear MCP

Be thorough but concise in your research documentation.
