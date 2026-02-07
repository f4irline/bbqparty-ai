---
name: github-pr-feedback
description: Fetch unresolved review threads and PR comments for the pull request tied to the resolved target branch
---

# GitHub PR Feedback

Find the pull request associated with the resolved target branch (ticket branch when available, otherwise current branch) and return both:
- unresolved review threads
- PR conversation comments

## What This Skill Does

1. Resolves the target branch (prefer `git-find-ticket-branch` when ticket ID is known)
2. Resolves the `owner/repo` from the `origin` remote
3. Finds the PR tied to that branch
4. Fetches review threads and PR comments from that PR
5. Filters review threads to unresolved only (`is_resolved: false`)
6. Returns a concise, actionable summary of unresolved threads and comments

## Required Tools

- Git
- `git-find-ticket-branch` skill
- GitHub MCP with:
  - `list_pull_requests`
  - `list_pr_comments`

## Steps

1. **Resolve target branch**:
   - If ticket ID is available, use `git-find-ticket-branch` to find the ticket branch.
   - If ticket ID is not available, fall back to:
     ```bash
     git branch --show-current
     ```

   If no branch can be resolved (for example detached HEAD and no ticket ID), stop and report that no target branch is available.

2. **Resolve repository from `origin`**:
   ```bash
   git remote get-url origin
   ```

   Parse either format:
   - `git@github.com:owner/repo.git`
   - `https://github.com/owner/repo.git`

   Extract `owner` and `repo` (without `.git`).

3. **Find PR for the branch**:
   - Call `list_pull_requests` with:
     - `owner`
     - `repo`
     - `state: "open"`
     - `head: "{owner}:{target-branch}"`
   - If no open PR is found, call again with `state: "all"` and pick the most recently updated match.
   - If no PR exists for this branch, report that and stop.

4. **Fetch all PR threads and comments**:
   - Call `list_pr_comments` with:
     - `owner`
     - `repo`
     - `pull_number`

   Use both arrays from the response:
   - `review_threads`
   - `issue_comments`

5. **Filter unresolved threads and collect comments**:
   - Keep only threads where `is_resolved` is `false`
   - Keep both outdated and non-outdated unresolved threads
   - Keep all `issue_comments` (PR conversation comments)
   - Note: comments are not resolved/unresolved in GitHub; only threads are

6. **Return results**:
   - PR number, title, URL
   - Branch name
   - Branch source (`git-find-ticket-branch` or current branch)
   - Total thread count
   - Unresolved thread count
   - Total comment count
   - For each unresolved thread, include:
     - `thread_id`
     - `path` and `line` (if present)
     - `is_outdated`
     - latest comment author and timestamp
     - latest comment snippet (short)
   - For each PR comment, include:
     - comment `id`
     - author and timestamp
     - comment snippet (short)

## Output Format

Use this structure:

```text
PR #123: Example title
URL: https://github.com/owner/repo/pull/123
Branch: feat/STU-15-example
Branch source: git-find-ticket-branch

Review threads: 7 total
Unresolved threads: 2
PR comments: 3 total

Unresolved review threads:
1) PRRT_xxx
   Location: src/file.ts:42
   Outdated: no
   Last comment: octocat at 2026-02-07T12:00:00Z
   "Please rename this for clarity..."

2) PRRT_yyy
   Location: src/other.ts:10
   Outdated: yes
   Last comment: hubot at 2026-02-07T12:05:00Z
   "This still fails when input is empty..."

PR conversation comments:
1) 998877
   Author: octocat at 2026-02-07T12:10:00Z
   "Can we include migration notes in the PR body?"

2) 998878
   Author: hubot at 2026-02-07T12:11:00Z
   "LGTM from the platform side."
```

If no unresolved threads remain, explicitly return that and still include comments:

```text
No unresolved review threads for PR #123 (feat/STU-15-example).
PR comments: 3 total.
```

If there are no unresolved threads and no comments:

```text
No unresolved review threads or PR comments for PR #123 (feat/STU-15-example).
```

## Error Handling

- If `origin` remote is missing, report and ask for `owner/repo`.
- If `git-find-ticket-branch` returns no matches, fall back to current branch if available; otherwise report that no ticket branch was found.
- If multiple PRs match the same head branch, use the most recently updated one and mention all candidate PR numbers.
- If GitHub MCP call fails, return the error message verbatim.
