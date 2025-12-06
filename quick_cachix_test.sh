#!/bin/bash
echo "=== Quick Cachix Auth Test ==="
echo ""

# Create a tiny test file
echo "test" > /tmp/cachix_test_file

# Build a minimal derivation
echo "Building minimal test derivation..."
TEST_PATH=$(nix-build -E '(import <nixpkgs> {}).runCommand "cachix-test" {} "echo test > $out"' 2>&1 | grep "^/nix/store" | head -1)

if [ -n "$TEST_PATH" ]; then
    echo "Test derivation: $TEST_PATH"
    echo ""
    echo "Attempting push to johngavin cache..."
    echo ""
    echo "$TEST_PATH" | cachix push johngavin 2>&1
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ SUCCESS: Cachix authentication is working!"
        echo "   You can push to the johngavin cache."
    else
        echo ""
        echo "❌ FAILED: Check your auth token or cache permissions"
    fi
else
    echo "❌ Could not build test derivation"
fi

# Cleanup
rm -f /tmp/cachix_test_file
