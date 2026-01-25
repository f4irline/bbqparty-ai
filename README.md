# BBQ Party - AI Workflow Automation

OpenCode-powered workflow automation for Linear tickets and GitHub PRs.

## Overview

This project uses [OpenCode](https://opencode.ai) to automate the software development lifecycle from ticket research to PR review. It integrates with:

- **Linear** - Issue tracking and status management
- **GitHub** - Pull requests and code review (via GitHub App for bot identity)

## Prerequisites

1. [OpenCode](https://opencode.ai) installed
2. [Bun](https://bun.sh) installed (for plugins)
3. [Node.js](https://nodejs.org) >= 18 (for GitHub App MCP server)
4. Linear API key
5. GitHub App (for bot identity) - see setup below

## Setup

### 1. Configure Linear MCP

Linear uses a remote MCP server with your API key.

**Get your Linear API key:**
1. Go to [Linear Settings → API](https://linear.app/settings/api)
2. Create a new personal API key
3. Copy the token

**Set environment variable:**
```bash
export BBQ_LINEAR_API_KEY="your-linear-api-key"
```

### 2. Configure GitHub App MCP

This project includes a custom GitHub App MCP server so actions appear as a bot, not your personal account.

#### 2.1 Create a GitHub App

1. Go to **GitHub Settings → Developer settings → GitHub Apps → New GitHub App**
2. Fill in:
   - **GitHub App name**: `BBQ Party Bot` (or your preferred name)
   - **Homepage URL**: Your project URL
   - **Webhook**: Uncheck "Active" (not needed)
3. Set **Permissions**:
   - **Repository permissions:**
     - Contents: Read and write
     - Issues: Read and write
     - Pull requests: Read and write
     - Metadata: Read-only
4. Click **Create GitHub App**
5. Note your **App ID**
6. Click **Generate a private key** (downloads a `.pem` file)

#### 2.2 Install the App

1. From your GitHub App settings, click **Install App**
2. Choose your account or organization
3. Select which repositories to grant access
4. Note the **Installation ID** from the URL after installing:
   - URL: `https://github.com/settings/installations/12345678`
   - Installation ID: `12345678`

#### 2.3 Build the MCP Server

```bash
cd mcp/github-app
pnpm install
pnpm run build
```

#### 2.4 Set Environment Variables

```bash
export BBQ_GITHUB_APP_ID="123456"
export BBQ_GITHUB_APP_KEY_PATH="/path/to/your-app.private-key.pem"
export BBQ_GITHUB_APP_INSTALLATION_ID="12345678"
```

Add these to your shell profile (`~/.zshrc`, `~/.bashrc`, etc.) for persistence.

### 3. MCP Configuration

The `opencode.json` is pre-configured to use:
- **Linear**: Remote MCP server
- **GitHub**: Local GitHub App MCP server

You can also configure MCP globally in `~/.config/opencode/opencode.json` if you want to use these across multiple projects.

### 4. Start OpenCode

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
.
├── opencode.json           # MCP configuration
├── mcp/
│   └── github-app/         # GitHub App MCP server
│       ├── src/index.ts    # Server implementation
│       ├── package.json
│       └── README.md       # Detailed setup instructions
└── .opencode/
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

## Security Notes

- **Never commit your GitHub App private key** - Add `*.pem` to `.gitignore`
- **Use environment variables** - Don't hardcode API keys or tokens
- **Limit GitHub App permissions** - Only grant what's needed
- **Limit repository access** - Install the app only on repos that need it

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
