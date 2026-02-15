# AGENTS.md - BBQ Party
Guidance for coding agents working in this repository.
Use this file as the default guide for build/lint/test commands and coding conventions.

## Project Overview
BBQ Party is a workflow automation toolkit connecting Linear ticket workflows to GitHub actions through OpenCode.
Key directories:
- `packages/opencode/` - portable OpenCode config package (`.opencode/commands`, `.opencode/skills`)
- `mcp/github-app/` - GitHub App MCP server (TypeScript)
- `docs/` - planning and project docs
- `init.sh` - setup/bootstrap script

## Rule Sources and Precedence
Read these in order before making changes:
1. This `AGENTS.md`
2. User task instructions
3. `.opencode/HOUSE_RULES.md` in the target project (if present)

Editor-specific rule files checked in this repo:
- `.cursor/rules/`: not present
- `.cursorrules`: not present
- `.github/copilot-instructions.md`: not present
If any of these files appear later, treat them as additional constraints.

## Build, Lint, and Test Commands
### Root (repository)
```bash
./init.sh /path/to/target-project
./init.sh /path/to/target-project --auth-method pat
./init.sh /path/to/target-project --auth-method app --pem /path/to/key.pem
```

### GitHub App MCP server (`mcp/github-app`)
```bash
pnpm install
pnpm build
pnpm dev
pnpm start
```

Docker build/run:
```bash
docker build -t bbqparty/github-app-mcp mcp/github-app
docker run --rm -i \
  -e GITHUB_APP_ID \
  -e GITHUB_APP_INSTALLATION_ID \
  -e GITHUB_APP_PRIVATE_KEY \
  bbqparty/github-app-mcp
```

### Lint/Test status (current state)
- No dedicated lint script exists in `mcp/github-app/package.json`.
- Use `pnpm build` as the required compile-time validation gate.
- No test framework is currently configured in this repository.
- If lint is added, prefer ESLint with `pnpm lint`.
- If tests are added, use Vitest with script: `"test": "vitest run"`.

Single-test execution (important):
```bash
pnpm test -- path/to/file.test.ts
```

## Code Style Guidelines
### Language and compiler
- TypeScript strict mode is enabled in `mcp/github-app/tsconfig.json`.
- Compiler baseline:
  - `target: ES2022`
  - `module: NodeNext`
  - `moduleResolution: NodeNext`

### Imports
- Group imports in this order:
  1. Node built-ins
  2. External packages
  3. Internal/local modules
- In NodeNext contexts, use `.js` extension where required (for example MCP SDK deep imports).
- Keep imports explicit and stable.
- Avoid wildcard imports except Node built-ins (for example `import * as fs from "fs"`).

### Formatting
- 2-space indentation
- Double quotes
- Semicolons
- Trailing commas in multiline objects/arrays/params
- Prefer readable wraps over dense one-liners

### Types and schemas
- Use explicit types when initialization is delayed (`let privateKey: string;`).
- Use `as const` for JSON-schema-like literals in MCP tool definitions.
- Keep `any` at boundaries only (dynamic MCP args).
- Do not spread `any` through core logic.
- Prefer narrow, descriptive types for returned payloads.

### Naming conventions
- Files: kebab-case (`setup-github-key.sh`)
- Variables/functions: camelCase (`graphqlWithAuth`)
- Types/interfaces/classes: PascalCase (`Server`)
- Constants/env vars: UPPER_SNAKE_CASE (`GITHUB_APP_ID`)
- MCP tool names: snake_case (`create_pull_request`)

### Error handling and logging
- Validate critical environment variables at startup and fail fast.
- Use `console.error` for logs/errors in MCP processes.
- Do not emit ad-hoc logs to stdout in MCP mode (stdout is protocol transport).
- Wrap async tool handlers in `try/catch`.
- Return structured MCP errors:
  - `content: [{ type: "text", text: "Error: ..." }]`
  - `isError: true`
- Return actionable error messages (what is missing, invalid, or failed).

### MCP response patterns
- Define each tool with `name`, `description`, and `inputSchema`.
- Always specify `required` fields.
- Return JSON with `JSON.stringify(value, null, 2)` unless plain text is expected.
- Keep response shapes stable for downstream automation.

## Git and Workflow Conventions
Branch naming format: `{type}/{ticket-id}-short-description`
Allowed types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`

Commit message format:
```text
{type}({scope}): {description}

{body}

Refs: {ticket-id}
```
Commit rules:
- Imperative mood
- Lowercase first letter
- No period at end of subject
- Subject max 72 characters

## Environment Variables and Security
Primary environment variables:
- `BBQ_LINEAR_API_KEY`
- `BBQ_GITHUB_PAT`
- `BBQ_GITHUB_APP_ID`
- `BBQ_GITHUB_APP_INSTALLATION_ID`
- `BBQ_GITHUB_APP_PRIVATE_KEY`

Security rules:
- Never commit `.pem`, `.env`, or credential files.
- Keep secrets in environment variables.
- Preserve `.gitignore` protection for `*.pem`.

## Learnings and Project Memory
- Store durable insights in `docs/learnings/`:
  - `gotchas.md`
  - `patterns.md`
  - `decisions.md`
  - `discoveries.md`
- Check learnings before implementation when the directory exists.
- Append new high-value learnings after significant work.
