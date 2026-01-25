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
/bbq.status STU-15      Check the ticket
/bbq.pantry STU-15      What's in the pantry? (research)
/bbq.prep STU-15        Mise en place (planning)
/bbq.fire STU-15        Fire! (code, test, PR)
/bbq.taste STU-15       Address the critics
```

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
# Fire up a new kitchen
./init.sh /path/to/your/project --pem /path/to/github-app-key.pem
```

This will:
1. 🔥 Fire up the grill (build Docker image)
2. 🧂 Stock the pantry (configure credentials)  
3. 📋 Hang the menu (copy OpenCode config)

### Manual Setup

<details>
<summary>Click to expand manual instructions</summary>

#### 1. Fire Up the Grill

```bash
cd mcp/github-app
docker build -t bbqparty/github-app-mcp .
```

#### 2. Get Your Ingredients (GitHub App)

See [mcp/github-app/README.md](mcp/github-app/README.md) for the full recipe:

1. Create a GitHub App (your kitchen's identity)
2. Install it on your repo
3. Download the secret ingredient (private key)
4. Run the prep script:

```bash
./scripts/setup-github-key.sh /path/to/private-key.pem
```

#### 3. Stock the Pantry (Environment Variables)

Add to `~/.zshenv`:

```bash
export BBQ_LINEAR_API_KEY="lin_api_xxxxx"
export BBQ_GITHUB_APP_ID="123456"
export BBQ_GITHUB_APP_INSTALLATION_ID="12345678"
export BBQ_GITHUB_APP_PRIVATE_KEY="<base64-encoded-key>"
```

#### 4. Copy the Recipe Book

```bash
cp -r /path/to/bbqparty/packages/opencode/.opencode .
cp /path/to/bbqparty/packages/opencode/opencode.json .
```

#### 5. Open for Business

```bash
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

---

## What's in the Box?

### 📦 The Recipe Book (`packages/opencode/`)

Drop this into any project. It's got everything your sous chef needs:

- **Commands** — The menu items (`/bbq.pantry`, `/bbq.prep`, `/bbq.fire`, etc.)
- **Skills** — Kitchen techniques (branching, commits, progress tracking)
- **Plugins** — Auto-validation after commits (the health inspector)
- **MCP Config** — Connection to Linear and GitHub

### 🔥 The Grill (`mcp/github-app/`)

A Docker-based GitHub MCP server. Actions appear as your bot, not your personal account. No more "why is the chef's name on every dish?"

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
