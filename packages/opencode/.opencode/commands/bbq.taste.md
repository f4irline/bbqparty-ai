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

## Write Down What You Learned

8. **Extract learnings** from addressing these review comments — but only if something technically relevant was learned:
   - A surprising API behavior or gotcha worth remembering
   - A workaround for a bug or limitation
   - A pattern that should be followed in the future
   - An architectural decision with non-obvious rationale
   
   Skip this step if the changes were straightforward and nothing noteworthy emerged.
   
9. For each learning worth documenting:
   - Categorize it (gotcha, pattern, decision, or discovery)
   - Create `docs/learnings/` directory if it doesn't exist
   - Append the learning to the appropriate file with ticket ID and date using the `learnings` skill
   
10. Summarize what was documented:
    ```
    Documented X learnings:
    - gotchas.md: "Title"
    - patterns.md: "Title"
    ```
    
    If nothing noteworthy was learned, say so briefly and move on.

Be thorough in addressing feedback and clear in your responses.
