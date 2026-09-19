---
description: Implement a Linear ticket following the full workflow
agent: pitmaster
---

Parse the input: `$ARGUMENTS`
- The first word is the **ticket ID** (e.g., `STU-15`)
- Everything after is **additional context** from the user (optional, e.g., "this needs extensive research", "focus on performance", "skip tests for now"), except the reserved final `[BBQ_HOUSE_RULES_PATH=...]` marker supplied by the Herdr orchestrator

You are implementing the ticket. If additional context was provided, adjust your approach accordingly.

> **CRITICAL: Context Compaction Safety**
> The ignored workflow-state file contains the checklist used to resume safely.
> After ANY interruption or context compaction, ALWAYS read it first and continue from
> the next unchecked item. Never stage or commit the workflow-state file.

Follow these steps:

## Before Cooking

**Mandatory House Rules Gate:**
- First inspect `BBQ_WORKFLOW_ROOT`, `BBQ_WORKTREE_PATH`, and `BBQ_BRANCH_NAME`.
- If all three are set, treat them as the orchestrator's pre-resolved worktree handoff: trust the orchestrator-validated `BBQ_WORKFLOW_ROOT` without accessing it, validate that `BBQ_WORKTREE_PATH` is the current absolute Git worktree, require `git branch --show-current` there to equal `BBQ_BRANCH_NAME`, and require the branch to belong to the requested ticket. Set `workflow_root`, `worktree_path`, and `branch_name` from those values. Do not run branch discovery or create/open another worktree.
- If only some of the three variables are set, stop with `BBQ_PHASE_RESULT: FAILED`; never guess missing orchestration context.
- If none are set, capture the launching checkout with `git rev-parse --show-toplevel` as `workflow_root` and initially set `worktree_path` to the same value.
- With a pre-resolved handoff, use the Read tool directly on `{worktree_path}/.opencode/.bbq-runtime/HOUSE_RULES.md`. Without a handoff, use the Read tool directly on `{workflow_root}/.opencode/HOUSE_RULES.md`.
- Do not use Glob, Grep, or directory listing to locate or test this known path.
- Treat the loaded rules as binding for the entire workflow. Under a pre-resolved handoff, the ignored runtime file is the authoritative copy prepared by the orchestrator; do not reload it from `workflow_root`.
- If the direct read fails, stop with `BBQ_PHASE_RESULT: FAILED` and report the read error.
- Track any required exception explicitly in the ignored workflow state.

1. Move the ticket to "In Progress" status using Linear MCP.
2. Read the full ticket details from Linear, including research and planning comments.
3. If `docs/learnings/` exists, scan all files for learnings relevant to this ticket's domain.
4. Ask clarifying questions if anything is unclear before starting.
5. When no pre-resolved handoff is active, use the `git-branch-create` skill to resolve a properly named ticket branch. It returns the branch to the caller-selected worktree provider. When the handoff is active, keep its validated `branch_name`.
6. When no pre-resolved handoff is active, resolve the worktree provider after resolving `workflow_root`, `branch_name`, and the remote default branch:
    - Read `.opencode/bbq-config.json` with `jq`. A missing file means `runtime == "native"`. Invalid JSON or any runtime other than `native` or `herdr` is an actionable error; do not guess a provider.
    - Use Herdr only when `runtime == "herdr"` **and** `HERDR_ENV=1`. In that case explicitly load and follow the installed `herdr` skill before running its CLI commands.
    - With active Herdr, confirm the installed CLI syntax, then run `herdr worktree list --cwd "{workflow_root}"` and inspect its JSON `.result.worktrees` for the matching branch.
    - When the matching checkout exists but has no `open_workspace_id`, open it without focus: `herdr worktree open --cwd "{workflow_root}" --branch "{branch-name}" --label "{ticket-id}" --no-focus`. Parse `.result.workspace.workspace_id` only as workspace metadata.
    - When no checkout exists, compute the deterministic absolute `.opencode/.bbq-worktrees/{branch-slug}` path. Use `origin/{branch-name}` as the base when only a remote ticket branch exists; otherwise use the resolved remote default branch. Run `herdr worktree create --cwd "{workflow_root}" --branch "{branch-name}" --base "{base-ref}" --path "{worktree-path}" --label "{ticket-id}" --no-focus`.
    - Parse the authoritative checkout path from `.result.worktree.path` (or its matching `.result.worktrees` entry), never from `.result.workspace.workspace_id`.
    - If Herdr is configured but `HERDR_ENV=1` is absent, state that native fallback is active and use the native fallback `git-worktree-prepare` skill.
    - The `git-worktree-find` skill remains the native fallback provider for continued review work in `/bbq.taste`.
    - Capture outputs as `workflow_root`, `branch_name`, and `worktree_path`.
    - Under a pre-resolved handoff, the orchestrator has already synchronized local files, prepared ignored runtime House Rules, and configured workflow-state ignores; do not rerun source-checkout scripts. Under either directly selected provider, run `"{workflow_root}/.opencode/scripts/sync-worktree-local-files.sh" "{workflow_root}" "{worktree-path}"` after resolving the path, then run `bash "{workflow_root}/.opencode/scripts/ensure-workflow-state-ignore.sh" "{worktree-path}"`. Worktree behavior is default-on and paths remain under `.opencode/.bbq-worktrees/`.
7. From this point forward, run **all git, code, test, and documentation actions in that worktree path**.
    - Prefer explicit path-aware commands (`git -C "{worktree_path}" ...`) when possible.
    - Do not rely on the process current directory; this applies whether `worktree_path` is the root checkout or a dedicated worktree.

## Fire the Grill

8. Use the `progress-doc` skill in `worktree_path` to create or resume `.opencode/.bbq-state/{branch-name}.md`.
9. Implement the ticket:
    - Write or modify unit tests first.
    - Add integration tests when an API contract changes.
    - Implement the smallest change that satisfies the plan and House Rules.
    - Update ignored workflow state after meaningful milestones, decisions, or blockers.
10. Detect and run all relevant lint, build, typecheck, and test commands. Do not rely on post-commit validation because no implementation commit exists yet.
11. Evaluate the session for durable technical learnings:
    - Capture only surprising behavior, reusable patterns, workarounds, or non-obvious architectural decisions.
    - Skip tracked learning changes when the work was routine.
    - When a learning is useful, update `docs/learnings/` with the `learnings` skill before review so it can ship with the coherent implementation change.
12. Stage the complete candidate change, including related tests and durable documentation, while excluding `.opencode/.bbq-state/` and unrelated files. Capture the staged tree as `reviewed_tree` with `git write-tree` immediately before each review round.
13. Run the Implementation Review Gate below against the staged candidate.
14. If the gate passes, run `git write-tree` again and require it to equal `reviewed_tree`. Then use the `git-commit` skill's pre-reviewed staged candidate mode from `worktree_path`; it must preserve the reviewed index without restaging. Commit only after the Implementation Review Gate passes.
    - Prefer one coherent commit for the ticket.
    - Use multiple commits only when the changes are independently understandable and shippable; never split commits merely by workflow phase or artifact type.

## Push and Create PR

15. Use the `git-push-remote` skill with explicit `worktree_path` and `branch_name` to push all commits to remote.
16. Create a pull request using GitHub MCP with:
    - Clear title referencing the ticket.
    - Description summarizing the implementation, validation, and durable learnings.
    - House Rules compliance summary and approved exception notes, if any.
    - Worktree context note and link to the Linear ticket.
17. Move the ticket to "In Review" status using Linear MCP.
18. Mark the ignored workflow state complete after the push, pull request, and ticket transition succeed. This state update is local bookkeeping and must not create another commit or push.

## Implementation Review Gate

After implementation, validation, learning capture, and staging are complete, use the Task tool to spawn the `health-inspector` subagent from `worktree_path`. Give it the ticket ID, user context, `workflow_root`, `worktree_path`, the authoritative `house_rules_path` selected above, and this task: review the staged candidate and any existing ticket-branch commits against the full Linear ticket, Technical Plan, House Rules, relevant learnings, and validation results.

- If it returns `REVIEW_RESULT: PASS`, create the implementation commit.
- If it returns `REVIEW_RESULT: CHANGES_REQUIRED`, resolve every blocking and important finding in `worktree_path`, update tests and durable documentation as needed, rerun relevant validation, restage the complete candidate, refresh `reviewed_tree` with `git write-tree`, update ignored workflow state, and spawn a fresh `health-inspector` review. Do not commit between review rounds.
- Run at most 3 review-and-revision rounds total. If the work still does not pass after round 3, do not commit, push, create a PR, or move the ticket to "In Review". Stop and ask the user for further instructions, including the unresolved findings.

## Terminal Result

Include exactly one result line in every response:

```text
BBQ_PHASE_RESULT: COMPLETE
```

When a user decision or clarification is needed, use the `question` tool and wait for its answer in the current session. Do not emit `BBQ_PHASE_RESULT: BLOCKED` before calling the `question` tool. Return `BBQ_PHASE_RESULT: BLOCKED` only if the phase still cannot continue after the user interaction. Return `BBQ_PHASE_RESULT: FAILED` if the phase cannot complete because of an execution error. Emit `COMPLETE` only after the implementation commit is pushed, the pull request exists, the ticket is moved to "In Review", and the ignored workflow state is marked complete.
