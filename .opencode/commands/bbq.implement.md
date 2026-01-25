---
description: Implement a Linear ticket following the full workflow
---

You are implementing Linear ticket $ARGUMENTS.

Follow these steps:

1. Move the ticket to "In Progress" status using Linear MCP
2. Read the full ticket details from Linear, including research and planning comments
3. Ask clarifying questions if anything is unclear before starting
4. Use the git-branch-create skill to create a properly named branch
5. Use the git-push-remote skill to push the empty branch to remote
6. Begin implementation:
   a. Use the progress-doc skill to document your progress
   b. Write or modify unit tests first (TDD approach)
   c. If there are API changes, write integration tests
   d. Implement the changes according to the plan
   e. Update progress documentation as you go
7. After implementation is complete, the validate-changes plugin will automatically run lint, build, and tests
8. Use the git-commit skill to commit changes with proper message format
9. Use the git-push-remote skill to push commits to remote
10. Create a pull request using GitHub MCP with:
    - Clear title referencing the ticket
    - Description summarizing changes
    - Link to the Linear ticket
11. Move the ticket to "In Review" status using Linear MCP

Ensure all tests pass before creating the PR.
