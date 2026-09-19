---
name: progress-doc
description: Use when implementing or reviewing a ticket across interruptions or context compaction
---

# Workflow State

Maintain resumable workflow state without adding bookkeeping to repository history.

## File Location

```text
.opencode/.bbq-state/{branch-name}.md
```

Replace `/` in the branch name with `-`. Keep the file in the ticket worktree so parallel branches have independent state. The package gitignore excludes `.opencode/.bbq-state/`.

Never stage or commit workflow state. If the state path appears in `git status`, stop and fix the ignore configuration before committing implementation changes.

## Template

```markdown
# {Ticket ID}: {Ticket Title}

**Branch:** `{branch-name}`
**Worktree:** `{absolute-worktree-path}`
**Status:** {In Progress | Blocked | Complete}
**Last Updated:** {YYYY-MM-DD HH:MM}

## Workflow Checklist

### Implementation
- [ ] Read ticket, plan, House Rules, and relevant learnings
- [ ] Write or update tests
- [ ] Implement the change
- [ ] Run relevant validation
- [ ] Evaluate and capture durable learnings
- [ ] Stage the complete candidate change
- [ ] Pass the implementation review gate
- [ ] Commit the approved candidate

### Delivery
- [ ] Push the branch
- [ ] Create or update the pull request
- [ ] Move the ticket to the required status

## Tasks

- [ ] {Next concrete task}

## Progress Log

### {YYYY-MM-DD HH:MM}

{Completed work, validation evidence, decision, or blocker}

## Technical Notes

{Important context needed to resume safely}
```

## Usage

1. Resolve the current branch and worktree path.
2. When no pre-resolved orchestration handoff is active, run `bash "{workflow_root}/.opencode/scripts/ensure-workflow-state-ignore.sh" "{worktree-path}"`. The Herdr orchestrator has already configured the ignore before a handed-off phase starts.
3. Create `.opencode/.bbq-state/` when needed, then create or read the branch state before implementation.
4. Update it after meaningful milestones, decisions, blockers, and review rounds.
5. After interruption or compaction, read it before taking another action.
6. Mark it complete only after push, pull request, and ticket transitions succeed.
7. For a later workflow on the same branch, append a fresh unchecked section and set status back to `In Progress`; never reuse a completed checklist as the current pass.

Use the state file for execution details such as timestamps, validation commands, review rounds, and external delivery status. Put durable technical knowledge in the implementation documentation or `docs/learnings/`; include those tracked files in the coherent change they explain rather than creating mandatory documentation-only commits.
