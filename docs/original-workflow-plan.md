# AI Workflow

1. Open OpenCode
2. Call custom command: /research STU-15 {might give some additional information here}
    1. Agent moves the ticket to "In Research" status using Linear MCP
    2. Reads STU-15 from Linear using Linear MCP
    3. Does research to find out the best approach - Asks questions/direction/clarifications if needed
    4. Documents the research results to the ticket in Linear using Linear MCP
    5. Moves to ticket to "Ready to Plan" status using Linear MCP
3. Call custom command: /plan STU-15 {might give some additional information here}
    1. Agent moves the ticket to "Planning" using Linear MCP
    2. Reads STU-15 from Linear using Linear MCP
    3. Plans the technical details - Asks questions/directions/clarifications if needed
    4. Documents the plan to the ticket using Linear MCP
    5. Moves the ticket to "Ready" status using Linear MCP
4. Call custom command: /implement STU-15 {might give some additional information here}
    1. Agent moves the ticket to "In Progress" using Linear MCP
    2. Reads STU-15 from Linear using Linear MCP
    3. Asks for questions/directions/clarifications if needed
    4. Comes up with a branch name from the ticket details and creates a branch with format {type, e.g. feat}/{ticket id, e.g. STU-15}-short-branch-name
        - This can be a skill
    5. Pushes the new branch to remote before it starts implementation
        - This can be a new skill
    6. Starts the implementation
        1. Documents the progress to `docs/progress/{branch-name}.md`
        2. Creates minimal set of unit tests first, or modifies existing ones
        3. If there are new APIs or changes to existing APIs, creates integration tests
        4. Implements the specified changes
    7. After finishing the implementation, runs lint, build and tests (or `terraform validate` and `terraform plan` in case of infra/ changes)
        - Only for the changed component (mobile/ or api/)
        - This can be a new hook (OpenCode plugin)
    8. Commits the changes
        - This can be a skill
    9. Pushes the branch to remote using the same skill used in step 5
    10. Creates a pull request to GitHub using GitHub component
    11. Moves the ticket to "In Review" status using Linear MCP
5. Call custom command: /review STU-15
    1. Agent finds the branch with the STU-15 prefix (e.g. feat/STU-15-some-feature)
        - This can be a skill
    2. Agent switches or checks out the branch
    3. Agent pulls the latest changes and resolves any conflicts
    4. Agent checks the review comments from the pull request related to the branch using GitHub MCP
    5. Agent validates the comments, and does fixes/changes according to the comments - creating a commit per comment
    6. Agent pushes commits to remote (using the skill)
    7. Agent summaries the changes to a comment in to the pull request using GitHub MCP
