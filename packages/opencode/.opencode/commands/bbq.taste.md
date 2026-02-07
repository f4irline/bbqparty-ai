---
description: Address PR review comments for a Linear ticket
---

Parse the input: `$ARGUMENTS`
- The first word is the **ticket ID** (e.g., `STU-15`)
- Everything after is **additional context** from the user (optional, e.g., specific comments to focus on)

You are addressing review comments for the ticket. If additional context was provided, prioritize accordingly.

> **CRITICAL: Context Compaction Safety**
> If a progress document exists for this branch, it contains a **Workflow Checklist** that tracks completion.
> After ANY interruption or context compaction, ALWAYS read the progress document first and
> continue from where the checklist indicates. The workflow is NOT complete until all phases are checked off.

Follow these steps:

## Setup

1. Use the git-find-ticket-branch skill to find the branch for this ticket
2. Check out the branch
3. Pull the latest changes and resolve any conflicts (ask for help if conflicts are complex)
4. **Check for existing progress doc** at `docs/progress/{branch-name}.md`
   - If it exists, read it and check the Workflow Checklist for current status
   - If not, create one using the progress-doc skill with a review-specific workflow checklist (see below)

## Address Review Comments (Phase 1: Implementation)

5. Use the `github-pr-feedback` skill to fetch unresolved review threads and PR conversation comments for this branch's pull request
6. For each unresolved review comment/thread:
   a. Understand the feedback
   b. Make the necessary changes
   c. Create a focused commit addressing that specific comment using the git-commit skill
   d. Resolve that comment in GitHub using GitHub MCP once the change is in place
7. **Update the Workflow Checklist**: Mark "Phase 1: Implementation" items as complete

## Write Down What You Learned (Phase 2: Learnings)

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
   - **Commit any new learnings** using the git-commit skill
   
10. Summarize what was documented:
    ```
    Documented X learnings:
    - gotchas.md: "Title"
    - patterns.md: "Title"
    ```
    
    If nothing noteworthy was learned, say so briefly and move on.

11. **Update the Workflow Checklist**: Mark "Phase 2: Learnings" items as complete

## Push Changes (Phase 3: Finalize - FINAL STEP)

**IMPORTANT: Only proceed with this section AFTER all changes, documentation, and learnings are complete. Do NOT push until everything else is finished.**

12. Use the git-push-remote skill to push all commits to remote
13. Add a summary comment to the PR using GitHub MCP explaining:
    - What changes were made
    - How each comment was addressed
    - Any items that need further discussion
14. **Update the Workflow Checklist**: Mark "Phase 3: Finalize & Push" items as complete

**Do NOT make any additional commits after pushing. If you discover something needs to change, do it BEFORE this step.**

> **REMINDER**: The workflow is complete ONLY when all three phases in the Workflow Checklist are fully checked off.

Be thorough in addressing feedback and clear in your responses.

---

## Review Workflow Checklist Template

When creating a progress doc for review work, use this checklist instead of the default:

```markdown
## Workflow Checklist

> **IMPORTANT**: This checklist ensures all workflow steps are completed, even after context compaction.
> Check off each phase as you complete it. After ANY interruption, read this section first.

### Phase 1: Address Review Comments
- [ ] Fetch PR feedback (unresolved threads + comments) — use `github-pr-feedback` skill
- [ ] Make changes for each comment
- [ ] Commit changes — use `git-commit` skill
- [ ] Resolve comments in GitHub — use GitHub MCP

### Phase 2: Learnings
- [ ] Extract learnings (or note: nothing noteworthy)
- [ ] Document learnings if any — use `learnings` skill
- [ ] Commit learnings if any — use `git-commit` skill

### Phase 3: Finalize & Push (DO NOT SKIP)
- [ ] Push all commits to remote — use `git-push-remote` skill
- [ ] Add summary comment to PR — use GitHub MCP
```
