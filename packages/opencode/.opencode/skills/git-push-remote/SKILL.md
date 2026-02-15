---
name: git-push-remote
description: Push the current branch to the remote repository with upstream tracking
---

# Git Push Remote

Push the current branch to the remote repository, setting up tracking if needed.

In worktree workflows, run this skill from the ticket's dedicated worktree path.

## Steps

1. **Get current branch name**:
   ```bash
   git branch --show-current
   ```

2. **Confirm repository/worktree location**:
   ```bash
   git rev-parse --show-toplevel
   ```
   Report the path so it is clear which worktree is being pushed.

3. **Check if upstream is set**:
   ```bash
   git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null
   ```

4. **Push to remote**:

   If no upstream is set (new branch):
   ```bash
   git push -u origin $(git branch --show-current)
   ```

   If upstream exists:
   ```bash
   git push
   ```

## Error Handling

### Push Rejected (Remote Has Changes)

If push is rejected because remote has new commits:
```bash
git pull --rebase origin $(git branch --show-current)
git push
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
git log origin/$(git branch --show-current) -1 --oneline
```

Report the pushed commit hash and message to confirm success.

Also report the worktree path used for the push.
