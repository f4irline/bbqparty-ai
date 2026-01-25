# AGENTS.md - BBQ Party

This file provides guidance for AI coding agents working in the BBQ Party repository.

## Project Overview

BBQ Party is a workflow automation toolkit that integrates Linear tickets with GitHub via OpenCode. It uses a "kitchen" metaphor where tickets are "orders" and the AI is your "sous chef."

### Repository Structure

```
bbqparty/
├── packages/opencode/       # OpenCode configuration (commands, skills, plugins)
│   └── .opencode/
│       ├── commands/        # Slash commands (/bbq.*)
│       ├── skills/          # Reusable procedures (git-*, learnings)
│       ├── plugins/         # Event hooks (validate-changes)
│       └── templates/       # Document templates
├── mcp/github-app/          # GitHub App MCP server (TypeScript)
│   ├── src/index.ts         # Main MCP server implementation
│   └── dist/                # Compiled output
└── docs/                    # Documentation
```

## Build/Lint/Test Commands

### GitHub App MCP Server (`mcp/github-app/`)

```bash
# Install dependencies
pnpm install

# Build TypeScript
pnpm build          # or: tsc

# Run development mode
pnpm dev            # uses tsx for hot reload

# Run production
pnpm start          # runs dist/index.js

# Build Docker image
docker build -t bbqparty/github-app-mcp .
```

### OpenCode Plugin (`packages/opencode/.opencode/`)

```bash
# Install dependencies (from .opencode directory)
bun install
```

### Running Tests

This project does not have a test suite. When implementing features in projects that use BBQ Party, the `validate-changes` plugin automatically runs lint/build/test after git commits based on changed directories:

- `mobile/` changes: `npm run lint && npm run build && npm test`
- `api/` changes: `npm run lint && npm run build && npm test`
- `infra/` changes: `terraform validate && terraform plan`

## Code Style Guidelines

### TypeScript Configuration

From `mcp/github-app/tsconfig.json`:
- Target: ES2022
- Module: NodeNext
- Strict mode enabled
- Declaration files generated

### Imports

```typescript
// Use ESM imports with .js extension for local files
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

// Named imports preferred
import { Octokit } from "@octokit/rest";
import { createAppAuth } from "@octokit/auth-app";

// Node.js built-ins
import * as fs from "fs";
```

### Type Annotations

```typescript
// Explicit types for function parameters
let privateKey: string;

// Use 'as const' for literal types in objects
type: "object" as const,

// Type assertions with 'as any' for dynamic MCP tool arguments
const { owner, repo, title } = args as any;
```

### Error Handling

```typescript
// Exit immediately on missing required config
if (!GITHUB_APP_ID) {
  console.error("Error: GITHUB_APP_ID environment variable is required");
  process.exit(1);
}

// Try-catch with error messages for tool operations
try {
  const response = await octokit.pulls.create({ ... });
  return { content: [...] };
} catch (error: any) {
  return {
    content: [{ type: "text", text: `Error: ${error.message}` }],
    isError: true,
  };
}

// Async main with catch block
main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Files | kebab-case | `validate-changes.ts` |
| Variables/Functions | camelCase | `privateKey`, `createPullRequest` |
| Types/Interfaces | PascalCase | `Plugin`, `Server` |
| Constants | UPPER_SNAKE | `GITHUB_APP_ID` |
| MCP tool names | snake_case | `create_pull_request` |

### Git Conventions

**Branch naming**: `{type}/{ticket-id}-short-description`
- Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`
- Example: `feat/STU-15-user-authentication`

**Commit messages**: Conventional Commits with ticket reference
```
{type}({scope}): {description}

{body}

Refs: {ticket-id}
```

Example:
```
feat(api): add user authentication endpoint

Implement JWT-based authentication with refresh tokens.
Includes rate limiting and brute force protection.

Refs: STU-15
```

### Formatting

- 2-space indentation
- Double quotes for strings
- Semicolons required
- Max line length: ~100 characters (soft limit)
- Trailing commas in multi-line objects/arrays

## OpenCode Skills & Commands

### Available Commands

| Command | Purpose |
|---------|---------|
| `/bbq.ticket <id>` | Check ticket status |
| `/bbq.pantry <id>` | Research phase |
| `/bbq.prep <id>` | Technical planning |
| `/bbq.fire <id>` | Implementation |
| `/bbq.taste <id>` | Address review comments |
| `/bbq.rules` | Set up house rules |
| `/bbq.learn` | Extract learnings |

### Skills

- `git-branch-create`: Create branches with proper naming
- `git-commit`: Conventional commits with ticket refs
- `git-push-remote`: Push with upstream tracking
- `git-find-ticket-branch`: Find branch by ticket ID
- `progress-doc`: Track progress in `docs/progress/`
- `learnings`: Manage project knowledge base

### Learnings System

Store insights in `docs/learnings/`:
- `gotchas.md`: Traps and pitfalls
- `patterns.md`: How things are done here
- `decisions.md`: Architectural choices with rationale
- `discoveries.md`: How things work

## Environment Variables

Required for GitHub App MCP:
```bash
BBQ_LINEAR_API_KEY        # Linear API key
BBQ_GITHUB_APP_ID         # GitHub App ID
BBQ_GITHUB_APP_INSTALLATION_ID  # Installation ID
BBQ_GITHUB_APP_PRIVATE_KEY      # Base64-encoded private key
```

## Security Rules

- Never commit `.pem` files (private keys)
- Use environment variables for secrets
- Limit GitHub App permissions to what's needed
- Do not commit credentials.json, .env, or similar files
