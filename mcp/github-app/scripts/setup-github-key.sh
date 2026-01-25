#!/bin/bash
#
# Reads a GitHub App private key (.pem file) and adds it to ~/.zshenv
# as the BBQ_GITHUB_APP_PRIVATE_KEY environment variable.
#
# The key is base64 encoded to avoid newline issues in JSON configs.
#
# Usage: ./scripts/setup-github-key.sh /path/to/private-key.pem

set -e

if [ -z "$1" ]; then
	echo "Usage: $0 <path-to-private-key.pem>"
	exit 1
fi

PEM_FILE="$1"

if [ ! -f "$PEM_FILE" ]; then
	echo "Error: File not found: $PEM_FILE"
	exit 1
fi

ZSHENV="$HOME/.zshenv"

# Base64 encode the key (single line, no wrapping)
ENCODED_KEY=$(base64 <"$PEM_FILE" | tr -d '\n')

# Check if already set in .zshenv
if grep -q "^export BBQ_GITHUB_APP_PRIVATE_KEY=" "$ZSHENV" 2>/dev/null; then
	echo "Warning: BBQ_GITHUB_APP_PRIVATE_KEY already exists in $ZSHENV"
	read -p "Overwrite? [y/N] " -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		echo "Aborted."
		exit 0
	fi
	# Remove existing entry
	grep -v "^export BBQ_GITHUB_APP_PRIVATE_KEY=" "$ZSHENV" >"$ZSHENV.tmp"
	mv "$ZSHENV.tmp" "$ZSHENV"
fi

# Append the base64-encoded key
{
	echo ""
	echo "# GitHub App private key for BBQ Party MCP (base64 encoded)"
	echo "export BBQ_GITHUB_APP_PRIVATE_KEY=\"$ENCODED_KEY\""
} >>"$ZSHENV"

echo "Added BBQ_GITHUB_APP_PRIVATE_KEY to $ZSHENV (base64 encoded)"
echo ""
echo "Run 'source ~/.zshenv' or restart your terminal to apply."
