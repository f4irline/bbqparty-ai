---
description: Show current status of a Linear ticket across Linear and GitHub
---

Parse the input: `$ARGUMENTS`
- The first word is the **ticket ID** (e.g., `STU-15`)
- Everything after is **additional context** from the user (optional)

Show the current status of the ticket across all systems. If additional context was provided, keep it in mind.

Before gathering status, use the Read tool directly on `.opencode/HOUSE_RULES.md`:
- Do not use Glob, Grep, or directory listing to locate or test this known path.
- Treat the loaded rules as governing guidance for this workflow.
- Use them to flag any obvious compliance risks or required exceptions visible from ticket, branch, or PR context.
- If the direct read fails, stop and report the read error.

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
4. For House Rules:
   - Include a brief compliance snapshot
   - Call out any item that appears to need an exception or governance review

Present a clear summary of where this ticket stands in the workflow, including House Rules compliance signals.
