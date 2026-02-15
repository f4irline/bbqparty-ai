---
name: git-push-remote
description: Push the current branch to the remote repository with upstream tracking
---

# Git Push Remote

Push the current branch to the remote repository, setting up tracking if needed.

In worktree workflows, run this skill from the ticket's dedicated worktree path.

## Inputs

- `worktree_path` (recommended): absolute path to the ticket worktree
- `branch` (optional): branch name; if omitted, resolve from the worktree

## Steps

1. **Resolve working context**:

   If `worktree_path` is provided, prefer explicit `-C` commands:
   ```bash
   git -C "{worktree_path}" rev-parse --show-toplevel
   git -C "{worktree_path}" branch --show-current
   ```

   If `branch` is not provided, resolve it from the same path.

   If branch resolves to empty (detached HEAD), stop and return an actionable error.

2. **Confirm repository/worktree location**:
   - Always report the resolved top-level path used for push.

3. **Check if upstream is set**:
   ```bash
   git -C "{worktree_path}" rev-parse --abbrev-ref --symbolic-full-name "@{upstream}" 2>/dev/null
   ```

4. **Push to remote**:

   If no upstream is set (new branch):
   ```bash
   git -C "{worktree_path}" push -u origin "{branch}"
   ```

   If upstream exists:
   ```bash
   git -C "{worktree_path}" push origin "{branch}"
   ```

    Never rely on implicit current directory branch for pushes in multi-worktree workflows.

## Error Handling

### Push Rejected (Remote Has Changes)

If push is rejected because remote has new commits:
```bash
git -C "{worktree_path}" pull --rebase origin "{branch}"
git -C "{worktree_path}" push origin "{branch}"
```

If there are conflicts during rebase:
1. Inform the user about the conflicts
2. List the conflicting files
3. Ask for guidance on resolution

### No Commits to Push

If there are no commits to push, inform the user that the branch is up to date.

### Authentication Issues

If authentication fails:
1. Check if SSH key or token is configured
2. Suggest running `gh auth login` for GitHub
3. Ask user to verify their credentials

## Verification

After pushing, verify the push succeeded:
```bash
git -C "{worktree_path}" log "origin/{branch}" -1 --oneline
```

Report the pushed commit hash and message to confirm success.

Also report the worktree path used for the push.
