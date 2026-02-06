---
description: Research a Linear ticket and document findings
---

Parse the input: `$ARGUMENTS`
- The first word is the **ticket ID** (e.g., `STU-15`)
- Everything after is **additional context** from the user (optional, e.g., areas to focus on, specific concerns)

You are researching the ticket. If additional context was provided, incorporate it into your research focus.

Follow these steps:

1. Read the full ticket details from Linear using Linear MCP
2. **Check the ticket description** for an existing "Research" section (look for `---` horizontal rule followed by `## Research`)

### If NO existing research section exists in the description:

3. Move the ticket to "In Research" status using Linear MCP
4. **Check existing learnings**: If `docs/learnings/` exists, scan all files for learnings relevant to this ticket's domain. These may inform your research and save time.
5. Research the codebase to understand the best approach for implementing this ticket
6. Ask clarifying questions if you need more information about:
   - Requirements or acceptance criteria
   - Technical constraints or preferences
   - Priority or timeline considerations
7. **Update the ticket description** by appending a research section at the end:
   ```markdown
   ---

   ## Research

   **Status:** Researched on YYYY-MM-DD

   ### Current State
   [Summary of the current state]

   ### Proposed Approach
   [Proposed approach(es)]

   ### Risks & Considerations
   [Potential risks or considerations]

   ### Dependencies
   [Any dependencies identified]

   ### Relevant Learnings
   [Learnings from docs/learnings/ if any apply, or "None identified"]
   ```
8. Move the ticket to "Ready to Plan" status using Linear MCP

### If an existing research section exists in the description:

3. Read any unresolved comments on the ticket — these may contain user feedback on the research
4. Analyze the feedback to understand what needs to be adjusted
5. Do additional research if the feedback requires it
6. **Update the research section in the ticket description** to address the feedback:
   - Revise approaches based on feedback
   - Add missing information that was requested
   - Clarify points that were unclear
   - Remove or adjust rejected approaches
   - Update the "Status" date to reflect the revision
7. If status is not already "Ready to Plan", move it there using Linear MCP

Be thorough but concise in your research documentation. Preserve the original ticket description content above the research section.
