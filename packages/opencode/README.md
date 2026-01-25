# BBQ Party - OpenCode Workflow Package

This directory contains the OpenCode configuration for the BBQ Party workflow automation system. Copy these files to your project to enable Linear-to-GitHub workflow automation.

## Installation

1. **Copy to your project root:**
   ```bash
   cp -r .opencode /path/to/your/project/
   cp opencode.json /path/to/your/project/
   ```

2. **Set up environment variables** (add to `~/.zshenv` or similar):
   ```bash
   # Linear API key (recommend using a service account)
   export BBQ_LINEAR_API_KEY="lin_api_xxxxx"
   
   # GitHub App credentials
   export BBQ_GITHUB_APP_ID="123456"
   export BBQ_GITHUB_APP_INSTALLATION_ID="12345678"
   export BBQ_GITHUB_APP_PRIVATE_KEY="<base64-encoded-key>"
   ```

3. **Build the GitHub App MCP Docker image** (one-time setup):
   ```bash
   cd /path/to/bbqparty/mcp/github-app
   docker build -t bbqparty/github-app-mcp .
   ```

## What's Included

### Commands

| Command | Description |
|---------|-------------|
| `/bbq.research <ticket>` | Research a ticket, document findings, move to "Ready to Plan" |
| `/bbq.plan <ticket>` | Create technical plan, move to "Ready" |
| `/bbq.implement <ticket>` | Full implementation: branch, code, tests, PR |
| `/bbq.review <ticket>` | Address PR review comments |
| `/bbq.status <ticket>` | Show ticket status across Linear, Git, GitHub |

### Skills

| Skill | Description |
|-------|-------------|
| `git-branch-create` | Create branch: `{type}/{ticket}-{description}` |
| `git-push-remote` | Push with upstream tracking |
| `git-commit` | Conventional commits with ticket refs |
| `git-find-ticket-branch` | Find branch by ticket ID |
| `progress-doc` | Track progress in `docs/progress/` |

### Plugins

- **validate-changes** - Auto-runs lint/build/test after commits based on changed paths

## Linear Workflow

The commands expect these Linear statuses:

```
Backlog → In Research → Ready to Plan → Planning → Ready → In Progress → In Review → Done
```

## Customization

- Edit `.opencode/commands/*.md` to customize command behavior
- Edit `.opencode/skills/*/SKILL.md` to modify skill instructions
- Edit `opencode.json` to change MCP configuration

## Requirements

- [OpenCode](https://opencode.ai) CLI
- Docker (for GitHub App MCP)
- Linear workspace with appropriate statuses
- GitHub App installed on your repository
