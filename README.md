# BBQ Party - AI Workflow Automation

OpenCode-powered workflow automation for Linear tickets and GitHub PRs.

## Overview

This project uses [OpenCode](https://opencode.ai) to automate the software development lifecycle from ticket research to PR review. It integrates with:

- **Linear** - Issue tracking and status management
- **GitHub** - Pull requests and code review

## Prerequisites

1. [OpenCode](https://opencode.ai) installed
2. [Bun](https://bun.sh) installed (for plugins)
3. Linear MCP server configured
4. GitHub MCP server configured

## Setup

### 1. Configure MCP Servers

MCP servers can be configured either **globally** (recommended for tools you use across projects) or **per-project**.

#### Option A: Global Configuration (Recommended)

Edit `~/.config/opencode/opencode.json`:

```json
{
  "mcp": {
    "linear": {
      "type": "remote",
      "url": "https://mcp.linear.app/mcp",
      "headers": {
        "Authorization": "Bearer {env:BBQ_LINEAR_API_KEY}"
      },
      "enabled": true
    },
    "github": {
      "type": "remote",
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": {
        "Authorization": "Bearer {env:BBQ_GITHUB_TOKEN}"
      },
      "enabled": true
    }
  }
}
```

This makes Linear and GitHub available in all your projects. The `{env:VAR}` syntax reads from environment variables.

#### Option B: Per-Project Configuration

Add the MCP config to your project's `opencode.json`. This is useful if:
- You want to share the config with your team via git
- You need project-specific MCP settings
- You want to keep credentials isolated per project

### 2. Set Environment Variables

Get your API tokens and add them to your shell profile (`~/.zshrc`, `~/.bashrc`, etc.):

```bash
export BBQ_LINEAR_API_KEY="your-linear-api-key"
export BBQ_GITHUB_TOKEN="your-github-token"
```

**Linear:**
1. Go to [Linear Settings → API](https://linear.app/settings/api)
2. Create a new personal API key
3. Copy the token

**GitHub:**
1. Go to [GitHub Settings → Developer settings → Personal access tokens](https://github.com/settings/tokens)
2. Generate a new token with `repo` and `read:org` scopes
3. Copy the token

### 3. Start OpenCode

```bash
opencode
```

## Commands

| Command | Description |
|---------|-------------|
| `/bbq.research STU-15` | Research a ticket, document findings, move to "Ready to Plan" |
| `/bbq.plan STU-15` | Create technical implementation plan, move to "Ready" |
| `/bbq.implement STU-15` | Full implementation workflow: branch, code, test, PR |
| `/bbq.review STU-15` | Address PR review comments with commit per comment |
| `/bbq.status STU-15` | Show ticket status across Linear, Git, and GitHub |

## Workflow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  /bbq.      │     │  /bbq.      │     │  /bbq.      │     │  /bbq.      │
│  research   │ ──▶ │  plan       │ ──▶ │  implement  │ ──▶ │  review     │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
      │                   │                   │                   │
      ▼                   ▼                   ▼                   ▼
  In Research        Planning            In Progress          In Review
      │                   │                   │                   │
      ▼                   ▼                   ▼                   ▼
 Ready to Plan          Ready            Creates PR           Merged
```

## Skills

Skills are reusable instructions loaded on-demand by the agent.

| Skill | Description |
|-------|-------------|
| `git-branch-create` | Create branches: `{type}/{ticket}-{description}` |
| `git-push-remote` | Push with upstream tracking |
| `git-commit` | Conventional commits with ticket refs |
| `git-find-ticket-branch` | Find branch by ticket ID |
| `progress-doc` | Track progress in `docs/progress/` |

## Plugin

### validate-changes

Automatically runs after `git commit`:

| Changed Path | Validation |
|--------------|------------|
| `mobile/` | `npm run lint && npm run build && npm test` |
| `api/` | `npm run lint && npm run build && npm test` |
| `infra/` | `terraform validate && terraform plan` |

> **Note:** Plugins in `.opencode/plugins/` are auto-loaded. You don't need to list them in `opencode.json`.

## Project Structure

```
.opencode/
├── commands/           # Slash commands
│   ├── bbq.research.md
│   ├── bbq.plan.md
│   ├── bbq.implement.md
│   ├── bbq.review.md
│   └── bbq.status.md
├── plugins/            # Automation hooks (auto-loaded)
│   └── validate-changes.ts
├── skills/             # Reusable agent instructions
│   ├── git-branch-create/SKILL.md
│   ├── git-commit/SKILL.md
│   ├── git-find-ticket-branch/SKILL.md
│   ├── git-push-remote/SKILL.md
│   └── progress-doc/SKILL.md
└── package.json        # Plugin dependencies
```

## Linear Workflow Setup

The commands expect the following statuses to exist in your Linear workflow:

| Status | Description | Set By |
|--------|-------------|--------|
| `In Research` | Ticket is being researched | `/bbq.research` |
| `Ready to Plan` | Research complete, ready for planning | `/bbq.research` |
| `Planning` | Technical planning in progress | `/bbq.plan` |
| `Ready` | Planning complete, ready for implementation | `/bbq.plan` |
| `In Progress` | Implementation in progress | `/bbq.implement` |
| `In Review` | PR created, awaiting review | `/bbq.implement` |

### Creating Statuses in Linear

1. Go to **Settings** → **Teams** → **[Your Team]** → **Workflow**
2. Add the statuses above in order
3. Suggested status types:
   - `In Research` → Started
   - `Ready to Plan` → Unstarted
   - `Planning` → Started
   - `Ready` → Unstarted
   - `In Progress` → Started
   - `In Review` → Started

### Workflow Diagram

```
Backlog → In Research → Ready to Plan → Planning → Ready → In Progress → In Review → Done
            ▲              ▲               ▲          ▲          ▲            ▲
            │              │               │          │          │            │
        /bbq.research  /bbq.research   /bbq.plan  /bbq.plan  /bbq.implement /bbq.implement
         (start)         (end)         (start)     (end)       (start)       (end)
```

## Customization

### Linear Status Names

If your Linear workflow uses different status names, update them in the command files:

- `.opencode/commands/bbq.research.md`
- `.opencode/commands/bbq.plan.md`
- `.opencode/commands/bbq.implement.md`

### Branch Naming

Edit `.opencode/skills/git-branch-create/SKILL.md` to change the branch naming convention.

### Commit Format

Edit `.opencode/skills/git-commit/SKILL.md` to adjust the conventional commit format.

## License

MIT
