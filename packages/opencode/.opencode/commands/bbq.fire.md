---
description: Implement a Linear ticket following the full workflow
---

Parse the input: `$ARGUMENTS`
- The first word is the **ticket ID** (e.g., `STU-15`)
- Everything after is **additional context** from the user (optional, e.g., "this needs extensive research", "focus on performance", "skip tests for now")

You are implementing the ticket. If additional context was provided, adjust your approach accordingly.

Follow these steps:

## Before Cooking

1. Move the ticket to "In Progress" status using Linear MCP
2. Read the full ticket details from Linear, including research and planning comments
3. **Check the pantry for learnings**: If `docs/learnings/` exists, scan all files for learnings relevant to this ticket's domain. Keep these in mind during implementation.
4. Ask clarifying questions if anything is unclear before starting
5. Use the git-branch-create skill to create a properly named branch
6. Use the git-push-remote skill to push the empty branch to remote

## Fire the Grill

7. Begin implementation:
   a. Use the progress-doc skill to document your progress
   b. Write or modify unit tests first (TDD approach)
   c. If there are API changes, write integration tests
   d. Implement the changes according to the plan
   e. Update progress documentation as you go
8. After implementation is complete, the validate-changes plugin will automatically run lint, build, and tests
9. Use the git-commit skill to commit changes with proper message format
10. Use the git-push-remote skill to push commits to remote
11. Create a pull request using GitHub MCP with:
    - Clear title referencing the ticket
    - Description summarizing changes
    - Link to the Linear ticket
12. Move the ticket to "In Review" status using Linear MCP

Ensure all tests pass before creating the PR.

## Write Down What You Learned

13. **Extract learnings** from this implementation session using the `learnings` skill:
    - What was surprising or unexpected?
    - What workarounds were needed?
    - What patterns were followed or established?
    - What decisions were made and why?
    
14. For each learning:
    - Categorize it (gotcha, pattern, decision, or discovery)
    - Create `docs/learnings/` directory if it doesn't exist
    - Append the learning to the appropriate file with ticket ID and date
    
15. Summarize what was documented:
    ```
    Documented X learnings:
    - gotchas.md: "Title"
    - patterns.md: "Title"
    ```
    
    If nothing noteworthy was learned, that's fine — say so.
