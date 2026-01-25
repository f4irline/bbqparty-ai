---
name: git-branch-create
description: Create a properly named git branch from a Linear ticket ID following the convention {type}/{ticket-id}-short-description
---

# Git Branch Create

Create a new git branch following the project's naming convention.

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

4. **Create the branch**:
   ```bash
   git checkout -b {type}/{ticket-id}-{short-description}
   ```

## Examples

| Ticket | Title | Branch Name |
|--------|-------|-------------|
| STU-15 | Add user authentication | `feat/STU-15-user-authentication` |
| STU-23 | Fix login timeout issue | `fix/STU-23-login-timeout` |
| STU-42 | Refactor API error handling | `refactor/STU-42-api-error-handling` |

## Validation

Before creating the branch:
1. Ensure you're on the main/master branch
2. Pull latest changes: `git pull origin main`
3. Check the branch doesn't already exist: `git branch -a | grep {ticket-id}`

If a branch for this ticket already exists, inform the user and ask whether to:
- Check out the existing branch
- Create a new branch with a different suffix
