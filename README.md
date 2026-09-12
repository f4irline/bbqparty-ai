```
                                    ╭───────────────────────────────────╮
                                    │      ~~~  ~~~  ~~~  ~~~  ~~~      │
                                    │    ~~~  SMOKE SIGNALS  ~~~        │
                                    │      ~~~  ~~~  ~~~  ~~~  ~~~      │
                                    ╰───────────────────────────────────╯
                                                    ║║║║
                                                   ╔════╗
                ╔═══════════════════════════════════════════════════════════════════╗
                ║  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐    ║
                ║  │ 🍖  │  │ 🌽  │  │ 🍗  │  │ 🥩  │  │ 🌶️  │  │ 🧅  │  │ 🍖  │    ║
                ║  └─────┘  └─────┘  └─────┘  └─────┘  └─────┘  └─────┘  └─────┘    ║
                ║═══════════════════════════════════════════════════════════════════║
                ║  ════════════════════════════════════════════════════════════════ ║
                ║  ════════════════════════════════════════════════════════════════ ║
                ║═══════════════════════════════════════════════════════════════════║
                ║   🔥  🔥  🔥  🔥  🔥  🔥  🔥  🔥  🔥  🔥  🔥  🔥  🔥  🔥  🔥  🔥   ║
                ╚═══════════════════════════════════════════════════════════════════╝
                    ╱╲      ╱╲      ╱╲      ╱╲      ╱╲      ╱╲      ╱╲      ╱╲

  ██████╗  ██████╗  ██████╗     ██████╗  █████╗ ██████╗ ████████╗██╗   ██╗
  ██╔══██╗██╔══██╗██╔═══██╗    ██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝╚██╗ ██╔╝
  ██████╔╝██████╔╝██║   ██║    ██████╔╝███████║██████╔╝   ██║    ╚████╔╝
  ██╔══██╗██╔══██╗██║▄▄ ██║    ██╔═══╝ ██╔══██║██╔══██╗   ██║     ╚██╔╝
  ██████╔╝██████╔╝╚██████╔╝    ██║     ██║  ██║██║  ██║   ██║      ██║
  ╚═════╝ ╚═════╝  ╚══▀▀═╝     ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝      ╚═╝

                         🍖  YOUR AI SOUS CHEF FOR CODE  🍖
```

<div align="center">

**You're the Head Chef. [OpenCode](https://opencode.ai) is your Sous Chef.**<br>
**Tickets are orders. Ship code like you're running a kitchen.**

</div>

---

## What's Cooking?

BBQ Party is a workflow automation toolkit that turns your Linear tickets into a well-oiled kitchen operation. Your AI sous chef handles the prep work, fires up the grill, and plates the code — you just call the shots.

| Kitchen Term | What It Really Means |
|--------------|---------------------|
| 📋 **Order** | Linear ticket |
| 🔪 **Prep Work** | Research & planning |
| 🔥 **Fire the Grill** | Implementation |
| 🍽️ **Plating** | PR ready for review |
| 👨‍🍳 **Taste Test** | Code review |
| ✅ **Served** | Merged to main |

## The Menu (Commands)

```
/bbq.ticket STU-15      Check the ticket
/bbq.pantry STU-15      What's in the pantry? (research)
/bbq.prep STU-15        Mise en place (planning)
/bbq.fire STU-15        Fire! (code, test, PR)
/bbq.taste STU-15       Address the critics
/bbq.rules              Set up house rules
/bbq.learn              Write down what you learned
```

Run the end-to-end workflow directly from a configured project:

```bash
./bbq-orchestrate.sh STU-15 "optional context"
```

The runner prints an `opencode attach` command for each active phase, so you can open its TUI in a second terminal when the agent needs input.

## Kitchen Layout

```
bbqparty/
├── 📦 packages/opencode/     # The recipe book — copy to your project
├── 🔥 mcp/github-app/        # The grill — GitHub bot that does the cooking
├── 📚 docs/                  # Kitchen manual
└── 🚀 init.sh                # Open the kitchen
```

---

## Opening the Kitchen

### Quick Start (Recommended)

```bash
# Fire up a new kitchen (interactive mode)
./init.sh /path/to/your/project
```

The init script will ask you to choose an authentication method:

| Method | Best For | Identity |
|--------|----------|----------|
| **Personal Access Token (PAT)** | Simple setup, full GitHub API | Actions appear as the PAT owner |
| **GitHub Application** | Bot identity, audit separation | Actions appear as the app |

This will:
1. 🔐 Choose authentication method (PAT or GitHub App)
2. 🔥 Fire up the grill (pull/build Docker image)
3. 🧂 Stock the pantry (configure credentials)  
4. 📋 Hang the menu (copy OpenCode config)
5. 🧭 Prepare project-local worktree root in `.opencode/.bbq-worktrees/`
6. 🥣 Ensure `.opencode/worktree-local-files` exists and auto-map common `.env*` files
7. 🧭 Install `./bbq-orchestrate.sh` for end-to-end ticket workflows

### Authentication Options

#### Option 1: Personal Access Token (Default)

The simplest setup. Uses [GitHub's official MCP server](https://github.com/github/github-mcp-server) with 60+ tools.

```bash
./init.sh /path/to/your/project --auth-method pat
```

**Pros:**
- Easy setup — just create a PAT
- 60+ GitHub tools available
- Can use a dedicated "service account" GitHub user

**Cons:**
- Actions appear as the PAT owner
- PAT needs broad permissions

**Creating a Fine-Grained Personal Access Token:**

1. Go to **GitHub Settings → Developer settings → Personal access tokens → Fine-grained tokens**
   - Direct link: https://github.com/settings/personal-access-tokens/new
2. Configure the token:
   - **Token name**: e.g., `BBQ Party MCP`
   - **Expiration**: Choose an appropriate expiration (90 days recommended)
   - **Repository access**: Select "All repositories" or choose specific repos
3. Set **Repository permissions** (required for BBQ Party):
   | Permission | Access Level | Used For |
   |------------|--------------|----------|
   | **Contents** | Read and write | Reading/writing files, creating branches |
   | **Issues** | Read and write | Creating and managing issues |
   | **Pull requests** | Read and write | Creating and managing PRs |
   | **Metadata** | Read-only | Basic repository info (auto-selected) |
4. Set **Organization permissions** (optional, for org features):
   | Permission | Access Level | Used For |
   |------------|--------------|----------|
   | **Members** | Read-only | Team access and mentions |
5. Click **Generate token** and copy the token (starts with `github_pat_`)

**Environment variables needed:**

Choose any environment variable name for your Linear API key. Export the key
under that name, then replace `YOUR_LINEAR_API_KEY_ENV_VAR` in `opencode.json`
with the same name. Do the same for your GitHub PAT using the
`YOUR_GITHUB_PAT_ENV_VAR` placeholder.

```bash
export YOUR_LINEAR_API_KEY_ENV_VAR="lin_api_xxxxx"
export YOUR_GITHUB_PAT_ENV_VAR="github_pat_xxxxx"
```

> **Tip:** Consider creating a dedicated GitHub account as a "service account" for cleaner audit trails. The AI's actions will appear as that account.

#### Option 2: GitHub Application

Use a dedicated bot identity. Uses custom MCP server with 12 essential tools.

```bash
./init.sh /path/to/your/project --auth-method app --pem /path/to/key.pem
```

**Pros:**
- Actions appear as the app (bot identity)
- Clear audit trail — bot commits vs human commits
- Fine-grained repository permissions

**Cons:**
- More complex setup (create app, install, get keys)
- Fewer tools (12 vs 60+)

**Environment variables needed:**

Choose any environment variable name for your Linear API key. Export the key
under that name, then replace `YOUR_LINEAR_API_KEY_ENV_VAR` in `opencode.json`
with the same name.

```bash
export YOUR_LINEAR_API_KEY_ENV_VAR="lin_api_xxxxx"
export BBQ_GITHUB_APP_ID="123456"
export BBQ_GITHUB_APP_INSTALLATION_ID="12345678"
export BBQ_GITHUB_APP_PRIVATE_KEY="<base64-encoded-key>"
```

See [mcp/github-app/README.md](mcp/github-app/README.md) for detailed GitHub App setup.

### Manual Setup

<details>
<summary>Click to expand manual instructions</summary>

#### For PAT Authentication

1. Create a Fine-Grained PAT at https://github.com/settings/personal-access-tokens/new
   - **Repository permissions**: Contents (R/W), Issues (R/W), Pull requests (R/W), Metadata (R)
   - **Organization permissions** (optional): Members (R)
2. Choose environment variable names for your Linear API key and GitHub PAT.
   Add them to `~/.zshenv`, then replace `YOUR_LINEAR_API_KEY_ENV_VAR` and
   `YOUR_GITHUB_PAT_ENV_VAR` in the copied `opencode.json` with the same names:
   ```bash
   export YOUR_LINEAR_API_KEY_ENV_VAR="lin_api_xxxxx"
   export YOUR_GITHUB_PAT_ENV_VAR="github_pat_xxxxx"
   ```
3. Pull the official GitHub MCP:
   ```bash
   docker pull ghcr.io/github/github-mcp-server
   ```
4. Copy the config:
   ```bash
    cp -r /path/to/bbqparty/packages/opencode/.opencode .
    cp /path/to/bbqparty/packages/opencode/opencode.github-pat.json ./opencode.json
    cp /path/to/bbqparty/packages/opencode/bbq-orchestrate.sh ./
    chmod +x ./bbq-orchestrate.sh
   ```

#### For GitHub App Authentication

1. Create a GitHub App (see [mcp/github-app/README.md](mcp/github-app/README.md))
2. Install it on your repo
3. Download the private key
4. Choose any environment variable name for your Linear API key. Add it to
   `~/.zshenv`, then replace `YOUR_LINEAR_API_KEY_ENV_VAR` in the copied
   `opencode.json` with the same name:
   ```bash
   export YOUR_LINEAR_API_KEY_ENV_VAR="lin_api_xxxxx"
   export BBQ_GITHUB_APP_ID="123456"
   export BBQ_GITHUB_APP_INSTALLATION_ID="12345678"
   export BBQ_GITHUB_APP_PRIVATE_KEY="<base64-encoded-key>"
   ```
5. Build the custom MCP:
   ```bash
   cd mcp/github-app
   docker build -t bbqparty/github-app-mcp .
   ```
6. Copy the config:
   ```bash
    cp -r /path/to/bbqparty/packages/opencode/.opencode .
    cp /path/to/bbqparty/packages/opencode/opencode.github-app.json ./opencode.json
    cp /path/to/bbqparty/packages/opencode/bbq-orchestrate.sh ./
    chmod +x ./bbq-orchestrate.sh
   ```

#### Open for Business

```bash
source ~/.zshenv
opencode
```

</details>

---

## The Ticket Window

Orders flow through the kitchen like this:

```
    📋 ORDER IN!
         │
         ▼
┌─────────────────┐
│  /bbq.pantry    │ ──▶ Check the pantry, document what we need
└────────┬────────┘
         ▼
┌─────────────────┐
│  /bbq.prep      │ ──▶ Mise en place — prep the ingredients
└────────┬────────┘
         ▼
┌─────────────────┐
│  /bbq.fire      │ ──▶ 🔥 FIRE! Cook it up, plate it (PR)
└────────┬────────┘
         ▼
┌─────────────────┐
│  /bbq.taste     │ ──▶ Critics sent it back? Re-season and re-fire
└────────┬────────┘
         ▼
    ✅ ORDER UP!
```

**Linear statuses move automatically:**
```
Backlog → In Research → Ready to Plan → Planning → Ready → In Progress → In Review → Done
                                                                                      🍽️
```

## Parallel Stations (Worktrees)

Run multiple tickets at once without branch checkout collisions:

- `/bbq.fire` and `/bbq.taste` use a dedicated git worktree per ticket branch by default
- Existing branch worktrees are reused so follow-up work stays in the same station
- BBQ Party uses a project-local layout: `.opencode/.bbq-worktrees/{branch-slug}`
- `.opencode/.bbq-worktrees/` is ignored by default via `.opencode/.gitignore`
- Clean up stale worktrees with `git worktree remove <path>` and `git worktree prune`
- Local-only files (for example `.env`) are mirrored using `.opencode/worktree-local-files`
- `init.sh` auto-discovers `.env`, `.env.local`, `.env.development`, and `.env.test` paths and maps them by exact repo-relative location

---

## What's in the Box?

### 📦 The Recipe Book (`packages/opencode/`)

Drop this into any project. It's got everything your sous chef needs:

- **Commands** — The menu items (`/bbq.pantry`, `/bbq.prep`, `/bbq.fire`, etc.)
- **Orchestration** — A script that runs the serial ticket workflow and records phase logs
- **Skills** — Kitchen techniques (branching, commits, progress tracking, learnings)
- **Templates** — House rules template for project standards
- **Plugins** — Auto-validation after commits (the health inspector)
- **MCP Config** — Connection to Linear and GitHub

### 🔥 The Grill (`mcp/github-app/`)

A Docker-based GitHub MCP server for **GitHub App authentication**. Actions appear as your bot, not your personal account. No more "why is the chef's name on every dish?"

> **Note:** If you're using PAT authentication, this custom MCP is not used — you'll use GitHub's official MCP server instead.

---

## Kitchen Rules (Security)

- 🔐 **Never commit the secret sauce** — `*.pem` stays out of git
- 🧂 **Keep ingredients in the pantry** — Use environment variables
- 👨‍🍳 **One chef, one station** — Limit GitHub App permissions
- 🍽️ **Service accounts for Linear** — So the bot gets credit, not you

---

## Further Reading

- [📦 OpenCode Package README](packages/opencode/README.md) — How to customize the menu
- [🔥 GitHub App MCP README](mcp/github-app/README.md) — Grill setup and maintenance

---

## License

MIT — *Free as in beer, free as in BBQ.*

---

<p align="center">
  <i>Now stop reading and start cooking.</i> 🍖
</p>
