---
name: git-worktree-prepare
description: Create or reuse a dedicated git worktree for a branch using a deterministic path layout
---

# Git Worktree Prepare

Create (or reuse) a dedicated worktree for a target branch so multiple agents can work in parallel without branch checkout conflicts.

## Shell Compatibility

- Commands should work in both bash and zsh.
- Do not use `status` as a shell variable name (read-only in zsh). Use `worktree_state` instead.

## Path Layout

Worktree root is resolved as:

1. If sidecar file `.opencode/worktree-root` exists and has a value:
   - Use that value as `{worktree-root}`
2. Otherwise fallback to default sibling layout:
   - `"{repo-parent}/.bbq-worktrees/{repo-name}"`

Worktree path for a branch:

```
{worktree-root}/{branch-name-with-slashes-replaced-by-dashes}
```

Example:

```
repo root: /Users/me/projects/my-repo
branch: feat/STU-15-user-authentication
worktree: /Users/me/projects/.bbq-worktrees/my-repo/feat-STU-15-user-authentication
```

## Inputs

- `branch` (required): target branch name, for example `feat/STU-15-user-authentication`

## Steps

1. Resolve repository context:
   ```bash
   git rev-parse --show-toplevel
   ```

2. Resolve default branch from remote HEAD (do not hardcode `main`):
   ```bash
   git symbolic-ref refs/remotes/origin/HEAD
   ```
   Parse to `origin/<default-branch>`.

   Fallback strategy if remote HEAD is unavailable:
   - Prefer `main` if it exists
   - Otherwise use `master` if it exists

3. Check whether this branch is already attached to any worktree:
   ```bash
   branch="{branch}"
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
   If found, return that path with worktree state `reused` and stop.

4. Build deterministic worktree path:
   - Resolve repo name from repo root basename
   - Resolve worktree root:
     - Prefer project-specific path from `.opencode/worktree-root`
     - Fallback to default sibling layout when no sidecar path is found
   - Replace `/` with `-` in branch name for directory name
   - Create parent directories as needed

   Example extraction flow:
   ```bash
   repo_root="$(git rev-parse --show-toplevel)"
   repo_name="$(basename "$repo_root")"
   worktree_root_file="$repo_root/.opencode/worktree-root"
   configured_root=""

   if [ -f "$worktree_root_file" ]; then
     read -r configured_root < "$worktree_root_file"
   fi

   if [ -n "$configured_root" ]; then
     worktree_root="$configured_root"
   else
     worktree_root="$(dirname "$repo_root")/.bbq-worktrees/$repo_name"
   fi
   ```

   Example resolution from sidecar:
   ```text
   .opencode/worktree-root: /Users/me/worktrees/my-repo
   worktree-root: /Users/me/worktrees/my-repo
   ```

5. Add the worktree:
   - If local branch exists:
     ```bash
     git worktree add "{worktree-path}" "{branch}"
     ```
   - Else if remote branch exists:
     ```bash
     git worktree add --track -b "{branch}" "{worktree-path}" "origin/{branch}"
     ```
   - Else create a new branch from remote default branch:
     ```bash
      git worktree add -b "{branch}" "{worktree-path}" "origin/{default-branch}"
      ```

6. Verify:
   ```bash
   git -C "{worktree-path}" branch --show-current
   ```

## Output

Return:

```text
Branch: <branch>
Worktree: <absolute-path>
Worktree state: <created|reused>
Default base: origin/<default-branch>
```

## Notes

- Do not use `git checkout -b` in the current working tree when parallel work is expected.
- Reusing an existing branch worktree is preferred over creating duplicates.
