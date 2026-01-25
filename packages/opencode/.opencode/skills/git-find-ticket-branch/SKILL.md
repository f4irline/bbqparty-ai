---
name: git-find-ticket-branch
description: Find a git branch by Linear ticket ID prefix (e.g., STU-15)
---

# Git Find Ticket Branch

Find an existing git branch that corresponds to a Linear ticket ID.

## Search Strategy

Branches follow the naming convention: `{type}/{ticket-id}-{description}`

Search for branches containing the ticket ID.

## Steps

1. **Fetch latest remote branches**:
   ```bash
   git fetch --all --prune
   ```

2. **Search local and remote branches**:
   ```bash
   git branch -a | grep -i "{ticket-id}"
   ```

3. **Parse results**:
   - Extract branch names from the output
   - Remove `remotes/origin/` prefix for remote branches
   - Deduplicate (same branch may exist locally and remotely)

## Result Handling

### Single Match Found

Return the branch name and report:
- Branch name
- Whether it exists locally, remotely, or both
- Last commit on the branch

### Multiple Matches Found

List all matching branches with their last commit dates:
```bash
git for-each-ref --sort=-committerdate --format='%(refname:short) - %(committerdate:relative)' refs/heads refs/remotes | grep -i "{ticket-id}"
```

Ask the user which branch to use.

### No Match Found

Report that no branch was found for this ticket ID.

Suggest possible actions:
1. The ticket might not have been started yet
2. The branch might use a different naming convention
3. List recent branches for manual inspection:
   ```bash
   git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads | head -10
   ```

## Output

Provide:
- The branch name (or list of candidates)
- Current status (local/remote/both)
- Last commit info:
  ```bash
  git log {branch} -1 --oneline
  ```

## Example

For ticket `STU-15`:

```
Found branch: feat/STU-15-user-authentication
  - Exists: locally and on origin
  - Last commit: abc1234 feat(api): add login endpoint (2 hours ago)
```
