---
description: Address PR review comments for a Linear ticket
---

Parse the input: `$ARGUMENTS`
- The first word is the **ticket ID** (e.g., `STU-15`)
- Everything after is **additional context** from the user (optional, e.g., specific comments to focus on)

You are addressing review comments for the ticket. If additional context was provided, prioritize accordingly.

Follow these steps:

1. Use the git-find-ticket-branch skill to find the branch for this ticket
2. Check out the branch
3. Pull the latest changes and resolve any conflicts (ask for help if conflicts are complex)
4. Read all review comments from the pull request using GitHub MCP
5. For each review comment:
   a. Understand the feedback
   b. Make the necessary changes
   c. Create a focused commit addressing that specific comment using the git-commit skill
   d. Resolve that comment in GitHub using GitHub MCP once the change is in place
6. Use the git-push-remote skill to push all commits
7. Add a summary comment to the PR using GitHub MCP explaining:
   - What changes were made
   - How each comment was addressed
   - Any items that need further discussion

Be thorough in addressing feedback and clear in your responses.
