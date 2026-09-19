# 📦 BBQ Party — The Recipe Book

This is the portable OpenCode configuration for BBQ Party. Drop it into any project to get your AI sous chef cooking.

## Installation

**Option A: Use the init script (recommended)**
```bash
# From bbqparty root
./init.sh /path/to/your/project --pem /path/to/key.pem
./init.sh /path/to/your/project --herdr
```

**Option B: Manual copy**
```bash
cp -r .opencode /path/to/your/project/
cp opencode.json /path/to/your/project/
cp bbq-orchestrate.sh /path/to/your/project/
chmod +x /path/to/your/project/bbq-orchestrate.sh
```

Fire and Taste run `.opencode/scripts/ensure-workflow-state-ignore.sh` before creating local state, so manual installations also configure the repository's shared local exclude file for linked worktrees.

Choose an environment variable name for your Linear API key and export the
key under that name. Replace `YOUR_LINEAR_API_KEY_ENV_VAR` in the copied
`opencode.json` with the same name so OpenCode can read it:

```bash
export YOUR_LINEAR_API_KEY_ENV_VAR="lin_api_xxxxx"
```

When using the GitHub PAT config, likewise choose a variable name for the PAT,
export it, and replace `YOUR_GITHUB_PAT_ENV_VAR` in the copied `opencode.json`:

```bash
export YOUR_GITHUB_PAT_ENV_VAR="github_pat_xxxxx"
```

## The Menu

| Command | What It Does |
|---------|--------------|
| `/bbq.ticket <ticket>` | 📋 Check the ticket |
| `/bbq.pantry <ticket>` | 🔍 Check the pantry, document findings |
| `/bbq.prep <ticket>` | 🔪 Mise en place (technical planning) |
| `/bbq.fire <ticket>` | 🔥 Fire the grill (code, test, PR) |
| `/bbq.taste <ticket>` | 👨‍🍳 Address the critics (review comments) |
| `/bbq.rules` | 📜 Set up project house rules |
| `/bbq.learn` | 📝 Write down learnings from current session |

`/bbq.station` is an internal, non-interactive command used by the Herdr runner to resolve the ticket branch before it creates the ticket worktree.

## Kitchen Techniques (Skills)

| Skill | What It Does |
|-------|--------------|
| `git-branch-create` | Resolve branch: `{type}/{ticket}-{description}` |
| `git-worktree-prepare` | Create/reuse dedicated branch worktree |
| `git-worktree-find` | Resolve branch worktree path for continued work |
| `git-push-remote` | Push with upstream tracking |
| `git-commit` | Conventional commits with ticket refs |
| `git-find-ticket-branch` | Find branch by ticket ID |
| `github-pr-feedback` | Fetch unresolved PR threads and comments |
| `progress-doc` | Track resumable state in ignored `.opencode/.bbq-state/` |
| `learnings` | Manage project learnings in `docs/learnings/` |

## House Agents

| Agent | What It Does |
|-------|--------------|
| `station` | Resolves the ticket branch before Herdr creates or opens its worktree |
| `sous-chef` | Research and planning agent for `/bbq.pantry` and `/bbq.prep` |
| `pitmaster` | Implementation and review-fix agent for `/bbq.fire` and `/bbq.taste` |
| `health-inspector` | Independent review subagent for research, plans, and implementations |

## Quality Gates

- `/bbq.fire` runs project validation, stages the complete candidate, and asks `health-inspector` to review it before creating a commit.

## Order Flow (Linear Statuses)

```
Backlog → In Research → Ready to Plan → Planning → Ready → In Progress → In Review → Done
           🔍              📋            🔪         ✅        🔥            👨‍🍳        🍽️
```

### End-to-End Script

Run the workflow directly from the target project root:

```bash
./bbq-orchestrate.sh STU-15 "focus on performance"
```

When prior research or planning is complete, start later in the workflow with
`--start-phase`. Valid values are `pantry` (default), `prep`, and `fire`; the
script runs the selected phase and every later phase:

```bash
./bbq-orchestrate.sh --start-phase prep STU-15
./bbq-orchestrate.sh --start-phase fire STU-15
```

The script runs pantry, prep, and fire serially in the user’s terminal. It starts a loopback-only OpenCode server and prints a command for attaching the OpenCode TUI to each active phase. Run that command in another terminal when the agent needs an answer; the phase resumes in the same session and the script continues after its result marker. Each phase retains its existing review gate and status transitions. The script stops when a phase is blocked, fails, or emits no valid result marker, and stores its session and command response logs under `.opencode/.bbq-runs/`.

### Optional Herdr Runtime

`.opencode/bbq-config.json` selects `native` (the default) or `herdr`. Select Herdr during `init.sh` with `--herdr`, or answer Yes to its prompt. BBQ Party does not install Herdr; it validates a v0.9.0-or-newer CLI, downloads that exact version's official skill, and may update Herdr's user-level OpenCode integration.

With `runtime: "herdr"`, run the script from a Herdr shell pane (`HERDR_ENV=1`). The runner first invokes the internal `/bbq.station` command as a headless OpenCode preflight, then creates or opens the resolved ticket worktree. Every selected phase gets a separate retained tab and OpenCode agent inside that worktree's Herdr workspace, so the sessions appear in its worktree view. Phase agents explicitly load `opencode.json` and `.opencode` from the source checkout, which keeps newly installed, uncommitted BBQ configuration available inside the worktree. Before phase startup, the runner copies the current House Rules to ignored `.opencode/.bbq-runtime/HOUSE_RULES.md` in the worktree, avoiding external-directory access from the agent session. Before submitting a `/bbq.*` command, the runner waits three seconds for OpenCode to initialize its project command registry. Set `BBQ_HERDR_COMMAND_READY_DELAY_SECONDS` to a non-negative integer to adjust that delay. The runner emits `herdr agent attach <name>` after completion or when a phase blocks, and keeps station output, JSON responses, and plain transcripts in `.opencode/.bbq-runs/` for inspection. Without `HERDR_ENV=1`, it announces native fallback and runs the existing loopback OpenCode backend.

The `station` agent does not pin a model. Set `agent.station.model` in the target project's `opencode.json` when branch resolution should use a specific model; restart OpenCode after changing agent configuration.

To use an existing loopback server instead, set `BBQ_OPENCODE_URL`; the script will not start or stop that server:

```bash
BBQ_OPENCODE_URL=http://127.0.0.1:4096 ./bbq-orchestrate.sh STU-15
```

By default, the local server uses a random port and retries conflicts. Set `BBQ_OPENCODE_PORT` to use a fixed local port. The runner requires `curl` and `jq`. When `OPENCODE_SERVER_PASSWORD` is set, it forwards the password to its API requests without adding it to process arguments; set the same variable in the attaching terminal before running the printed command.

## Customizing the Menu

| What to Change | Where |
|----------------|-------|
| Command behavior | `.opencode/commands/*.md` |
| Kitchen techniques | `.opencode/skills/*/SKILL.md` |
| Custom agents | `opencode.json` (`agent`) |
| House rules template | `.opencode/templates/HOUSE_RULES.md` |
| MCP connections | `opencode.json` |

## Knowledge Management

BBQ Party includes a learnings system to capture and reuse project knowledge:

```
docs/learnings/
├── gotchas.md       # Traps and pitfalls
├── patterns.md      # How things are done here
├── decisions.md     # Architectural choices and rationale
└── discoveries.md   # How things work in this codebase
```

- `/bbq.fire` automatically extracts learnings after implementation
- `/bbq.learn` manually captures learnings from any conversation
- `/bbq.pantry`, `/bbq.prep`, `/bbq.fire` read learnings before starting work
- `/bbq.pantry`, `/bbq.prep`, `/bbq.fire` each run an independent review gate, with up to three review-and-revision rounds
- All `/bbq.*` commands apply `.opencode/HOUSE_RULES.md` when it exists

Implementation workflow state is local bookkeeping under ignored `.opencode/.bbq-state/`; it is never committed. `/bbq.fire` stages and reviews the complete candidate before committing, while related tests and durable learnings ship with the implementation they describe. `/bbq.taste` normally creates one coherent commit per review pass rather than one commit per comment.

`init.sh` also adds `/.opencode/.bbq-state/` to the repository's local Git exclude file so state remains ignored in ticket worktrees even before the installed OpenCode configuration is committed.

## Parallel Worktrees (Default)

- `/bbq.fire` and `/bbq.taste` default to a dedicated worktree per ticket branch
- This enables multiple agents to implement/review different tickets in parallel without branch checkout conflicts
- Worktrees use project-local directory layout `.opencode/.bbq-worktrees/{branch-slug}`
- `.opencode/.bbq-worktrees/` is ignored by default via `.opencode/.gitignore`
- Local-only file sync list lives in `.opencode/worktree-local-files`
- `init.sh` auto-discovers common `.env*` files and appends exact repo-relative mappings
- Cleanup: remove old stations with `git worktree remove <path>` and `git worktree prune`

When Herdr is active, the runner creates or opens the same deterministic worktree path before starting Pantry, Prep, or Fire, then runs the same local-file sync helper. Remove the associated workspace with `herdr worktree remove --workspace <workspace-id>`; it does not delete the branch and requires `--force` for a dirty worktree.

## House Rules

Run `/bbq.rules` to set up project-wide development principles:

- Creates `.opencode/HOUSE_RULES.md`
- Interactively gathers core principles and standards
- Provides governance for how the project should be built

## Ingredients Required

- [OpenCode](https://opencode.ai) — Your sous chef
- Docker — For the grill (GitHub App MCP)
- Linear — Order management
- GitHub App — Bot identity

---

*Part of [BBQ Party](../../README.md) — Your AI Sous Chef for Code*
