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
#   --worktree-root <path>   Optional per-project worktree root override
#   --skip-docker            Skip Docker image build/pull
#   --skip-env               Skip environment variable setup
#   --help                   Show this help message
#
# Examples:
#   ./init.sh /path/to/my-project
#   ./init.sh /path/to/my-project --auth-method pat
#   ./init.sh /path/to/my-project --auth-method app --pem ~/keys/github-app.pem
#   ./init.sh /path/to/my-project --worktree-root ../custom-worktrees
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
WORKTREE_ROOT_EXPLICIT=false
WORKTREE_PROJECT_ROOT=""
SKIP_DOCKER=false
SKIP_ENV=false

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
	--worktree-root)
		WORKTREE_ROOT="$2"
		WORKTREE_ROOT_EXPLICIT=true
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
		echo "  --worktree-root <path>   Optional per-project worktree root override"
		echo "                           relative paths resolve from target project"
		echo "  --skip-docker            Skip firing up the grill"
		echo "  --skip-env               Skip stocking the pantry"
		echo "  --help                   Show this menu"
		echo ""
		echo "Examples:"
		echo "  $0 /path/to/my-project"
		echo "  $0 /path/to/my-project --auth-method pat"
		echo "  $0 /path/to/my-project --auth-method app --pem ~/keys/github-app.pem"
		echo "  $0 /path/to/my-project --worktree-root ../custom-worktrees"
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

# Resolve to absolute path
TARGET_PATH="$(cd "$TARGET_PATH" 2>/dev/null && pwd)" || {
	echo -e "${RED}🔥 Kitchen not found: $TARGET_PATH${NC}"
	exit 1
}

TARGET_PARENT="$(dirname "$TARGET_PATH")"
TARGET_PROJECT_NAME="$(basename "$TARGET_PATH")"

# Worktree root for this project's BBQ stations
if [ "$WORKTREE_ROOT_EXPLICIT" = true ]; then
	if [[ "$WORKTREE_ROOT" == ~* ]]; then
		WORKTREE_ROOT="${HOME}${WORKTREE_ROOT:1}"
	fi
	if [[ "$WORKTREE_ROOT" != /* ]]; then
		WORKTREE_ROOT="$TARGET_PATH/$WORKTREE_ROOT"
	fi
	WORKTREE_ROOT_PARENT="$(dirname "$WORKTREE_ROOT")"
	WORKTREE_ROOT_BASENAME="$(basename "$WORKTREE_ROOT")"
	if [ -d "$WORKTREE_ROOT_PARENT" ]; then
		WORKTREE_ROOT="$(cd "$WORKTREE_ROOT_PARENT" && pwd)/$WORKTREE_ROOT_BASENAME"
	fi
	WORKTREE_ROOT="${WORKTREE_ROOT%/}"
else
	WORKTREE_ROOT="$TARGET_PARENT/.bbq-worktrees"
fi

WORKTREE_PROJECT_ROOT="$WORKTREE_ROOT/$TARGET_PROJECT_NAME"
WORKTREE_PERMISSION_PATH="$WORKTREE_PROJECT_ROOT/**"
SOURCE_PERMISSION_PATH="$TARGET_PATH/**"

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
echo -e "  Worktree root:    ${GREEN}$WORKTREE_PROJECT_ROOT${NC}"
if [ "$WORKTREE_ROOT_EXPLICIT" = true ]; then
	echo -e "  Worktree mode:    ${CYAN}custom (project-specific override)${NC}"
else
	echo -e "  Worktree mode:    ${CYAN}default sibling layout${NC}"
fi
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
elif [ "$AUTH_METHOD" = "pat" ]; then
	# PAT setup
	echo -e "  Add these ingredients to ${CYAN}~/.zshenv${NC}:"
	echo ""
	echo "    export BBQ_LINEAR_API_KEY=\"lin_api_xxxxx\""
	echo "    export BBQ_GITHUB_PAT=\"github_pat_xxxxx\""
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
		echo -e "  Add these ingredients to ${CYAN}~/.zshenv${NC}:"
		echo ""
		echo "    export BBQ_LINEAR_API_KEY=\"lin_api_xxxxx\""
		echo "    export BBQ_GITHUB_APP_ID=\"123456\""
		echo "    export BBQ_GITHUB_APP_INSTALLATION_ID=\"12345678\""
		echo "    export BBQ_GITHUB_APP_PRIVATE_KEY=\"<base64-encoded-key>\""
		echo ""
		echo "  Or run the prep script later:"
		echo "    $SCRIPT_DIR/mcp/github-app/scripts/setup-github-key.sh /path/to/key.pem"
	fi
fi
echo ""

# Step 3: Copy OpenCode configuration
echo -e "${YELLOW}━━━ 📋 Step 3: Hang the Menu ━━━${NC}"

OPENCODE_SOURCE="$SCRIPT_DIR/packages/opencode"

# Select the correct template based on auth method
if [ "$AUTH_METHOD" = "pat" ]; then
	OPENCODE_JSON_TEMPLATE="$OPENCODE_SOURCE/opencode.github-pat.json"
else
	OPENCODE_JSON_TEMPLATE="$OPENCODE_SOURCE/opencode.github-app.json"
fi

# Check if .opencode already exists
if [ -d "$TARGET_PATH/.opencode" ]; then
	echo -e "  ${YELLOW}Old menu found in kitchen${NC}"
	read -p "  Replace with new menu? [y/N] " -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		echo "  Keeping old menu"
	else
		mkdir -p "$TARGET_PATH/.opencode"
		cp -R "$OPENCODE_SOURCE/.opencode/." "$TARGET_PATH/.opencode/"
		echo -e "  ${GREEN}✓ New menu hung${NC}"
	fi
else
	mkdir -p "$TARGET_PATH/.opencode"
	cp -R "$OPENCODE_SOURCE/.opencode/." "$TARGET_PATH/.opencode/"
	echo -e "  ${GREEN}✓ Menu hung${NC}"
fi

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

# Remove legacy placeholder env lines when root files do not exist.
for legacy_env in .env .env.local .env.development .env.test; do
	if [ ! -e "$TARGET_PATH/$legacy_env" ]; then
		tmp_file="$WORKTREE_LOCAL_FILES_FILE.tmp"
		: >"$tmp_file"
		while IFS= read -r existing_line || [ -n "$existing_line" ]; do
			if [ "$existing_line" != "$legacy_env" ]; then
				printf "%s\n" "$existing_line" >>"$tmp_file"
			fi
		done <"$WORKTREE_LOCAL_FILES_FILE"
		mv "$tmp_file" "$WORKTREE_LOCAL_FILES_FILE"
	fi
done

# Auto-discover common environment files and add exact repo-relative paths
DISCOVERED_ENV_PATHS="$(
	find "$TARGET_PATH" \
		\( -path "$TARGET_PATH/.git" -o -path "$TARGET_PATH/.opencode" -o -path "$TARGET_PATH/node_modules" -o -path "$TARGET_PATH/.bbq-worktrees" \) -prune -o \
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

# Record per-project worktree root for git-worktree-prepare skill
WORKTREE_ROOT_FILE="$TARGET_PATH/.opencode/worktree-root"
printf "%s\n" "$WORKTREE_PROJECT_ROOT" >"$WORKTREE_ROOT_FILE"
echo -e "  ${GREEN}✓ Worktree root recorded (${WORKTREE_ROOT_FILE})${NC}"

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

if [ "$CONFIG_WRITTEN" = true ]; then
	if command -v python3 >/dev/null 2>&1; then
		if python3 - "$TARGET_PATH/opencode.json" "$WORKTREE_PERMISSION_PATH" "$SOURCE_PERMISSION_PATH" <<'PY'
import json
import sys

config_path = sys.argv[1]
worktree_permission_path = sys.argv[2]
source_permission_path = sys.argv[3]

with open(config_path, "r", encoding="utf-8") as f:
    data = json.load(f)

permission = data.get("permission")
if not isinstance(permission, dict):
    permission = {}
    data["permission"] = permission

external_directory = permission.get("external_directory")
if not isinstance(external_directory, dict):
    external_directory = {}
    permission["external_directory"] = external_directory

external_directory[worktree_permission_path] = "allow"
external_directory[source_permission_path] = "allow"

with open(config_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
		then
			echo -e "  ${GREEN}✓ External directory permissions added:${NC}"
			echo "    - $WORKTREE_PERMISSION_PATH"
			echo "    - $SOURCE_PERMISSION_PATH"
		else
			echo -e "  ${YELLOW}⚠ Could not auto-configure external_directory permissions${NC}"
			echo "    Add this manually in $TARGET_PATH/opencode.json:"
			echo "    \"permission\": { \"external_directory\": { \"$WORKTREE_PERMISSION_PATH\": \"allow\", \"$SOURCE_PERMISSION_PATH\": \"allow\" } }"
		fi
	else
		echo -e "  ${YELLOW}⚠ python3 not found; add external_directory permissions manually${NC}"
		echo "    Add this in $TARGET_PATH/opencode.json:"
		echo "    \"permission\": { \"external_directory\": { \"$WORKTREE_PERMISSION_PATH\": \"allow\", \"$SOURCE_PERMISSION_PATH\": \"allow\" } }"
	fi
else
	echo -e "  ${YELLOW}⚠ Config was not replaced; ensure this permission exists in your current opencode.json:${NC}"
	echo "    \"permission\": { \"external_directory\": { \"$WORKTREE_PERMISSION_PATH\": \"allow\", \"$SOURCE_PERMISSION_PATH\": \"allow\" } }"
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              🍖 KITCHEN IS OPEN! 🍖                          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Kitchen ready at: ${GREEN}$TARGET_PATH${NC}"
echo -e "  Auth method: ${CYAN}$AUTH_METHOD${NC}"
echo ""
echo -e "${BLUE}  Next steps:${NC}"
echo ""
if [ "$SKIP_ENV" = false ]; then
	echo "    1. Stock the pantry (see ingredients above)"
	echo "    2. source ~/.zshenv"
	echo "    3. cd $TARGET_PATH && opencode"
else
	echo "    1. source ~/.zshenv"
	echo "    2. cd $TARGET_PATH && opencode"
fi
echo ""
echo -e "${BLUE}  Worktree sandbox rules:${NC}"
echo ""
echo "    external_directory allows:"
echo "    - $WORKTREE_PERMISSION_PATH"
echo "    - $SOURCE_PERMISSION_PATH"
echo ""
echo "    Worktree location is project-specific by default:"
echo "    $WORKTREE_PROJECT_ROOT"
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
