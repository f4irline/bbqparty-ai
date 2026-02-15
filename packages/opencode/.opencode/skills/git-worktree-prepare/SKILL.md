---
name: git-worktree-prepare
description: Create or reuse a dedicated git worktree for a branch using a deterministic path layout
---

# Git Worktree Prepare

Create (or reuse) a dedicated worktree for a target branch so multiple agents can work in parallel without branch checkout conflicts.

## Default Path Layout

Worktree root is resolved as:

1. If `BBQ_WORKTREE_ROOT` is set: `"$BBQ_WORKTREE_ROOT/{repo-name}"`
2. Otherwise: `"{repo-parent}/.bbq-worktrees/{repo-name}"`

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
   git worktree list --porcelain
   ```
   If found, return that path with status `reused` and stop.

4. Build deterministic worktree path:
   - Resolve repo name from repo root basename
   - Resolve worktree root using `BBQ_WORKTREE_ROOT` or fallback layout
   - Replace `/` with `-` in branch name for directory name
   - Create parent directories as needed

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
Status: <created|reused>
Default base: origin/<default-branch>
```

## Notes

- Do not use `git checkout -b` in the current working tree when parallel work is expected.
- Reusing an existing branch worktree is preferred over creating duplicates.
