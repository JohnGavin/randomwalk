#!/bin/bash
# install_hooks.sh
#
# Install git hooks for randomwalk package development
#
# This script copies git hooks from hooks/ directory to .git/hooks/
# and makes them executable.
#
# Usage:
#   ./hooks/install_hooks.sh
#
# Or from project root:
#   bash hooks/install_hooks.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Installing git hooks for randomwalk development...${NC}"
echo ""

# Check if we're in the project root
if [ ! -f "DESCRIPTION" ]; then
  echo "Error: Must run from randomwalk project root directory"
  exit 1
fi

# Check if .git exists
if [ ! -d ".git" ]; then
  echo "Error: .git directory not found. Is this a git repository?"
  exit 1
fi

# Install pre-commit hook
echo "📦 Installing pre-commit hook..."
cp hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
echo -e "${GREEN}✅ pre-commit hook installed${NC}"
echo ""

# Show what the hook does
echo "📋 Installed hooks:"
echo "  • pre-commit: Regenerates nix files when DESCRIPTION changes"
echo ""

echo -e "${GREEN}✅ Git hooks installed successfully!${NC}"
echo ""
echo "💡 What happens now:"
echo "  - When you commit changes to DESCRIPTION, the hook will:"
echo "    1. Automatically regenerate package.nix, default-ci.nix, default.nix"
echo "    2. Stage the updated nix files"
echo "    3. Include them in your commit"
echo ""
echo "  - If regeneration fails, the commit will be aborted"
echo "  - This ensures nix files are always in sync with DESCRIPTION"
echo ""
