---
name: git-worktree-find
description: Find the worktree path for a branch and create/reuse it when missing
---

# Git Worktree Find

Resolve the worktree path for a ticket branch. If a worktree does not exist yet, create it using `git-worktree-prepare`.

## Inputs

- `branch` (required): branch name to locate

## Steps

1. Find existing worktree assignment for the branch:
   ```bash
   git worktree list --porcelain
   ```
   Parse entries and locate `branch refs/heads/{branch}`.

2. If found:
   - Return the existing worktree path
   - Return status `reused`
   - Stop

3. If not found:
   - Call `git-worktree-prepare` for the same branch
   - Return the newly created path and status `created`

4. Verify branch in resolved worktree:
   ```bash
   git -C "{worktree-path}" branch --show-current
   ```

## Output

Return:

```text
Branch: <branch>
Worktree: <absolute-path>
Status: <created|reused>
```

## Error Handling

- If branch is empty or invalid, fail with actionable guidance.
- If `git worktree` command fails, return the git error directly.
- If creation fails in step 3, report failure and include the attempted path.
