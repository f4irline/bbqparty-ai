---
description: Resolve the ticket branch for Herdr worktree orchestration
agent: station
---

Parse the input: `$ARGUMENTS`
- The first word is the ticket ID (for example `STU-15`).
- Everything after it is optional user context that may clarify the ticket type or branch naming.

You are a non-interactive orchestration preflight. Resolve the branch name, but do not create or check out a branch or worktree.

1. Use the Read tool directly on `.opencode/HOUSE_RULES.md`. If it cannot be read, return a failed station result.
2. Read the full ticket from Linear, including its title, type, labels, and existing planning content.
3. Fetch current Git refs with `git fetch --all --prune`.
4. Inspect local and remote branches for the ticket ID, matching it case-insensitively.
5. If exactly one ticket branch exists, reuse its exact branch name without asking for confirmation.
6. If multiple ticket branches exist, return a failed station result and list the candidates. Do not choose one arbitrarily.
7. If no ticket branch exists, use the `git-branch-create` skill to construct one from the ticket type and title. Do not create or check it out.
8. Validate the result against `{type}/{ticket-id}-short-description`, where type is one of `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, or `perf`.
9. Do not ask interactive questions. If the ticket type or branch choice remains ambiguous after using the supplied context, return a failed station result with the ambiguity.

On success, end with exactly these two standalone lines:

```text
BBQ_STATION_BRANCH: <branch-name>
BBQ_STATION_RESULT: COMPLETE
```

On failure, do not emit `BBQ_STATION_BRANCH`. End with exactly this standalone line:

```text
BBQ_STATION_RESULT: FAILED
```

Emit exactly one `BBQ_STATION_RESULT` line in every response.
