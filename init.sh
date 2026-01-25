#!/bin/bash
#
# BBQ Party - Initialize OpenCode workflow automation in a project
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
		echo "BBQ Party - Initialize OpenCode workflow automation"
		echo ""
		echo "Usage: $0 <target-project-path> [options]"
		echo ""
		echo "Options:"
		echo "  --pem <path>        Path to GitHub App private key (.pem file)"
		echo "  --skip-docker       Skip Docker image build"
		echo "  --skip-env          Skip environment variable setup"
		echo "  --help              Show this help message"
		echo ""
		echo "Examples:"
		echo "  $0 /path/to/my-project --pem ~/keys/github-app.pem"
		echo "  $0 . --skip-docker"
		exit 0
		;;
	-*)
		echo -e "${RED}Error: Unknown option $1${NC}"
		exit 1
		;;
	*)
		if [ -z "$TARGET_PATH" ]; then
			TARGET_PATH="$1"
		else
			echo -e "${RED}Error: Multiple target paths specified${NC}"
			exit 1
		fi
		shift
		;;
	esac
done

# Validate target path
if [ -z "$TARGET_PATH" ]; then
	echo -e "${RED}Error: Target project path is required${NC}"
	echo "Usage: $0 <target-project-path> [options]"
	echo "Run '$0 --help' for more information"
	exit 1
fi

# Resolve to absolute path
TARGET_PATH="$(cd "$TARGET_PATH" 2>/dev/null && pwd)" || {
	echo -e "${RED}Error: Target path does not exist: $TARGET_PATH${NC}"
	exit 1
}

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           BBQ Party - OpenCode Workflow Setup                ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Target project: ${GREEN}$TARGET_PATH${NC}"
echo ""

# Step 1: Build Docker image
echo -e "${YELLOW}━━━ Step 1: Docker Image ━━━${NC}"
if [ "$SKIP_DOCKER" = true ]; then
	echo -e "Skipping Docker build (--skip-docker)"
elif docker image inspect bbqparty/github-app-mcp >/dev/null 2>&1; then
	echo -e "Docker image ${GREEN}bbqparty/github-app-mcp${NC} already exists"
	read -p "Rebuild? [y/N] " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		echo "Building Docker image..."
		docker build -t bbqparty/github-app-mcp "$SCRIPT_DIR/mcp/github-app"
		echo -e "${GREEN}✓ Docker image built${NC}"
	else
		echo "Skipping rebuild"
	fi
else
	echo "Building Docker image..."
	docker build -t bbqparty/github-app-mcp "$SCRIPT_DIR/mcp/github-app"
	echo -e "${GREEN}✓ Docker image built${NC}"
fi
echo ""

# Step 2: Environment setup
echo -e "${YELLOW}━━━ Step 2: Environment Variables ━━━${NC}"
if [ "$SKIP_ENV" = true ]; then
	echo -e "Skipping environment setup (--skip-env)"
elif [ -n "$PEM_PATH" ]; then
	if [ ! -f "$PEM_PATH" ]; then
		echo -e "${RED}Error: PEM file not found: $PEM_PATH${NC}"
		exit 1
	fi
	echo "Setting up GitHub App private key..."
	"$SCRIPT_DIR/mcp/github-app/scripts/setup-github-key.sh" "$PEM_PATH"
	echo -e "${GREEN}✓ Private key configured${NC}"
else
	echo -e "${YELLOW}No --pem path provided${NC}"
	echo ""
	echo "To complete setup, you need to set these environment variables:"
	echo ""
	echo "  export BBQ_LINEAR_API_KEY=\"lin_api_xxxxx\""
	echo "  export BBQ_GITHUB_APP_ID=\"123456\""
	echo "  export BBQ_GITHUB_APP_INSTALLATION_ID=\"12345678\""
	echo "  export BBQ_GITHUB_APP_PRIVATE_KEY=\"<base64-encoded-key>\""
	echo ""
	echo "You can run the setup script later:"
	echo "  $SCRIPT_DIR/mcp/github-app/scripts/setup-github-key.sh /path/to/key.pem"
fi
echo ""

# Step 3: Copy OpenCode configuration
echo -e "${YELLOW}━━━ Step 3: Copy OpenCode Configuration ━━━${NC}"

OPENCODE_SOURCE="$SCRIPT_DIR/packages/opencode"

# Check if .opencode already exists
if [ -d "$TARGET_PATH/.opencode" ]; then
	echo -e "${YELLOW}Warning: .opencode already exists in target${NC}"
	read -p "Overwrite? [y/N] " -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		echo "Skipping .opencode copy"
	else
		rm -rf "$TARGET_PATH/.opencode"
		cp -r "$OPENCODE_SOURCE/.opencode" "$TARGET_PATH/"
		echo -e "${GREEN}✓ Copied .opencode/${NC}"
	fi
else
	cp -r "$OPENCODE_SOURCE/.opencode" "$TARGET_PATH/"
	echo -e "${GREEN}✓ Copied .opencode/${NC}"
fi

# Check if opencode.json already exists
if [ -f "$TARGET_PATH/opencode.json" ]; then
	echo -e "${YELLOW}Warning: opencode.json already exists in target${NC}"
	read -p "Overwrite? [y/N] " -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		echo "Skipping opencode.json copy"
	else
		cp "$OPENCODE_SOURCE/opencode.json" "$TARGET_PATH/"
		echo -e "${GREEN}✓ Copied opencode.json${NC}"
	fi
else
	cp "$OPENCODE_SOURCE/opencode.json" "$TARGET_PATH/"
	echo -e "${GREEN}✓ Copied opencode.json${NC}"
fi

# Add .pem to .gitignore if not already there
if [ -f "$TARGET_PATH/.gitignore" ]; then
	if ! grep -q '^\*\.pem$' "$TARGET_PATH/.gitignore" 2>/dev/null; then
		echo "" >>"$TARGET_PATH/.gitignore"
		echo "# Private keys" >>"$TARGET_PATH/.gitignore"
		echo "*.pem" >>"$TARGET_PATH/.gitignore"
		echo -e "${GREEN}✓ Added *.pem to .gitignore${NC}"
	fi
else
	echo "# Private keys" >"$TARGET_PATH/.gitignore"
	echo "*.pem" >>"$TARGET_PATH/.gitignore"
	echo -e "${GREEN}✓ Created .gitignore with *.pem${NC}"
fi

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                        Setup Complete!                       ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Project initialized: ${GREEN}$TARGET_PATH${NC}"
echo ""
echo "Next steps:"
echo ""
if [ -z "$PEM_PATH" ] && [ "$SKIP_ENV" = false ]; then
	echo "  1. Set environment variables (see above)"
	echo "  2. Run 'source ~/.zshenv' to load them"
	echo "  3. cd $TARGET_PATH && opencode"
else
	echo "  1. Run 'source ~/.zshenv' to load environment variables"
	echo "  2. cd $TARGET_PATH && opencode"
fi
echo ""
echo "Available commands:"
echo "  /bbq.status <ticket>     - Check ticket status"
echo "  /bbq.research <ticket>   - Research a ticket"
echo "  /bbq.plan <ticket>       - Plan implementation"
echo "  /bbq.implement <ticket>  - Implement the ticket"
echo "  /bbq.review <ticket>     - Address PR review comments"
echo ""
