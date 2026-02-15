---
description: Implement a Linear ticket following the full workflow
---

Parse the input: `$ARGUMENTS`
- The first word is the **ticket ID** (e.g., `STU-15`)
- Everything after is **additional context** from the user (optional, e.g., "this needs extensive research", "focus on performance", "skip tests for now")

You are implementing the ticket. If additional context was provided, adjust your approach accordingly.

> **CRITICAL: Context Compaction Safety**
> The progress document contains a **Workflow Checklist** that tracks completion of all phases.
> After ANY interruption or context compaction, ALWAYS read the progress document first and
> continue from where the checklist indicates. The workflow is NOT complete until all phases
> (Implementation → Learnings → Push & PR) are checked off.

Follow these steps:

## Before Cooking

1. Move the ticket to "In Progress" status using Linear MCP
2. Read the full ticket details from Linear, including research and planning comments
3. **Check the pantry for learnings**: If `docs/learnings/` exists, scan all files for learnings relevant to this ticket's domain. Keep these in mind during implementation.

**House Rules Gate (always):**
- Check if `.opencode/HOUSE_RULES.md` exists.
- If it exists, read it before writing code and treat it as binding for implementation choices, testing, and PR scope.
- Track any required exception explicitly in progress documentation.

4. Ask clarifying questions if anything is unclear before starting
5. Use the `git-branch-create` skill to resolve a properly named ticket branch
6. Use the `git-worktree-prepare` skill to create or reuse a dedicated worktree for that branch
   - Worktree behavior is **default-on** for `/bbq.fire`
   - Use the worktree base path resolved by `git-worktree-prepare` (sidecar override when present)
   - Capture outputs as `branch_name` and `worktree_path`
7. From this point forward, run **all git, code, test, and documentation actions in that worktree path**
   - Prefer explicit path-aware commands (`git -C "{worktree_path}" ...`) when possible
   - Do not rely on current working directory after worktree creation
8. Use the `git-push-remote` skill with explicit inputs `worktree_path` and `branch_name`

## Fire the Grill (Phase 1: Implementation)

9. Begin implementation:
   a. Use the progress-doc skill in `worktree_path` to create the progress document (includes Workflow Checklist)
   b. Write or modify unit tests first (TDD approach)
   c. If there are API changes, write integration tests
   d. Implement the changes according to the plan and House Rules
   e. Update progress documentation as you go, including House Rules compliance notes and worktree context
   f. Use the git-commit skill from `worktree_path` to commit changes as you go and finish the tasks from progress document
10. After implementation is complete, the validate-changes plugin will automatically run lint, build, and tests
11. Use the git-commit skill from `worktree_path` to commit changes with proper message format
12. **Update the Workflow Checklist**: Mark "Phase 1: Implementation" items as complete in the progress doc

Ensure all tests pass before proceeding.

## Write Down What You Learned (Phase 2: Learnings)

13. **Extract learnings** from this implementation session — but only if something technically relevant was learned:
    - A surprising API behavior or gotcha worth remembering
    - A workaround for a bug or limitation
    - A pattern that should be followed in the future
    - An architectural decision with non-obvious rationale
    
    Skip this step if the work was routine and nothing noteworthy emerged.
    
14. For each learning worth documenting:
    - Categorize it (gotcha, pattern, decision, or discovery)
    - Create `docs/learnings/` directory if it doesn't exist
    - Append the learning to the appropriate file with ticket ID and date using the `learnings` skill
    - **Commit any new learnings** using the git-commit skill from `worktree_path`
    
15. Summarize what was documented:
    ```
    Documented X learnings:
    - gotchas.md: "Title"
    - patterns.md: "Title"
    ```
    
    If nothing noteworthy was learned, say so briefly and move on.

16. **Update the Workflow Checklist**: Mark "Phase 2: Learnings" items as complete in the progress doc

## Push and Create PR (Phase 3: Finalize - FINAL STEP)

**IMPORTANT: Only proceed with this section AFTER all implementation, testing, documentation, and learnings are complete. Do NOT push or create a PR until everything else is finished.**

17. **Finalize progress documentation**: Update the progress document with:
    - Status changed to "Complete"
    - Final progress log entry summarizing what was accomplished
    - All task checkboxes updated
    - Complete list of files changed
    - House Rules compliance status and approved exceptions (if any)
    - Worktree path used for implementation
    - **Commit this update** using the git-commit skill from `worktree_path` before proceeding
18. Use the git-push-remote skill with explicit `worktree_path` and `branch_name` to push all commits to remote
19. Create a pull request using GitHub MCP with:
    - Clear title referencing the ticket
    - Description summarizing changes
    - House Rules compliance summary (or approved exception notes)
    - Worktree context note (path or "resolved worktree layout")
    - Link to the Linear ticket
20. Move the ticket to "In Review" status using Linear MCP
21. **Update the Workflow Checklist**: Mark "Phase 3: Finalize & Push" items as complete

**Do NOT make any additional commits after pushing. If you discover something needs to change, do it BEFORE this step.**

> **REMINDER**: The workflow is complete ONLY when all three phases in the Workflow Checklist are fully checked off.
