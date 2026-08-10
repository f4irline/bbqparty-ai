# 📦 BBQ Party — The Recipe Book

This is the portable OpenCode configuration for BBQ Party. Drop it into any project to get your AI sous chef cooking.

## Installation

**Option A: Use the init script (recommended)**
```bash
# From bbqparty root
./init.sh /path/to/your/project --pem /path/to/key.pem
```

**Option B: Manual copy**
```bash
cp -r .opencode /path/to/your/project/
cp opencode.json /path/to/your/project/
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
| `progress-doc` | Track progress in `docs/progress/` |
| `learnings` | Manage project learnings in `docs/learnings/` |

## House Agents

| Agent | What It Does |
|-------|--------------|
| `sous-chef` | Research and planning agent for `/bbq.pantry` and `/bbq.prep` |
| `pitmaster` | Implementation and review-fix agent for `/bbq.fire` and `/bbq.taste` |
| `health-inspector` | Independent review subagent for research, plans, and implementations |

## The Health Inspector (Plugins)

- **validate-changes** — Auto-runs lint/build/test after commits

## Order Flow (Linear Statuses)

```
Backlog → In Research → Ready to Plan → Planning → Ready → In Progress → In Review → Done
           🔍              📋            🔪         ✅        🔥            👨‍🍳        🍽️
```

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

## Parallel Worktrees (Default)

- `/bbq.fire` and `/bbq.taste` default to a dedicated worktree per ticket branch
- This enables multiple agents to implement/review different tickets in parallel without branch checkout conflicts
- Worktrees use project-local directory layout `.opencode/.bbq-worktrees/{branch-slug}`
- `.opencode/.bbq-worktrees/` is ignored by default via `.opencode/.gitignore`
- Local-only file sync list lives in `.opencode/worktree-local-files`
- `init.sh` auto-discovers common `.env*` files and appends exact repo-relative mappings
- Cleanup: remove old stations with `git worktree remove <path>` and `git worktree prune`

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
