---
description: Address PR review comments for a Linear ticket
agent: pitmaster
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

1. Use the git-find-ticket-branch skill to find the branch for this ticket.
2. Resolve the worktree provider after resolving `repo_root`, `branch_name`, and the remote default branch:
    - Read `.opencode/bbq-config.json` with `jq`. A missing file means `runtime == "native"`. Invalid JSON or any runtime other than `native` or `herdr` is an actionable error; do not guess a provider.
    - Use Herdr only when `runtime == "herdr"` **and** `HERDR_ENV=1`. In that case explicitly load and follow the installed `herdr` skill before running its CLI commands.
    - With active Herdr, run `herdr worktree list --cwd "{repo-root}"` and inspect its JSON `.result.worktrees` for the matching branch.
    - If the matching checkout has no `open_workspace_id`, run `herdr worktree open --cwd "{repo-root}" --branch "{branch-name}" --label "{ticket-id}" --no-focus` and retain `.result.workspace.workspace_id` as metadata only.
    - If no checkout exists, use the deterministic absolute `.opencode/.bbq-worktrees/{branch-slug}` path. Use `origin/{branch-name}` as the base when only a remote ticket branch exists; otherwise use the resolved remote default branch. Run `herdr worktree create --cwd "{repo-root}" --branch "{branch-name}" --base "{base-ref}" --path "{worktree-path}" --label "{ticket-id}" --no-focus`.
    - Parse the authoritative checkout path from `.result.worktree.path` or its matching `.result.worktrees` entry, never from `.result.workspace.workspace_id`.
    - If Herdr is configured but `HERDR_ENV=1` is absent, state that native fallback is active and use `git-worktree-find`. It may call the native fallback `git-worktree-prepare` skill when the checkout is missing.
    - Under either provider, run `"{repo-root}/.opencode/scripts/sync-worktree-local-files.sh" "{repo-root}" "{worktree-path}"` after resolving the path. Capture outputs as `branch_name` and `worktree_path`.
3. From this point forward, run all git/code actions in the resolved worktree path
   - Prefer explicit path-aware commands (`git -C "{worktree_path}" ...`) when possible
   - Do not rely on current working directory after worktree resolution
4. Pull the latest changes in that worktree and resolve any conflicts (ask for help if conflicts are complex)
5. **Check for existing progress doc** at `docs/progress/{branch-name}.md` in that worktree
    - If it exists, read it and check the Workflow Checklist for current status
    - If not, create one using the progress-doc skill with a review-specific workflow checklist (see below)

**House Rules Gate (always):**
- Check if `.opencode/HOUSE_RULES.md` exists.
- If it exists, read it before making review fixes and treat it as binding.
- If any requested change conflicts with House Rules, call it out and request explicit exception handling.

## Address Review Comments (Phase 1: Implementation)

6. Use the `github-pr-feedback` skill to fetch unresolved review threads and PR conversation comments for this branch's pull request
7. For each unresolved review comment/thread:
   a. Understand the feedback
   b. Make the necessary changes while preserving House Rules compliance
   c. Create a focused commit addressing that specific comment using the git-commit skill from `worktree_path`
   d. Resolve that comment in GitHub using GitHub MCP once the change is in place
8. **Update the Workflow Checklist**: Mark "Phase 1: Implementation" items as complete

## Write Down What You Learned (Phase 2: Learnings)

9. **Extract learnings** from addressing these review comments — but only if something technically relevant was learned:
   - A surprising API behavior or gotcha worth remembering
   - A workaround for a bug or limitation
   - A pattern that should be followed in the future
   - An architectural decision with non-obvious rationale
   
   Skip this step if the changes were straightforward and nothing noteworthy emerged.
   
10. For each learning worth documenting:
   - Categorize it (gotcha, pattern, decision, or discovery)
   - Create `docs/learnings/` directory if it doesn't exist
   - Append the learning to the appropriate file with ticket ID and date using the `learnings` skill
   - **Commit any new learnings** using the git-commit skill from `worktree_path`
   
11. Summarize what was documented:
     ```
     Documented X learnings:
     - gotchas.md: "Title"
     - patterns.md: "Title"
     ```
    
    If nothing noteworthy was learned, say so briefly and move on.

12. **Update the Workflow Checklist**: Mark "Phase 2: Learnings" items as complete

## Push Changes (Phase 3: Finalize - FINAL STEP)

**IMPORTANT: Only proceed with this section AFTER all changes, documentation, and learnings are complete. Do NOT push until everything else is finished.**

13. Use the git-push-remote skill with explicit `worktree_path` and `branch_name` to push all commits to remote
14. Add a summary comment to the PR using GitHub MCP explaining:
    - What changes were made
    - How each comment was addressed
    - House Rules alignment (and any approved exceptions)
    - Worktree context used for this review pass
    - Any items that need further discussion
15. **Update the Workflow Checklist**: Mark "Phase 3: Finalize & Push" items as complete

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
- [ ] Resolve ticket worktree path — use `git-worktree-find` skill
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
