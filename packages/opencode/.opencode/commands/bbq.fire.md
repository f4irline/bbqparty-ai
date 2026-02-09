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
5. Use the git-branch-create skill to create a properly named branch
6. Use the git-push-remote skill to push the empty branch to remote

## Fire the Grill (Phase 1: Implementation)

7. Begin implementation:
   a. Use the progress-doc skill to create the progress document (includes Workflow Checklist)
   b. Write or modify unit tests first (TDD approach)
   c. If there are API changes, write integration tests
   d. Implement the changes according to the plan and House Rules
   e. Update progress documentation as you go, including House Rules compliance notes
   f. Use the git-commit skill to commit changes as you go and finish the tasks from progress document
8. After implementation is complete, the validate-changes plugin will automatically run lint, build, and tests
9. Use the git-commit skill to commit changes with proper message format
10. **Update the Workflow Checklist**: Mark "Phase 1: Implementation" items as complete in the progress doc

Ensure all tests pass before proceeding.

## Write Down What You Learned (Phase 2: Learnings)

11. **Extract learnings** from this implementation session — but only if something technically relevant was learned:
    - A surprising API behavior or gotcha worth remembering
    - A workaround for a bug or limitation
    - A pattern that should be followed in the future
    - An architectural decision with non-obvious rationale
    
    Skip this step if the work was routine and nothing noteworthy emerged.
    
12. For each learning worth documenting:
    - Categorize it (gotcha, pattern, decision, or discovery)
    - Create `docs/learnings/` directory if it doesn't exist
    - Append the learning to the appropriate file with ticket ID and date using the `learnings` skill
    - **Commit any new learnings** using the git-commit skill
    
13. Summarize what was documented:
    ```
    Documented X learnings:
    - gotchas.md: "Title"
    - patterns.md: "Title"
    ```
    
    If nothing noteworthy was learned, say so briefly and move on.

14. **Update the Workflow Checklist**: Mark "Phase 2: Learnings" items as complete in the progress doc

## Push and Create PR (Phase 3: Finalize - FINAL STEP)

**IMPORTANT: Only proceed with this section AFTER all implementation, testing, documentation, and learnings are complete. Do NOT push or create a PR until everything else is finished.**

15. **Finalize progress documentation**: Update the progress document with:
    - Status changed to "Complete"
    - Final progress log entry summarizing what was accomplished
    - All task checkboxes updated
    - Complete list of files changed
    - House Rules compliance status and approved exceptions (if any)
    - **Commit this update** using the git-commit skill before proceeding
16. Use the git-push-remote skill to push all commits to remote
17. Create a pull request using GitHub MCP with:
    - Clear title referencing the ticket
    - Description summarizing changes
    - House Rules compliance summary (or approved exception notes)
    - Link to the Linear ticket
18. Move the ticket to "In Review" status using Linear MCP
19. **Update the Workflow Checklist**: Mark "Phase 3: Finalize & Push" items as complete

**Do NOT make any additional commits after pushing. If you discover something needs to change, do it BEFORE this step.**

> **REMINDER**: The workflow is complete ONLY when all three phases in the Workflow Checklist are fully checked off.
