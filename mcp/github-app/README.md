# GitHub App MCP Server

A Model Context Protocol (MCP) server that authenticates as a GitHub App, allowing AI agents to interact with GitHub as a bot rather than a personal user account.

## Features

- **GitHub App Authentication** - Actions appear as your app, not your personal account
- **Pull Request Management** - Create, list, search, and comment on PRs
- **Issue Management** - Create and manage issues
- **Repository Access** - List branches, read files, get repo info

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

# Option A: Path to private key file
export GITHUB_APP_PRIVATE_KEY_PATH="/path/to/your-app.private-key.pem"

# Option B: Private key content directly (useful for CI/CD)
export GITHUB_APP_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----
...
-----END RSA PRIVATE KEY-----"
```

### 4. Build and Run

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

Add to your `opencode.json`:

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

## Security Notes

- **Never commit your private key** - Add `*.pem` to `.gitignore`
- **Use environment variables** - Don't hardcode credentials
- **Limit permissions** - Only grant the permissions your workflows need
- **Limit repository access** - Install the app only on repos that need it

## License

MIT
