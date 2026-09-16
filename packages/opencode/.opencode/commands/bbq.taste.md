---
description: Address PR review comments for a Linear ticket
agent: pitmaster
---

Parse the input: `$ARGUMENTS`
- The first word is the **ticket ID** (e.g., `STU-15`)
- Everything after is **additional context** from the user (optional, e.g., specific comments to focus on)

You are addressing review comments for the ticket. If additional context was provided, prioritize accordingly.

> **CRITICAL: Context Compaction Safety**
> Use the ignored workflow-state file to resume after interruption or compaction.
> Read it first, keep its checklist current, and never stage or commit it.

Follow these steps:

## Setup

**Mandatory House Rules Gate:**
- Before doing repository work, capture the launching checkout with `git rev-parse --show-toplevel` as `workflow_root` and initially set `worktree_path` to the same value.
- Use the Read tool directly on `{workflow_root}/.opencode/HOUSE_RULES.md`.
- Do not use Glob, Grep, or directory listing to locate or test this known path.
- Treat the loaded rules as binding for the entire workflow; do not require or load a copy from the ticket worktree.
- If the direct read fails, stop with `BBQ_PHASE_RESULT: FAILED` and report the read error.
- If any requested change conflicts with House Rules, call it out and request explicit exception handling.

1. Use the `git-find-ticket-branch` skill to find the branch for this ticket.
2. Resolve the worktree provider after resolving `workflow_root`, `branch_name`, and the remote default branch:
    - Read `.opencode/bbq-config.json` with `jq`. A missing file means `runtime == "native"`. Invalid JSON or any runtime other than `native` or `herdr` is an actionable error; do not guess a provider.
    - Use Herdr only when `runtime == "herdr"` **and** `HERDR_ENV=1`. In that case explicitly load and follow the installed `herdr` skill before running its CLI commands.
    - With active Herdr, run `herdr worktree list --cwd "{workflow_root}"` and inspect its JSON `.result.worktrees` for the matching branch.
    - If the matching checkout has no `open_workspace_id`, run `herdr worktree open --cwd "{workflow_root}" --branch "{branch-name}" --label "{ticket-id}" --no-focus` and retain `.result.workspace.workspace_id` as metadata only.
    - If no checkout exists, use the deterministic absolute `.opencode/.bbq-worktrees/{branch-slug}` path. Use `origin/{branch-name}` as the base when only a remote ticket branch exists; otherwise use the resolved remote default branch. Run `herdr worktree create --cwd "{workflow_root}" --branch "{branch-name}" --base "{base-ref}" --path "{worktree-path}" --label "{ticket-id}" --no-focus`.
    - Parse the authoritative checkout path from `.result.worktree.path` or its matching `.result.worktrees` entry, never from `.result.workspace.workspace_id`.
    - If Herdr is configured but `HERDR_ENV=1` is absent, state that native fallback is active and use `git-worktree-find`. It may call the native fallback `git-worktree-prepare` skill when the checkout is missing.
    - Under either provider, run `"{workflow_root}/.opencode/scripts/sync-worktree-local-files.sh" "{workflow_root}" "{worktree-path}"` after resolving the path. Then run `bash "{workflow_root}/.opencode/scripts/ensure-workflow-state-ignore.sh" "{worktree-path}"` so local state stays ignored even when installed configuration is not committed. Capture outputs as `workflow_root`, `branch_name`, and `worktree_path`.
3. From this point forward, run all git, code, test, and documentation actions in the resolved worktree path.
    - Prefer explicit path-aware commands (`git -C "{worktree_path}" ...`) when possible.
    - Do not rely on the process current directory.
4. Pull the latest changes in that worktree and resolve conflicts, asking for help if conflicts are complex.
5. Use the `progress-doc` skill to create or resume `.opencode/.bbq-state/{branch-name}.md` in the worktree. Start a fresh review-pass checklist with status "In Progress" for every Taste invocation; do not reuse completed checklist items from Fire or an earlier review pass.

## Address Review Comments

6. Use the `github-pr-feedback` skill to fetch unresolved review threads and PR conversation comments for this branch's pull request.
7. Review all feedback before editing, then group comments into coherent changes.
8. Implement each valid change while preserving House Rules compliance. Track the comment-to-change mapping in ignored workflow state, but do not commit after each comment.
9. Run all relevant lint, build, typecheck, and test commands for the complete review pass.
10. Evaluate whether the review exposed a durable technical learning. When useful, update `docs/learnings/` before committing so it ships with the change it explains; otherwise record "none" only in ignored workflow state.
11. Stage and inspect the complete review-pass diff. Exclude workflow state and unrelated files. Capture the inspected staged tree as `reviewed_tree` with `git write-tree`.
12. Run `git write-tree` again and require it to equal `reviewed_tree`. Create one commit for the coherent review pass using the `git-commit` skill's pre-reviewed staged candidate mode. Do not restage after inspection.
    - Multiple commits are allowed only when feedback groups are independently understandable and shippable.
    - Never create separate commits merely for workflow state, learning capture, or one commit per review comment.

## Push Changes

13. Use the `git-push-remote` skill with explicit `worktree_path` and `branch_name` to push the review commit or commits.
14. Resolve the addressed comments in GitHub and add a PR summary explaining:
    - What changed and how each comment was addressed.
    - Validation performed.
    - House Rules alignment and approved exceptions, if any.
    - Any items that still need discussion.
15. Mark the ignored workflow state complete. Do not commit or push this local bookkeeping update.

## Review Workflow Checklist Template

When creating state for review work, use this checklist:

```markdown
## Workflow Checklist

### Review Pass
- [ ] Resolve ticket worktree path
- [ ] Fetch and group PR feedback
- [ ] Implement valid changes
- [ ] Run relevant validation
- [ ] Evaluate and capture durable learnings
- [ ] Stage and inspect the coherent review-pass diff
- [ ] Commit the reviewed changes

### Delivery
- [ ] Push changes
- [ ] Resolve addressed comments
- [ ] Add a PR summary
```

Be thorough in addressing feedback and concise in the PR response.
