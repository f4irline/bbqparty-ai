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
| `git-branch-create` | Create branch: `{type}/{ticket}-{description}` |
| `git-push-remote` | Push with upstream tracking |
| `git-commit` | Conventional commits with ticket refs |
| `git-find-ticket-branch` | Find branch by ticket ID |
| `progress-doc` | Track progress in `docs/progress/` |
| `learnings` | Manage project learnings in `docs/learnings/` |

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
