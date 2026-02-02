# 🔥 The Grill — GitHub App MCP Server

A Model Context Protocol (MCP) server that authenticates as a GitHub App. This is what lets your AI sous chef interact with GitHub as a bot, not as you personally.

> *The grill does the cooking. You take the credit.*

> **Note:** This custom MCP server is only used when you choose **GitHub Application** authentication during init. If you're using **Personal Access Token (PAT)** authentication, BBQ Party uses [GitHub's official MCP server](https://github.com/github/github-mcp-server) instead, which provides 60+ tools.

## When to Use This vs PAT

| Feature | GitHub App (this MCP) | PAT (official MCP) |
|---------|----------------------|-------------------|
| **Identity** | Bot identity | User identity |
| **Available tools** | 12 essential tools | 60+ tools |
| **Setup complexity** | More complex | Simple |
| **Audit trail** | Clear separation | Actions as user |
| **Best for** | Production, teams | Personal use, quick start |

**Choose GitHub App if:**
- You want AI actions to appear as a bot, not as you
- You need clear audit separation between human and AI commits
- You're working in a team environment

**Choose PAT if:**
- You want quick setup
- You need access to more GitHub features (60+ tools)
- You're okay with actions appearing as your user (or a dedicated service account)

## Features

- **Bot Identity** — Actions appear as your app, not your personal account
- **Pull Request Management** — Create, list, search, and comment on PRs
- **Issue Management** — Create and manage issues
- **Repository Access** — List branches, read files, get repo info

## Available Tools

| Tool | Description |
|------|-------------|
| `create_pull_request` | Create a new pull request |
| `get_pull_request` | Get details of a specific PR |
| `list_pull_requests` | List PRs in a repository |
| `search_pull_requests` | Search PRs across repositories |
| `list_pr_comments` | List review and issue comments on a PR |
| `create_pr_comment` | Add a comment to a PR |
| `create_issue` | Create a new issue |
| `get_issue` | Get details of an issue |
| `create_issue_comment` | Comment on an issue |
| `get_repository` | Get repository information |
| `list_branches` | List branches in a repository |
| `get_file_contents` | Read file contents from a repository |

## Setup

### 1. Create a GitHub App

1. Go to **GitHub Settings → Developer settings → GitHub Apps → New GitHub App**
2. Fill in the required fields:
   - **GitHub App name**: Choose a unique name (e.g., `My Project Bot`)
   - **Homepage URL**: Your project URL or GitHub repo
   - **Webhook**: Uncheck "Active" (not needed for MCP)
3. Set **Permissions**:
   - **Repository permissions:**
     - Contents: Read and write
     - Issues: Read and write
     - Pull requests: Read and write
     - Metadata: Read-only
4. Click **Create GitHub App**
5. Note your **App ID** (shown on the app settings page)
6. Scroll down and click **Generate a private key**
   - This downloads a `.pem` file - keep it secure!

### 2. Install the App

1. From your GitHub App settings, click **Install App** in the sidebar
2. Choose your account or organization
3. Select repositories to grant access (or all repositories)
4. After installation, note the **Installation ID** from the URL:
   - URL format: `https://github.com/settings/installations/12345678`
   - Installation ID: `12345678`

### 3. Set Environment Variables

```bash
export GITHUB_APP_ID="123456"
export GITHUB_APP_INSTALLATION_ID="12345678"

# Option A: Path to private key file (for local development)
export GITHUB_APP_PRIVATE_KEY_PATH="/path/to/your-app.private-key.pem"

# Option B: Base64 encoded key (recommended for Docker/CI/CD)
export GITHUB_APP_PRIVATE_KEY="$(base64 < /path/to/your-app.private-key.pem | tr -d '\n')"

# Option C: Raw key content (works but may have JSON escaping issues)
export GITHUB_APP_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----
...
-----END RSA PRIVATE KEY-----"
```

**Tip:** Use the included setup script to add the base64-encoded key to your shell:
```bash
./scripts/setup-github-key.sh /path/to/your-app.private-key.pem
```

### 4. Build and Run

#### Option A: Docker (Recommended)

Build the image once and use it anywhere:

```bash
cd mcp/github-app
docker build -t bbqparty/github-app-mcp .
```

Or pull from a registry if published:
```bash
docker pull ghcr.io/your-org/github-app-mcp:latest
```

#### Option B: Local (Development)

```bash
cd mcp/github-app
pnpm install
pnpm build
pnpm start
```

Or for development:
```bash
pnpm dev
```

## Configuration in OpenCode

### Docker Configuration (Recommended)

Add to your project's `opencode.json`:

```json
{
  "mcp": {
    "github": {
      "type": "local",
      "command": [
        "docker", "run", "--rm", "-i",
        "-e", "GITHUB_APP_ID",
        "-e", "GITHUB_APP_INSTALLATION_ID",
        "-e", "GITHUB_APP_PRIVATE_KEY",
        "bbqparty/github-app-mcp"
      ],
      "environment": {
        "GITHUB_APP_ID": "{env:BBQ_GITHUB_APP_ID}",
        "GITHUB_APP_INSTALLATION_ID": "{env:BBQ_GITHUB_APP_INSTALLATION_ID}",
        "GITHUB_APP_PRIVATE_KEY": "{env:BBQ_GITHUB_APP_PRIVATE_KEY}"
      },
      "enabled": true
    }
  }
}
```

Note: With Docker, pass the private key content directly via `GITHUB_APP_PRIVATE_KEY` environment variable (not a file path).

### Local Configuration

If running locally without Docker:

```json
{
  "mcp": {
    "github": {
      "type": "local",
      "command": ["node", "mcp/github-app/dist/index.js"],
      "environment": {
        "GITHUB_APP_ID": "{env:GITHUB_APP_ID}",
        "GITHUB_APP_PRIVATE_KEY_PATH": "{env:GITHUB_APP_PRIVATE_KEY_PATH}",
        "GITHUB_APP_INSTALLATION_ID": "{env:GITHUB_APP_INSTALLATION_ID}"
      },
      "enabled": true
    }
  }
}
```

## Security Notes (Kitchen Rules)

- 🔐 **Never commit the secret sauce** — Add `*.pem` to `.gitignore`
- 🧂 **Keep ingredients in the pantry** — Use environment variables
- 👨‍🍳 **One chef, one station** — Limit permissions to what's needed
- 🍽️ **Invite-only kitchen** — Install the app only on repos that need it

## License

MIT

---

*Part of [BBQ Party](../../README.md) — Your AI Sous Chef for Code*
