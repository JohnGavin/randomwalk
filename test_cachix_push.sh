#!/bin/bash
# Test script to verify cachix push works

echo "=== Testing Cachix Push to johngavin cache ==="
echo ""

echo "1. Building a small derivation to test push..."
# Build the CI environment (this is what the workflow does)
nix-build default-ci.nix --no-out-link -A shell 2>&1 | tail -5

echo ""
echo "2. Finding the randomwalk package in the store..."
# Find randomwalk derivation in the nix store
RANDOMWALK_PATH=$(nix-store -qR $(nix-instantiate default-ci.nix) 2>/dev/null | grep -m1 "randomwalk" || echo "")

if [ -z "$RANDOMWALK_PATH" ]; then
    echo "⚠️  No randomwalk package found in store yet"
    echo "    Building randomwalk package first..."
    nix-build -E 'with import <nixpkgs> {}; callPackage ./. {}' --no-out-link 2>&1 | tail -3
    RANDOMWALK_PATH=$(nix-store -qR $(nix-instantiate default-ci.nix) 2>/dev/null | grep -m1 "randomwalk" || echo "NOT_FOUND")
fi

echo "Found: $RANDOMWALK_PATH"
echo ""

echo "3. Testing cachix push (dry-run)..."
# Test pushing to cachix (just to see if auth works)
if [ "$RANDOMWALK_PATH" != "NOT_FOUND" ] && [ -n "$RANDOMWALK_PATH" ]; then
    echo "$RANDOMWALK_PATH" | head -1 | cachix push johngavin --verbose 2>&1 | head -15
    EXIT_CODE=$?
    echo ""
    if [ $EXIT_CODE -eq 0 ]; then
        echo "✅ SUCCESS: Can write to johngavin cachix!"
    else
        echo "❌ FAILED: Cannot write to johngavin cachix (exit code: $EXIT_CODE)"
    fi
else
    echo "❌ Could not find randomwalk package to test push"
fi
