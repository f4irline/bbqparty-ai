---
name: git-branch-create
description: Resolve a properly named git branch from a Linear ticket ID following the convention {type}/{ticket-id}-short-description
---

# Git Branch Create

Resolve a ticket branch name following the project's naming convention.

In parallel workflows, branch creation should happen through a dedicated worktree (via `git-worktree-prepare`), not by checking out directly in the current tree.

## Branch Format

```
{type}/{ticket-id}-short-description
```

### Type Prefixes

| Type | Use Case |
|------|----------|
| `feat` | New features or functionality |
| `fix` | Bug fixes |
| `refactor` | Code refactoring without functional changes |
| `docs` | Documentation changes |
| `test` | Adding or updating tests |
| `chore` | Maintenance tasks, dependencies, tooling |
| `perf` | Performance improvements |

## Steps

1. **Determine the type** from the ticket:
   - Look at the ticket type/label in Linear
   - If unclear, ask the user

2. **Extract ticket ID**:
   - Format: `STU-XX` (or similar project prefix)
   - Keep the full ID including prefix

3. **Create short description**:
   - Use 2-4 words from the ticket title
   - Lowercase, hyphen-separated
   - No special characters
   - Max 30 characters

4. **Construct branch name**:
   ```text
   {type}/{ticket-id}-{short-description}
   ```

5. **Do not check out in the current tree**:
   - Do not run `git checkout -b` in the active workspace
   - Return the constructed branch name to the caller

6. **Handoff to worktree flow**:
   - The caller should run `git-worktree-prepare` with the constructed branch name
   - Let that skill create/reuse the actual branch checkout

## Examples

| Ticket | Title | Branch Name |
|--------|-------|-------------|
| STU-15 | Add user authentication | `feat/STU-15-user-authentication` |
| STU-23 | Fix login timeout issue | `fix/STU-23-login-timeout` |
| STU-42 | Refactor API error handling | `refactor/STU-42-api-error-handling` |

## Validation

Before returning the branch name:
1. Fetch latest refs: `git fetch --all --prune`
2. Check branch candidates: `git branch -a | grep {ticket-id}`

If a branch for this ticket already exists, inform the user and ask whether to:
- Reuse the existing branch name
- Create a new branch with a different suffix

## Output

Return:

```text
Branch: <branch-name>
Status: <new|existing>
```
