# BBQ Party - AI Workflow Automation

OpenCode-powered workflow automation for Linear tickets and GitHub PRs.

## Overview

This project uses [OpenCode](https://opencode.ai) to automate the software development lifecycle from ticket research to PR review. It integrates with:

- **Linear** - Issue tracking and status management
- **GitHub** - Pull requests and code review (via GitHub App for bot identity)

## Project Structure

```
bbqparty/
├── packages/
│   └── opencode/              # ← Copy this to your project
│       ├── .opencode/         # Commands, skills, plugins
│       ├── opencode.json      # MCP configuration
│       └── README.md          # Usage instructions
├── mcp/
│   └── github-app/            # GitHub App MCP server (Docker)
│       ├── src/
│       ├── Dockerfile
│       ├── scripts/
│       │   └── setup-github-key.sh
│       └── README.md
└── docs/
    └── ...
```

## Quick Start

### 1. Build the GitHub App MCP Server

```bash
cd mcp/github-app
docker build -t bbqparty/github-app-mcp .
```

### 2. Set Up GitHub App

See [mcp/github-app/README.md](mcp/github-app/README.md) for detailed instructions:

1. Create a GitHub App with required permissions
2. Install it on your repository
3. Generate a private key
4. Run the setup script to configure your environment:

```bash
cd mcp/github-app
./scripts/setup-github-key.sh /path/to/private-key.pem
```

### 3. Set Environment Variables

Add to `~/.zshenv`:

```bash
# Linear API key (recommend using a service account for bot identity)
export BBQ_LINEAR_API_KEY="lin_api_xxxxx"

# GitHub App (set by setup-github-key.sh, or manually)
export BBQ_GITHUB_APP_ID="123456"
export BBQ_GITHUB_APP_INSTALLATION_ID="12345678"
export BBQ_GITHUB_APP_PRIVATE_KEY="<base64-encoded-key>"
```

### 4. Copy to Your Project

```bash
# From your target project root:
cp -r /path/to/bbqparty/packages/opencode/.opencode .
cp /path/to/bbqparty/packages/opencode/opencode.json .
```

### 5. Run OpenCode

```bash
opencode
```

## Commands

| Command | Description |
|---------|-------------|
| `/bbq.research <ticket>` | Research a ticket, document findings, move to "Ready to Plan" |
| `/bbq.plan <ticket>` | Create technical implementation plan, move to "Ready" |
| `/bbq.implement <ticket>` | Full implementation workflow: branch, code, test, PR |
| `/bbq.review <ticket>` | Address PR review comments with commit per comment |
| `/bbq.status <ticket>` | Show ticket status across Linear, Git, and GitHub |

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

## Linear Workflow Setup

The commands expect these statuses in your Linear workflow:

```
Backlog → In Research → Ready to Plan → Planning → Ready → In Progress → In Review → Done
```

See [packages/opencode/README.md](packages/opencode/README.md) for customization options.

## Components

### OpenCode Package (`packages/opencode/`)

The portable workflow configuration. Copy to any project to enable BBQ Party automation.

**Includes:**
- Commands (`/bbq.research`, `/bbq.plan`, etc.)
- Skills (git-branch-create, git-commit, etc.)
- Plugins (validate-changes)
- MCP configuration

### GitHub App MCP Server (`mcp/github-app/`)

A Docker-based MCP server that authenticates as a GitHub App, so actions appear as a bot.

**Features:**
- Pull request management
- Issue management
- Repository access
- Bot identity (not your personal account)

## Documentation

- [OpenCode Package README](packages/opencode/README.md) - Usage and customization
- [GitHub App MCP README](mcp/github-app/README.md) - Server setup and configuration

## Security Notes

- **Never commit private keys** - `*.pem` is in `.gitignore`
- **Use environment variables** - Don't hardcode API keys
- **Limit permissions** - Only grant what's needed
- **Use service accounts** - For clear bot attribution in Linear

## License

MIT
