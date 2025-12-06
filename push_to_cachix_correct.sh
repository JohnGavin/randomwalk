#!/usr/bin/env bash
#
# push_to_cachix_correct.sh - Push ONLY randomwalk package to johngavin cachix
#
# This script pushes only the randomwalk package derivation, NOT its dependencies.
# Dependencies (ggplot2, logger, crew, etc.) are already on rstats-on-nix cache.
#
# Usage:
#   ./push_to_cachix_correct.sh

set -euo pipefail

echo "=== Push randomwalk to johngavin cachix (correct method) ==="
echo ""

# Get package name from DESCRIPTION
PKG_NAME=$(grep "^Package:" DESCRIPTION | awk '{print $2}' | tr -d '\r')
echo "📦 Package: $PKG_NAME"

# Build the package if not already built
STORE_PATH=$(nix-store -q --references /nix/store/hyknb383kw006yz541bpshd7chiby6a5-r-randomwalk 2>/dev/null | grep "r-${PKG_NAME}" | head -1) || true

if [ -z "$STORE_PATH" ]; then
    echo ""
    echo "🔨 Building package.nix..."
    RESULT=$(nix-build package.nix --no-out-link)
    STORE_PATH="$RESULT"
else
    echo "✅ Package already built: $STORE_PATH"
fi

echo ""
echo "📤 Pushing to johngavin cachix (ONLY randomwalk, no dependencies)..."
cachix push johngavin "$STORE_PATH"

echo ""
echo "✅ Successfully pushed $PKG_NAME to johngavin cachix"
echo ""
echo "Verify at: https://app.cachix.org/cache/johngavin#search"
