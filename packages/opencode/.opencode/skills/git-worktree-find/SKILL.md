---
name: git-worktree-find
description: Find the worktree path for a branch and create/reuse it when missing
---

# Git Worktree Find

Resolve the worktree path for a ticket branch using the native Git provider. If a worktree does not exist yet, create it using the native fallback `git-worktree-prepare`. Herdr-configured projects use this skill only outside an active Herdr pane.

Use shell-safe parsing compatible with bash/zsh and avoid `status` as a variable name.

## Inputs

- `branch` (required): branch name to locate

## Steps

1. Capture the launching checkout before resolving another worktree:
   ```bash
   workflow_root="$(git rev-parse --show-toplevel)"
   ```
   Keep this value unchanged. Workflow control files, including House Rules,
   remain anchored to this checkout.

2. Find existing worktree assignment for the branch:
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

3. If found:
   - Return the existing worktree path
   - Return the captured workflow root
   - If the path equals `workflow_root`, return worktree state `root`; use it instead of creating a dedicated worktree
   - Otherwise return worktree state `reused`
   - Stop

4. If not found:
   - Call `git-worktree-prepare` for the same branch
   - This also applies local-file sync from `.opencode/worktree-local-files`
   - Return the workflow root, newly created path, and worktree state `created`

5. Verify branch in resolved worktree:
   ```bash
   git -C "{worktree-path}" branch --show-current
   ```

## Output

Return:

```text
Workflow root: <absolute-path>
Branch: <branch>
Worktree: <absolute-path>
Worktree state: <root|created|reused>
```

## Error Handling

- If branch is empty or invalid, fail with actionable guidance.
- If `git worktree` command fails, return the git error directly.
- If creation fails in step 3, report failure and include the attempted path.
