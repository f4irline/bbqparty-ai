# AGENTS.md — BBQ Party

Guidance for AI coding agents working in this repository.

## Project Overview

BBQ Party is a workflow automation toolkit integrating Linear tickets with GitHub via OpenCode.

## Repository Structure

```
bbqparty/
├── packages/opencode/           # OpenCode config (copy to target projects)
│   ├── .opencode/commands/      # Slash commands (/bbq.*)
│   ├── .opencode/skills/        # Reusable procedures (git-*, learnings)
│   └── opencode.json            # MCP server configuration
├── mcp/github-app/              # GitHub App MCP server (TypeScript)
│   └── src/index.ts             # Main server implementation
└── docs/                        # Documentation
```

## Build/Lint/Test Commands

### GitHub App MCP Server (`mcp/github-app/`)

```bash
pnpm install              # Install dependencies
pnpm build                # Build TypeScript (tsc)
pnpm dev                  # Development with hot reload (tsx)
pnpm start                # Run production (node dist/index.js)

# Docker
docker build -t bbqparty/github-app-mcp .
docker run --rm -i -e GITHUB_APP_ID -e GITHUB_APP_INSTALLATION_ID -e GITHUB_APP_PRIVATE_KEY bbqparty/github-app-mcp
```

### OpenCode Plugin (`packages/opencode/.opencode/`)

```bash
bun install               # Install dependencies
```

### Tests

No test framework currently configured. If adding tests, use Vitest or Jest.
Single test: `pnpm test -- path/to/file.test.ts`

## Code Style Guidelines

### TypeScript

- Target: ES2022 | Module: NodeNext | Strict mode enabled
- Use `.js` extension for MCP SDK imports

```typescript
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { Octokit } from "@octokit/rest";
import * as fs from "fs";
```

### Type Annotations

```typescript
let privateKey: string;                    // Explicit types for delayed init
type: "object" as const,                   // Literal types in schemas
const { owner, repo } = args as any;       // Dynamic MCP tool arguments
```

### Formatting

- 2 spaces indentation | Double quotes | Semicolons required
- Trailing commas in multi-line objects/arrays

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Files | kebab-case | `validate-changes.ts` |
| Variables/Functions | camelCase | `privateKey` |
| Types/Interfaces | PascalCase | `Server` |
| Constants | UPPER_SNAKE_CASE | `GITHUB_APP_ID` |
| MCP tool names | snake_case | `create_pull_request` |

### Error Handling

```typescript
// Fail fast on missing config
if (!GITHUB_APP_ID) {
  console.error("Error: GITHUB_APP_ID environment variable is required");
  process.exit(1);
}

// Wrap async operations
try {
  const response = await octokit.pulls.create({ ... });
} catch (error: any) {
  return { content: [{ type: "text", text: `Error: ${error.message}` }], isError: true };
}
```

## Git Conventions

### Branch Naming

Format: `{type}/{ticket-id}-short-description`

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`

Example: `feat/STU-15-user-authentication`

### Commit Messages

```
{type}({scope}): {description}

{body}

Refs: {ticket-id}
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `BBQ_LINEAR_API_KEY` | Linear API key |
| `BBQ_GITHUB_APP_ID` | GitHub App ID |
| `BBQ_GITHUB_APP_INSTALLATION_ID` | Installation ID |
| `BBQ_GITHUB_APP_PRIVATE_KEY` | Base64-encoded private key |

## Security Rules

- Never commit `.pem` files, `.env`, or `credentials.json`
- Use environment variables for all secrets

## OpenCode Commands

| Command | Purpose |
|---------|---------|
| `/bbq.ticket <id>` | Check ticket status |
| `/bbq.pantry <id>` | Research — gather context, check learnings |
| `/bbq.prep <id>` | Planning — technical design |
| `/bbq.fire <id>` | Implementation — code, test, PR |
| `/bbq.taste <id>` | Address review comments |
| `/bbq.rules` | Set up project house rules |
| `/bbq.learn` | Extract learnings from session |

## Learnings System

Store insights in `docs/learnings/`:

| File | Content |
|------|---------|
| `gotchas.md` | Traps, pitfalls, unexpected behavior |
| `patterns.md` | "How we do X here" conventions |
| `decisions.md` | Architectural choices with rationale |
| `discoveries.md` | How things work in the codebase |

Check learnings before starting work. Document new insights after implementation.
