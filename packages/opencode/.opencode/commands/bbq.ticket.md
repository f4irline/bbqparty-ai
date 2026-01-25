---
description: Show current status of a Linear ticket across Linear and GitHub
---

Parse the input: `$ARGUMENTS`
- The first word is the **ticket ID** (e.g., `STU-15`)
- Everything after is **additional context** from the user (optional)

Show the current status of the ticket across all systems. If additional context was provided, keep it in mind.

Gather and display:

1. From Linear MCP:
   - Ticket title and description
   - Current status
   - Assignee
   - Priority
   - Recent comments/updates
2. From Git:
   - Use git-find-ticket-branch skill to find related branch(es)
   - Show branch status (ahead/behind main)
   - Recent commits on the branch
3. From GitHub MCP:
   - Find any PRs related to this ticket
   - PR status (open, merged, closed)
   - Review status (approved, changes requested, pending)
   - Open comments count

Present a clear summary of where this ticket stands in the workflow.
