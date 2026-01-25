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

## Kitchen Techniques (Skills)

| Skill | What It Does |
|-------|--------------|
| `git-branch-create` | Create branch: `{type}/{ticket}-{description}` |
| `git-push-remote` | Push with upstream tracking |
| `git-commit` | Conventional commits with ticket refs |
| `git-find-ticket-branch` | Find branch by ticket ID |
| `progress-doc` | Track progress in `docs/progress/` |

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
| MCP connections | `opencode.json` |

## Ingredients Required

- [OpenCode](https://opencode.ai) — Your sous chef
- Docker — For the grill (GitHub App MCP)
- Linear — Order management
- GitHub App — Bot identity

---

*Part of [BBQ Party](../../README.md) — Your AI Sous Chef for Code*
