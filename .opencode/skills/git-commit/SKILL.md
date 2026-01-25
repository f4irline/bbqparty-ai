---
name: git-commit
description: Create a well-formatted git commit with conventional commit message format and ticket reference
---

# Git Commit

Create a git commit following the conventional commits specification with Linear ticket reference.

## Commit Message Format

```
{type}({scope}): {description}

{body}

Refs: {ticket-id}
```

### Type

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code refactoring |
| `docs` | Documentation only |
| `test` | Adding/updating tests |
| `chore` | Maintenance, deps, tooling |
| `perf` | Performance improvement |
| `style` | Code style (formatting, semicolons) |
| `ci` | CI/CD changes |

### Scope

Optional, indicates the component affected:
- `api` - Backend API changes
- `mobile` - Mobile app changes
- `infra` - Infrastructure/Terraform changes
- `shared` - Shared libraries/utilities
- Or a specific feature name

### Description

- Imperative mood ("add" not "added")
- No period at the end
- Max 72 characters
- Lowercase first letter

### Body

- Explain WHAT and WHY (not how)
- Wrap at 72 characters
- Separate from subject with blank line

## Steps

1. **Stage changes**:
   ```bash
   git add -A
   ```

   Or stage specific files if making focused commits:
   ```bash
   git add path/to/file1 path/to/file2
   ```

2. **Review staged changes**:
   ```bash
   git diff --staged --stat
   ```

3. **Create commit**:
   ```bash
   git commit -m "{type}({scope}): {description}" -m "{body}" -m "Refs: {ticket-id}"
   ```

## Examples

### Feature Commit
```
feat(api): add user authentication endpoint

Implement JWT-based authentication with refresh tokens.
Includes rate limiting and brute force protection.

Refs: STU-15
```

### Bug Fix Commit
```
fix(mobile): resolve login timeout issue

Increase timeout from 5s to 30s for slow networks.
Add retry logic with exponential backoff.

Refs: STU-23
```

### Test Commit
```
test(api): add integration tests for auth endpoints

Cover login, logout, and token refresh flows.
Add edge cases for invalid credentials.

Refs: STU-15
```

## Validation

Before committing:
1. Ensure all tests pass
2. Ensure linting passes
3. Review the diff to confirm changes are intentional

After committing:
```bash
git log -1 --oneline
```

Report the commit hash to confirm success.
