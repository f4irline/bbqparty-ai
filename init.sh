#!/bin/bash
#
# 🍖 BBQ Party - Open the Kitchen
#
# Usage:
#   ./init.sh <target-project-path> [options]
#
# Options:
#   --pem <path>        Path to GitHub App private key (.pem file)
#   --skip-docker       Skip Docker image build (if already built)
#   --skip-env          Skip environment variable setup
#   --help              Show this help message
#
# Examples:
#   ./init.sh /path/to/my-project --pem ~/keys/github-app.pem
#   ./init.sh . --skip-docker
#   ./init.sh /path/to/project --skip-env

set -e

# Get the directory where this script lives (bbqparty root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

# Default options
TARGET_PATH=""
PEM_PATH=""
SKIP_DOCKER=false
SKIP_ENV=false

# Parse arguments
while [[ $# -gt 0 ]]; do
	case $1 in
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
	--help | -h)
		echo "🍖 BBQ Party - Open the Kitchen"
		echo ""
		echo "Usage: $0 <target-project-path> [options]"
		echo ""
		echo "Options:"
		echo "  --pem <path>        Path to GitHub App private key (secret sauce)"
		echo "  --skip-docker       Skip firing up the grill"
		echo "  --skip-env          Skip stocking the pantry"
		echo "  --help              Show this menu"
		echo ""
		echo "Examples:"
		echo "  $0 /path/to/my-project --pem ~/keys/github-app.pem"
		echo "  $0 . --skip-docker"
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
echo ""

# Step 1: Build Docker image
echo -e "${YELLOW}━━━ 🔥 Step 1: Fire Up the Grill ━━━${NC}"
if [ "$SKIP_DOCKER" = true ]; then
	echo -e "  Skipping (grill already hot)"
elif docker image inspect bbqparty/github-app-mcp >/dev/null 2>&1; then
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
echo ""

# Step 2: Environment setup
echo -e "${YELLOW}━━━ 🧂 Step 2: Stock the Pantry ━━━${NC}"
if [ "$SKIP_ENV" = true ]; then
	echo -e "  Skipping (pantry already stocked)"
elif [ -n "$PEM_PATH" ]; then
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
	echo "  Stock these ingredients in ~/.zshenv:"
	echo ""
	echo "    export BBQ_LINEAR_API_KEY=\"lin_api_xxxxx\""
	echo "    export BBQ_GITHUB_APP_ID=\"123456\""
	echo "    export BBQ_GITHUB_APP_INSTALLATION_ID=\"12345678\""
	echo "    export BBQ_GITHUB_APP_PRIVATE_KEY=\"<base64-encoded-key>\""
	echo ""
	echo "  Or run the prep script later:"
	echo "    $SCRIPT_DIR/mcp/github-app/scripts/setup-github-key.sh /path/to/key.pem"
fi
echo ""

# Step 3: Copy OpenCode configuration
echo -e "${YELLOW}━━━ 📋 Step 3: Hang the Menu ━━━${NC}"

OPENCODE_SOURCE="$SCRIPT_DIR/packages/opencode"

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

# Check if opencode.json already exists
if [ -f "$TARGET_PATH/opencode.json" ]; then
	echo -e "  ${YELLOW}Old config found${NC}"
	read -p "  Replace? [y/N] " -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		echo "  Keeping old config"
	else
		cp "$OPENCODE_SOURCE/opencode.json" "$TARGET_PATH/"
		echo -e "  ${GREEN}✓ Config updated${NC}"
	fi
else
	cp "$OPENCODE_SOURCE/opencode.json" "$TARGET_PATH/"
	echo -e "  ${GREEN}✓ Config installed${NC}"
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              🍖 KITCHEN IS OPEN! 🍖                          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Kitchen ready at: ${GREEN}$TARGET_PATH${NC}"
echo ""
echo -e "${BLUE}  Next steps:${NC}"
echo ""
if [ -z "$PEM_PATH" ] && [ "$SKIP_ENV" = false ]; then
	echo "    1. Stock the pantry (see ingredients above)"
	echo "    2. source ~/.zshenv"
	echo "    3. cd $TARGET_PATH && opencode"
else
	echo "    1. source ~/.zshenv"
	echo "    2. cd $TARGET_PATH && opencode"
fi
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
