---
name: git-worktree-find
description: Find the worktree path for a branch and create/reuse it when missing
---

# Git Worktree Find

Resolve the worktree path for a ticket branch. If a worktree does not exist yet, create it using `git-worktree-prepare`.

Use shell-safe parsing compatible with bash/zsh and avoid `status` as a variable name.

## Inputs

- `branch` (required): branch name to locate

## Steps

1. Find existing worktree assignment for the branch:
   ```bash
   existing_path=""
   current_path=""
   while IFS= read -r line; do
     case "$line" in
       "worktree "*)
         current_path="${line#worktree }"
         ;;
       "branch refs/heads/"*)
         current_branch="${line#branch refs/heads/}"
         if [ "$current_branch" = "$branch" ]; then
           existing_path="$current_path"
           break
         fi
         ;;
     esac
   done < <(git worktree list --porcelain)
   ```

2. If found:
   - Return the existing worktree path
   - Return worktree state `reused`
   - Stop

3. If not found:
   - Call `git-worktree-prepare` for the same branch
   - This also applies local-file sync from `.opencode/worktree-local-files`
   - Return the newly created path and worktree state `created`

4. Verify branch in resolved worktree:
   ```bash
   git -C "{worktree-path}" branch --show-current
   ```

## Output

Return:

```text
Branch: <branch>
Worktree: <absolute-path>
Worktree state: <created|reused>
```

## Error Handling

- If branch is empty or invalid, fail with actionable guidance.
- If `git worktree` command fails, return the git error directly.
- If creation fails in step 3, report failure and include the attempted path.
