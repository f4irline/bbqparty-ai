#!/bin/bash
#
# 🍖 BBQ Party - Open the Kitchen
#
# Usage:
#   ./init.sh <target-project-path> [options]
#
# Options:
#   --auth-method <app|pat>  GitHub authentication method (default: pat)
#   --pem <path>             Path to GitHub App private key (.pem file) [requires --auth-method app]
#   --skip-docker            Skip Docker image build/pull
#   --skip-env               Skip environment variable setup
#   --herdr                  Use Herdr for persistent phase agents and worktrees
#   --help                   Show this help message
#
# Examples:
#   ./init.sh /path/to/my-project
#   ./init.sh /path/to/my-project --auth-method pat
#   ./init.sh /path/to/my-project --auth-method app --pem ~/keys/github-app.pem
#   ./init.sh /path/to/my-project --herdr
#   ./init.sh . --skip-docker

set -e

# Get the directory where this script lives (bbqparty root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
ORANGE='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default options
TARGET_PATH=""
PEM_PATH=""
AUTH_METHOD=""
WORKTREE_ROOT=""
SKIP_DOCKER=false
SKIP_ENV=false
HERDR_MODE=""
HERDR_VERSION=""
HERDR_SKILL_URL=""

# Parse arguments
while [[ $# -gt 0 ]]; do
	case $1 in
	--auth-method)
		AUTH_METHOD="$2"
		if [[ "$AUTH_METHOD" != "app" && "$AUTH_METHOD" != "pat" ]]; then
			echo -e "${RED}🔥 Invalid auth method: $AUTH_METHOD (use 'app' or 'pat')${NC}"
			exit 1
		fi
		shift 2
		;;
	--pem)
		PEM_PATH="$2"
		shift 2
		;;
	--skip-docker)
		SKIP_DOCKER=true
		shift
		;;
	--skip-env)
		SKIP_ENV=true
		shift
		;;
	--herdr)
		HERDR_MODE=true
		shift
		;;
	--help | -h)
		echo "🍖 BBQ Party - Open the Kitchen"
		echo ""
		echo "Usage: $0 <target-project-path> [options]"
		echo ""
		echo "Options:"
		echo "  --auth-method <app|pat>  GitHub auth method (default: pat)"
		echo "                           pat = Personal Access Token (official GitHub MCP)"
		echo "                           app = GitHub Application (custom MCP)"
		echo "  --pem <path>             Path to GitHub App private key [requires --auth-method app]"
		echo "  --skip-docker            Skip firing up the grill"
		echo "  --skip-env               Skip stocking the pantry"
		echo "  --herdr                  Use Herdr for persistent phase agents and worktrees"
		echo "  --help                   Show this menu"
		echo ""
		echo "Examples:"
		echo "  $0 /path/to/my-project"
		echo "  $0 /path/to/my-project --auth-method pat"
		echo "  $0 /path/to/my-project --auth-method app --pem ~/keys/github-app.pem"
		echo "  $0 /path/to/my-project --herdr"
		exit 0
		;;
	-*)
		echo -e "${RED}🔥 Burnt! Unknown option: $1${NC}"
		exit 1
		;;
	*)
		if [ -z "$TARGET_PATH" ]; then
			TARGET_PATH="$1"
		else
			echo -e "${RED}🔥 Too many cooks! Only one kitchen path allowed${NC}"
			exit 1
		fi
		shift
		;;
	esac
done

# Validate target path
if [ -z "$TARGET_PATH" ]; then
	echo -e "${RED}🍖 Where's the kitchen? Target path required${NC}"
	echo "Usage: $0 <target-project-path> [options]"
	echo "Run '$0 --help' for the full menu"
	exit 1
fi

validate_herdr() {
	local version_output
	local major
	local minor
	local patch
	local worktree_help
	local agent_help
	local tab_help

	if ! command -v herdr >/dev/null 2>&1; then
		echo -e "${RED}Herdr mode requires the Herdr CLI.${NC}" >&2
		echo "Install it from https://github.com/herdrdev/herdr or with Homebrew: brew install herdrdev/tap/herdr" >&2
		return 1
	fi

	if ! command -v curl >/dev/null 2>&1; then
		echo -e "${RED}Herdr mode requires curl in PATH.${NC}" >&2
		return 1
	fi

	if ! version_output="$(herdr --version 2>&1)" || ! [[ "$version_output" =~ ([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
		echo -e "${RED}Could not parse a semantic Herdr version from: $version_output${NC}" >&2
		return 1
	fi

	major="${BASH_REMATCH[1]}"
	minor="${BASH_REMATCH[2]}"
	patch="${BASH_REMATCH[3]}"
	if [ "$major" -eq 0 ] && { [ "$minor" -lt 9 ] || { [ "$minor" -eq 9 ] && [ "$patch" -lt 0 ]; }; }; then
		echo -e "${RED}Herdr v0.9.0 or newer is required (found $version_output).${NC}" >&2
		return 1
	fi

	HERDR_VERSION="$major.$minor.$patch"
	HERDR_SKILL_URL="https://raw.githubusercontent.com/herdrdev/herdr/v$HERDR_VERSION/skills/herdr/SKILL.md"

	if ! worktree_help="$(herdr worktree help 2>&1)" || [[ "$worktree_help" != *list* ]] || [[ "$worktree_help" != *create* ]] || [[ "$worktree_help" != *open* ]]; then
		echo -e "${RED}Installed Herdr lacks required worktree list, create, or open commands.${NC}" >&2
		return 1
	fi

	if ! agent_help="$(herdr agent help 2>&1)" || [[ "$agent_help" != *start* ]] || [[ "$agent_help" != *prompt* ]] || [[ "$agent_help" != *wait* ]] || [[ "$agent_help" != *read* ]]; then
		echo -e "${RED}Installed Herdr lacks required agent start, prompt, wait, or read commands.${NC}" >&2
		return 1
	fi

	if ! tab_help="$(herdr tab help 2>&1)" || [[ "$tab_help" != *create* ]]; then
		echo -e "${RED}Installed Herdr lacks the required tab create command.${NC}" >&2
		return 1
	fi
}

install_herdr_skill() {
	local skill_dir="$TARGET_PATH/.opencode/skills/herdr"
	local skill_target="$skill_dir/SKILL.md"
	local skill_temp
	local first_line

	skill_temp="$(mktemp "$TARGET_PATH/.opencode/herdr-skill.XXXXXX")"
	if ! curl --fail --silent --show-error --location "$HERDR_SKILL_URL" > "$skill_temp"; then
		rm -f "$skill_temp"
		echo -e "${RED}Failed to download the Herdr skill from $HERDR_SKILL_URL${NC}" >&2
		return 1
	fi

	IFS= read -r first_line < "$skill_temp" || true
	if [ "$first_line" != "---" ] || ! grep -Fqx "name: herdr" "$skill_temp" || ! grep -Fq "Requires HERDR_ENV=1" "$skill_temp"; then
		rm -f "$skill_temp"
		echo -e "${RED}Downloaded Herdr skill failed validation: $HERDR_SKILL_URL${NC}" >&2
		return 1
	fi

	mkdir -p "$skill_dir"
	mv "$skill_temp" "$skill_target"
	echo -e "  ${GREEN}✓ Herdr skill installed (v$HERDR_VERSION)${NC}"
}

install_herdr_opencode_integration() {
	local integration_status
	local opencode_status

	if ! integration_status="$(herdr integration status 2>&1)"; then
		echo -e "${RED}Could not inspect the Herdr OpenCode integration.${NC}" >&2
		return 1
	fi

	opencode_status="$(printf '%s\n' "$integration_status" | grep '^opencode:' || true)"
	if [[ "$opencode_status" =~ ^opencode:[[:space:]]*current([[:space:]]|\(|$) ]]; then
		echo "  Herdr OpenCode integration is current"
		return 0
	fi

	echo "  Installing Herdr's user-level OpenCode integration..."
	if ! herdr integration install opencode; then
		echo -e "${RED}Failed to install the Herdr OpenCode integration.${NC}" >&2
		return 1
	fi
	echo "  Herdr integration installed"
}

# Resolve to absolute path
TARGET_PATH="$(cd "$TARGET_PATH" 2>/dev/null && pwd)" || {
	echo -e "${RED}🔥 Kitchen not found: $TARGET_PATH${NC}"
	exit 1
}

# Worktree root for this project (kept inside .opencode)
WORKTREE_ROOT="$TARGET_PATH/.opencode/.bbq-worktrees"

echo ""
echo -e "${ORANGE}  ____  ____   ___    ____   _    ____ _______   __${NC}"
echo -e "${ORANGE} | __ )| __ ) / _ \  |  _ \ / \  |  _ \_   _\ \ / /${NC}"
echo -e "${ORANGE} |  _ \|  _ \| | | | | |_) / _ \ | |_) || |  \ V / ${NC}"
echo -e "${ORANGE} | |_) | |_) | |_| | |  __/ ___ \|  _ < | |   | |  ${NC}"
echo -e "${ORANGE} |____/|____/ \__\_\ |_| /_/   \_\_| \_\|_|   |_|  ${NC}"
echo ""
echo -e "${BLUE}        🍖 Opening the Kitchen 🍖${NC}"
echo ""
echo -e "  Kitchen location: ${GREEN}$TARGET_PATH${NC}"
echo -e "  Worktree root:    ${GREEN}$WORKTREE_ROOT${NC}"
echo -e "  Worktree mode:    ${CYAN}project-local (.opencode/.bbq-worktrees)${NC}"
echo ""

# Authentication method selection
echo -e "${YELLOW}━━━ 🔐 GitHub Authentication ━━━${NC}"
if [ -z "$AUTH_METHOD" ]; then
	echo "  How would you like to authenticate the AI agent?"
	echo ""
	echo -e "  ${CYAN}[1]${NC} Personal Access Token (PAT) - user/service account identity"
	echo -e "      ${GREEN}+ Easier setup, 60+ tools via official GitHub MCP${NC}"
	echo -e "      ${YELLOW}- Actions appear as the PAT owner${NC}"
	echo ""
	echo -e "  ${CYAN}[2]${NC} GitHub Application - dedicated bot identity"
	echo -e "      ${GREEN}+ Actions appear as the app (bot identity)${NC}"
	echo -e "      ${YELLOW}- More complex setup, 12 tools via custom MCP${NC}"
	echo ""
	read -p "  Select [1]: " -n 1 -r auth_choice
	echo
	
	case $auth_choice in
	2)
		AUTH_METHOD="app"
		echo -e "  ${GREEN}✓ Using GitHub Application authentication${NC}"
		;;
	*)
		AUTH_METHOD="pat"
		echo -e "  ${GREEN}✓ Using Personal Access Token authentication${NC}"
		;;
	esac
else
	if [ "$AUTH_METHOD" = "pat" ]; then
		echo -e "  ${GREEN}✓ Using Personal Access Token authentication${NC}"
	else
		echo -e "  ${GREEN}✓ Using GitHub Application authentication${NC}"
	fi
fi

if [ -z "$HERDR_MODE" ]; then
	read -p "  Use Herdr for persistent phase agents and worktrees? [y/N] " -r herdr_choice || true
	if [[ "$herdr_choice" =~ ^[Yy]$ ]]; then
		HERDR_MODE=true
	else
		HERDR_MODE=false
	fi
fi

if [ "$HERDR_MODE" = true ]; then
	echo -e "  ${GREEN}✓ Using Herdr runtime${NC}"
	if ! validate_herdr; then
		exit 1
	fi
else
	echo -e "  ${GREEN}✓ Using native OpenCode runtime${NC}"
fi

# Validate --pem is only used with app auth
if [ -n "$PEM_PATH" ] && [ "$AUTH_METHOD" = "pat" ]; then
	echo -e "${YELLOW}  ⚠ Note: --pem flag is ignored when using PAT authentication${NC}"
	PEM_PATH=""
fi

echo ""

# Step 1: Docker image handling
echo -e "${YELLOW}━━━ 🔥 Step 1: Fire Up the Grill ━━━${NC}"
if [ "$SKIP_DOCKER" = true ]; then
	echo -e "  Skipping (grill already hot)"
elif [ "$AUTH_METHOD" = "pat" ]; then
	# Pull official GitHub MCP server
	echo "  Pulling official GitHub MCP server..."
	if docker pull ghcr.io/github/github-mcp-server; then
		echo -e "  ${GREEN}✓ Grill is hot and ready${NC}"
	else
		echo -e "  ${RED}✗ Failed to pull image${NC}"
		echo -e "  ${YELLOW}If you see auth errors, try: docker logout ghcr.io${NC}"
		exit 1
	fi
else
	# Build custom GitHub App MCP (existing behavior)
	if docker image inspect bbqparty/github-app-mcp >/dev/null 2>&1; then
		echo -e "  Grill ${GREEN}bbqparty/github-app-mcp${NC} is already hot"
		read -p "  Reheat? [y/N] " -n 1 -r
		echo
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			echo "  Firing up the grill..."
			docker build -t bbqparty/github-app-mcp "$SCRIPT_DIR/mcp/github-app"
			echo -e "  ${GREEN}✓ Grill is hot and ready${NC}"
		else
			echo "  Keeping current temperature"
		fi
	else
		echo "  Firing up the grill..."
		docker build -t bbqparty/github-app-mcp "$SCRIPT_DIR/mcp/github-app"
		echo -e "  ${GREEN}✓ Grill is hot and ready${NC}"
	fi
fi
echo ""

# Step 2: Environment setup
echo -e "${YELLOW}━━━ 🧂 Step 2: Stock the Pantry ━━━${NC}"
if [ "$SKIP_ENV" = true ]; then
	echo -e "  Skipping (pantry already stocked)"
else
	echo -e "  Choose any environment variable name for your Linear API key."
	echo -e "  Add it to ${CYAN}~/.zshenv${NC}:"
	echo ""
	echo "    export YOUR_LINEAR_API_KEY_ENV_VAR=\"lin_api_xxxxx\""
	echo ""
	echo "  Replace YOUR_LINEAR_API_KEY_ENV_VAR in opencode.json with that name."
	echo ""

	if [ "$AUTH_METHOD" = "pat" ]; then
		# PAT setup
		echo -e "  Choose any environment variable name for your GitHub PAT."
		echo -e "  Add it to ${CYAN}~/.zshenv${NC}:"
		echo ""
		echo "    export YOUR_GITHUB_PAT_ENV_VAR=\"github_pat_xxxxx\""
		echo ""
		echo "  Replace YOUR_GITHUB_PAT_ENV_VAR in opencode.json with that name."
		echo ""
		echo -e "  ${BLUE}Tip:${NC} Create a dedicated GitHub account for the AI agent"
		echo -e "       to use as a 'service account' for cleaner audit trails."
		echo ""
		echo -e "  ${BLUE}Create a Fine-Grained PAT:${NC}"
		echo -e "    ${CYAN}https://github.com/settings/personal-access-tokens/new${NC}"
		echo ""
		echo -e "  ${BLUE}Required Repository Permissions:${NC}"
		echo "    • Contents: Read and write"
		echo "    • Issues: Read and write"
		echo "    • Pull requests: Read and write"
		echo "    • Metadata: Read-only (auto-selected)"
		echo ""
		echo -e "  ${BLUE}Optional Organization Permissions:${NC}"
		echo "    • Members: Read-only (for team features)"
	else
		# GitHub App setup (existing behavior)
		if [ -n "$PEM_PATH" ]; then
			if [ ! -f "$PEM_PATH" ]; then
				echo -e "  ${RED}🔥 Secret sauce not found: $PEM_PATH${NC}"
				exit 1
			fi
			echo "  Adding the secret sauce..."
			"$SCRIPT_DIR/mcp/github-app/scripts/setup-github-key.sh" "$PEM_PATH"
			echo -e "  ${GREEN}✓ Secret sauce secured${NC}"
		else
			echo -e "  ${YELLOW}No secret sauce provided (--pem)${NC}"
			echo ""
			echo -e "  Add these GitHub ingredients to ${CYAN}~/.zshenv${NC}:"
			echo ""
			echo "    export BBQ_GITHUB_APP_ID=\"123456\""
			echo "    export BBQ_GITHUB_APP_INSTALLATION_ID=\"12345678\""
			echo "    export BBQ_GITHUB_APP_PRIVATE_KEY=\"<base64-encoded-key>\""
			echo ""
			echo "  Or run the prep script later:"
			echo "    $SCRIPT_DIR/mcp/github-app/scripts/setup-github-key.sh /path/to/key.pem"
		fi
	fi
fi
echo ""

# Step 3: Copy OpenCode configuration
echo -e "${YELLOW}━━━ 📋 Step 3: Hang the Menu ━━━${NC}"

OPENCODE_SOURCE="$SCRIPT_DIR/packages/opencode"
WORKFLOW_SCRIPT_SOURCE="$OPENCODE_SOURCE/bbq-orchestrate.sh"
WORKFLOW_SCRIPT_TARGET="$TARGET_PATH/bbq-orchestrate.sh"

# Select the correct template based on auth method
if [ "$AUTH_METHOD" = "pat" ]; then
	OPENCODE_JSON_TEMPLATE="$OPENCODE_SOURCE/opencode.github-pat.json"
else
	OPENCODE_JSON_TEMPLATE="$OPENCODE_SOURCE/opencode.github-app.json"
fi

# Check if .opencode already exists
MENU_INSTALLED=false
if [ -d "$TARGET_PATH/.opencode" ]; then
	echo -e "  ${YELLOW}Old menu found in kitchen${NC}"
	read -p "  Replace with new menu? [y/N] " -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		echo "  Keeping old menu"
		if [ "$HERDR_MODE" = true ]; then
			echo -e "${YELLOW}Herdr was not configured. Rerun init and replace the existing .opencode menu to enable it.${NC}" >&2
			exit 1
		fi
	else
		mkdir -p "$TARGET_PATH/.opencode"
		cp -R "$OPENCODE_SOURCE/.opencode/." "$TARGET_PATH/.opencode/"
		MENU_INSTALLED=true
		echo -e "  ${GREEN}✓ New menu hung${NC}"
	fi
else
	mkdir -p "$TARGET_PATH/.opencode"
	cp -R "$OPENCODE_SOURCE/.opencode/." "$TARGET_PATH/.opencode/"
	MENU_INSTALLED=true
	echo -e "  ${GREEN}✓ Menu hung${NC}"
fi

if [ "$MENU_INSTALLED" = true ]; then
	if [ "$HERDR_MODE" = true ]; then
		install_herdr_skill
		install_herdr_opencode_integration
		cat > "$TARGET_PATH/.opencode/bbq-config.json" <<'EOF'
{
  "runtime": "herdr"
}
EOF
	else
		cat > "$TARGET_PATH/.opencode/bbq-config.json" <<'EOF'
{
  "runtime": "native"
}
EOF
	fi
fi

cp "$WORKFLOW_SCRIPT_SOURCE" "$WORKFLOW_SCRIPT_TARGET"
chmod +x "$WORKFLOW_SCRIPT_TARGET"
echo -e "  ${GREEN}✓ Workflow script installed ($WORKFLOW_SCRIPT_TARGET)${NC}"

# Ensure worktree local-file sync list exists
WORKTREE_LOCAL_FILES_FILE="$TARGET_PATH/.opencode/worktree-local-files"
if [ ! -f "$WORKTREE_LOCAL_FILES_FILE" ]; then
	cat >"$WORKTREE_LOCAL_FILES_FILE" <<'EOF'
# Repo-relative local-only files or directories to mirror into ticket worktrees.
# One path per line. Blank lines and lines beginning with # are ignored.
#
# `init.sh` auto-discovers common .env files and appends exact repo-relative paths.
# Add additional paths manually when needed.
EOF
	echo -e "  ${GREEN}✓ Worktree local file list created (${WORKTREE_LOCAL_FILES_FILE})${NC}"
else
	echo "  Worktree local file list kept (${WORKTREE_LOCAL_FILES_FILE})"
fi

# Auto-discover common environment files and add exact repo-relative paths
DISCOVERED_ENV_PATHS="$(
	find "$TARGET_PATH" \
		\( -path "$TARGET_PATH/.git" -o -path "$TARGET_PATH/.opencode" -o -path "$TARGET_PATH/node_modules" \) -prune -o \
		-type f \( -name ".env" -o -name ".env.local" -o -name ".env.development" -o -name ".env.test" \) -print | LC_ALL=C sort
)"

DISCOVERED_ENV_COUNT=0
ADDED_ENV_COUNT=0

if [ -n "$DISCOVERED_ENV_PATHS" ]; then
	while IFS= read -r env_abs_path; do
		if [ -z "$env_abs_path" ]; then
			continue
		fi

		env_rel_path="${env_abs_path#"$TARGET_PATH"/}"
		if [ "$env_rel_path" = "$env_abs_path" ]; then
			continue
		fi

		DISCOVERED_ENV_COUNT=$((DISCOVERED_ENV_COUNT + 1))

		if ! grep -Fqx "$env_rel_path" "$WORKTREE_LOCAL_FILES_FILE"; then
			printf "%s\n" "$env_rel_path" >>"$WORKTREE_LOCAL_FILES_FILE"
			ADDED_ENV_COUNT=$((ADDED_ENV_COUNT + 1))
		fi
	done <<< "$DISCOVERED_ENV_PATHS"
fi

if [ "$DISCOVERED_ENV_COUNT" -gt 0 ]; then
	echo "  Env files discovered: $DISCOVERED_ENV_COUNT (added $ADDED_ENV_COUNT exact path mapping(s))"
else
	echo "  Env files discovered: 0 (using existing mappings)"
fi

# Ensure local worktree root exists inside .opencode
mkdir -p "$WORKTREE_ROOT"
echo -e "  ${GREEN}✓ Worktree root ready (${WORKTREE_ROOT})${NC}"

# Check if opencode.json already exists
CONFIG_WRITTEN=false
if [ -f "$TARGET_PATH/opencode.json" ]; then
	echo -e "  ${YELLOW}Old config found${NC}"
	read -p "  Replace? [y/N] " -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		echo "  Keeping old config"
	else
		cp "$OPENCODE_JSON_TEMPLATE" "$TARGET_PATH/opencode.json"
		CONFIG_WRITTEN=true
		echo -e "  ${GREEN}✓ Config updated (${AUTH_METHOD} mode)${NC}"
	fi
else
	cp "$OPENCODE_JSON_TEMPLATE" "$TARGET_PATH/opencode.json"
	CONFIG_WRITTEN=true
	echo -e "  ${GREEN}✓ Config installed (${AUTH_METHOD} mode)${NC}"
fi

if [ "$CONFIG_WRITTEN" = false ]; then
	echo -e "  ${YELLOW}⚠ Config was not replaced; keeping current opencode.json${NC}"
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              🍖 KITCHEN IS OPEN! 🍖                          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Kitchen ready at: ${GREEN}$TARGET_PATH${NC}"
echo -e "  Auth method: ${CYAN}$AUTH_METHOD${NC}"
if [ "$HERDR_MODE" = true ]; then
	echo -e "  Runtime: ${CYAN}herdr${NC}"
else
	echo -e "  Runtime: ${CYAN}native${NC}"
fi
echo ""
echo -e "${BLUE}  Next steps:${NC}"
echo ""
if [ "$HERDR_MODE" = true ]; then
	echo "    1. cd $TARGET_PATH && herdr"
	echo "    2. Start opencode in the Herdr pane, or run ./bbq-orchestrate.sh <ticket-id> from a Herdr shell pane"
elif [ "$SKIP_ENV" = false ]; then
	echo "    1. Stock the pantry (see ingredients above)"
	echo "    2. source ~/.zshenv"
	echo "    3. cd $TARGET_PATH && opencode"
else
	echo "    1. source ~/.zshenv"
	echo "    2. cd $TARGET_PATH && opencode"
fi
echo "    Run end-to-end workflow: ./bbq-orchestrate.sh <ticket-id>"
echo ""
echo -e "${BLUE}  Worktree station layout:${NC}"
echo ""
echo "    Base path:"
echo "    $WORKTREE_ROOT"
echo ""
echo "    Branch worktree path pattern:"
echo "    $WORKTREE_ROOT/{branch-name-with-slashes-replaced-by-dashes}"
echo ""
echo -e "${BLUE}  Today's Menu:${NC}"
echo ""
echo "    /bbq.ticket <order>   📋 Check the ticket"
echo "    /bbq.pantry <order>   🔍 What's in the pantry?"
echo "    /bbq.prep <order>     🔪 Mise en place"
echo "    /bbq.fire <order>     🔥 Fire the grill!"
echo "    /bbq.taste <order>    👨‍🍳 Address the critics"
echo "    /bbq.rules            📜 Set up house rules"
echo "    /bbq.learn            📝 Write down learnings"
echo ""
echo -e "  ${ORANGE}Now get cooking, chef! 🍖${NC}"
echo ""
