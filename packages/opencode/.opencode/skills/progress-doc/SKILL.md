---
name: progress-doc
description: Create and maintain implementation progress documentation for a feature branch
---

# Progress Documentation

Create and maintain a progress document in `docs/progress/{branch-name}.md` to track implementation status.

## File Location

```
docs/progress/{branch-name}.md
```

Example: `docs/progress/feat-STU-15-user-authentication.md`

Note: Replace `/` in branch names with `-` for the filename.
Note: Keep this file in the branch's dedicated worktree checkout.

## Document Structure

```markdown
# {Ticket ID}: {Ticket Title}

**Branch:** `{branch-name}`
**Worktree:** `{absolute-worktree-path}`
**Status:** {In Progress | Blocked | Complete}
**Started:** {YYYY-MM-DD}
**Last Updated:** {YYYY-MM-DD HH:MM}

## Overview

{Brief description of what this ticket implements}

## Workflow Checklist

> **IMPORTANT**: This checklist ensures all workflow steps are completed, even after context compaction.
> Check off each phase as you complete it. After ANY interruption, read this section first.

### Phase 1: Implementation
- [ ] Write/modify tests (TDD)
- [ ] Implement changes
- [ ] Validate (lint, build, tests pass) — validate-changes plugin runs automatically
- [ ] Commit implementation changes — use `git-commit` skill

### Phase 2: Learnings
- [ ] Extract learnings (or note: nothing noteworthy)
- [ ] Document learnings if any — use `learnings` skill
- [ ] Commit learnings if any — use `git-commit` skill

### Phase 3: Finalize & Push (DO NOT SKIP)
- [ ] Update this progress doc to "Complete" status
- [ ] Commit progress doc update — use `git-commit` skill
- [ ] Push all commits to remote — use `git-push-remote` skill
- [ ] Create pull request — use GitHub MCP
- [ ] Move ticket to "In Review" — use Linear MCP

## Tasks

- [ ] Task 1
- [ ] Task 2
- [x] Completed task

## Progress Log

### {YYYY-MM-DD HH:MM}

{Description of work done}

### {YYYY-MM-DD HH:MM}

{Description of work done}

## Technical Notes

{Any important technical decisions, gotchas, or context for future reference}

## Blockers

{Any blockers or dependencies - remove section if none}

## Testing

- [ ] Unit tests written
- [ ] Integration tests written
- [ ] Manual testing completed

## Files Changed

- `path/to/file1.ts` - {brief description}
- `path/to/file2.ts` - {brief description}
```

## Steps

### Creating New Progress Doc

1. **Ensure directory exists**:
   ```bash
   mkdir -p docs/progress
   ```

2. **Get branch name**:
   ```bash
   git branch --show-current
   ```

3. **Get worktree path**:
   ```bash
   git rev-parse --show-toplevel
   ```

4. **Create the file** with the initial template filled in

### Updating Progress Doc

1. **Read current content** of the progress doc
2. **Add new entry** to Progress Log with timestamp
3. **Update**:
   - Status if changed
   - Last Updated timestamp
   - Task checkboxes
   - Files Changed list
   - Technical Notes as needed
   - Worktree path if missing

## When to Update

Update the progress document:
- When starting a new task
- After completing a significant piece of work
- When encountering blockers
- When making important technical decisions
- Before committing changes

## Example

```markdown
# STU-15: Add User Authentication

**Branch:** `feat/STU-15-user-authentication`
**Worktree:** `/Users/me/projects/my-repo/.opencode/.bbq-worktrees/feat-STU-15-user-authentication`
**Status:** In Progress
**Started:** 2024-01-15
**Last Updated:** 2024-01-15 14:30

## Overview

Implement JWT-based authentication with login, logout, and token refresh.

## Workflow Checklist

> **IMPORTANT**: This checklist ensures all workflow steps are completed, even after context compaction.
> Check off each phase as you complete it. After ANY interruption, read this section first.

### Phase 1: Implementation
- [x] Write/modify tests (TDD)
- [x] Implement changes
- [x] Validate (lint, build, tests pass) — validate-changes plugin runs automatically
- [x] Commit implementation changes — use `git-commit` skill

### Phase 2: Learnings
- [ ] Extract learnings (or note: nothing noteworthy)
- [ ] Document learnings if any — use `learnings` skill
- [ ] Commit learnings if any — use `git-commit` skill

### Phase 3: Finalize & Push (DO NOT SKIP)
- [ ] Update this progress doc to "Complete" status
- [ ] Commit progress doc update — use `git-commit` skill
- [ ] Push all commits to remote — use `git-push-remote` skill
- [ ] Create pull request — use GitHub MCP
- [ ] Move ticket to "In Review" — use Linear MCP

## Tasks

- [x] Set up JWT utilities
- [x] Create auth middleware
- [ ] Implement login endpoint
- [ ] Implement logout endpoint
- [ ] Add refresh token logic
- [ ] Write integration tests

## Progress Log

### 2024-01-15 14:30

Completed JWT utilities and auth middleware. Moving on to login endpoint.

### 2024-01-15 10:00

Started implementation. Set up project structure for auth module.

## Technical Notes

- Using RS256 algorithm for JWT signing
- Refresh tokens stored in httpOnly cookies
- Access token expiry: 15 minutes

## Files Changed

- `api/src/utils/jwt.ts` - JWT sign/verify utilities
- `api/src/middleware/auth.ts` - Authentication middleware
- `api/src/types/auth.ts` - TypeScript interfaces
```
