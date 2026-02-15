#!/bin/bash
# =============================================================================
# Nix Environment Setup Script with Persistent GC Root for randomwalk
# =============================================================================
#
# PURPOSE: Builds and activates a reproducible Nix environment with:
# - Persistent garbage collection (GC) root to prevent package deletion
# - Fast subsequent runs (seconds instead of minutes)
# - All DESCRIPTION dependencies available
#
# USAGE:
#   ./default.sh           # First run: builds and creates nix-shell-root
#   ./default.sh           # Subsequent runs: FAST (packages cached)
#   rm nix-shell-root && ./default.sh  # Force rebuild
#
# =============================================================================

# Define paths
PROJECT_PATH="/Users/johngavin/docs_gh/proj/stats/simulations/randomwalk"
GC_ROOT_PATH="$PROJECT_PATH/nix-shell-root"
NIX_FILE="$PROJECT_PATH/default.nix"

# Debug mode: set DEBUG=true to enable verbose output
DEBUG=${DEBUG:-false}
debug() { [ "$DEBUG" = "true" ] && echo "[DEBUG] $*"; }

# Validate HOME path: must be non-empty, absolute, and not contain literal '$'
is_valid_home() {
    case "$1" in
        "") return 1 ;;      # Empty
        *'$'*) return 1 ;;   # Contains literal $
        /*) return 0 ;;      # Absolute path - valid
        *) return 1 ;;       # Relative path
    esac
}

# Normalize HOME to avoid literal $HOME paths inside the repo.
sanitize_home() {
    if ! is_valid_home "$HOME"; then
        if [ -n "$USER" ] && [ -d "/Users/$USER" ]; then
            export HOME="/Users/$USER"
            debug "Fixed invalid HOME, set to $HOME"
        fi
    fi
}

sanitize_home

# Export environment variables BEFORE any Nix operations
export NIXPKGS_ALLOW_BROKEN=1 
export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1
export NIXPKGS_ALLOW_UNFREE=1
export SSL_CERT_FILE="${SSL_CERT_FILE:-/etc/ssl/cert.pem}"
export CURL_CA_BUNDLE="${CURL_CA_BUNDLE:-/etc/ssl/cert.pem}"

echo -e "\n=== STEP 1: Generate default.nix from default.R (if needed) ==="

# Determine if default.nix needs regeneration
NEED_REGEN=false

# Check 1: default.nix doesn't exist
if [ ! -f "$NIX_FILE" ]; then
    echo "default.nix does not exist."
    NEED_REGEN=true
# Check 2: default.nix exists but is empty
elif [ ! -s "$NIX_FILE" ]; then
    echo "default.nix exists but is empty."
    NEED_REGEN=true
# Check 3: default.R is newer than default.nix
elif [ "$PROJECT_PATH/default.R" -nt "$NIX_FILE" ]; then
    echo "default.R has been modified since default.nix was generated."
    NEED_REGEN=true
# Check 4: default.nix exists but has invalid Nix syntax
elif ! nix-instantiate --parse "$NIX_FILE" > /dev/null 2>&1; then
    echo "default.nix has invalid Nix syntax."
    NEED_REGEN=true
else
    echo "default.nix is up to date."
fi

if [ "$NEED_REGEN" = true ]; then
    echo "Regenerating default.nix from default.R..."
    if ! nix-shell \
        --keep PATH \
        --keep TMPDIR \
        --keep CACHIX_AUTH_TOKEN \
        --keep GITHUB_PAT \
        --keep SSL_CERT_FILE \
        --keep CURL_CA_BUNDLE \
        --keep NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM \
        --keep NIXPKGS_ALLOW_UNFREE \
        --expr "let pkgs = import <nixpkgs> {}; in pkgs.mkShell { buildInputs = [ pkgs.R pkgs.rPackages.rix pkgs.rPackages.cli pkgs.rPackages.curl pkgs.curlMinimal pkgs.cacert ]; }" \
        --command "cd \"$PROJECT_PATH\" && \
            Rscript \
            --vanilla \
            \"$PROJECT_PATH/default.R\" \
            --args GITHUB_PAT=$GITHUB_PAT" \
        --cores 4 \
        --quiet; then
        echo "ERROR: Step 1 failed - Rscript default.R returned an error."
        echo "Fix the error in default.R and try again."
        exit 1
    fi

    # Verify regeneration succeeded
    if [ ! -s "$NIX_FILE" ]; then
        echo "ERROR: default.nix regeneration failed (file is empty or missing)."
        exit 1
    fi
fi

echo -e "\n=== STEP 2: Build shell and create persistent GC root ==="

# Build the shell derivation and create GC root symlink atomically
# The -o flag creates the symlink AND protects from garbage collection
echo "Using cachix: rstats-on-nix and johngavin"
cachix use rstats-on-nix
cachix use johngavin

echo "Starting nix-build '$NIX_FILE' ..."
if ! time nix-build "$NIX_FILE" \
    -o "$GC_ROOT_PATH" \
    --cores 8 \
    --quiet; then
    echo "ERROR: Step 2 failed - nix-build returned an error."
    exit 1
fi

if [ ! -L "$GC_ROOT_PATH" ]; then
    echo "ERROR: Failed to build the Nix shell or create GC root at $GC_ROOT_PATH"
    exit 1
fi

STORE_PATH=$(readlink -f "$GC_ROOT_PATH")
echo "✓ SUCCESS: Persistent GC Root created"
echo "  Symlink: $GC_ROOT_PATH"
echo "  Points to: $STORE_PATH"
echo "  To allow garbage collection later, run: rm $GC_ROOT_PATH"

echo -e "\n=== STEP 3: Verify GC root is registered ==="
if nix-store --gc --print-roots | grep -q "$GC_ROOT_PATH"; then
    echo "✓ GC root is properly registered with Nix"
else
    echo "⚠ WARNING: GC root may not be properly registered"
fi

echo -e "\n=== STEP 4: Enter Interactive Nix Shell ==="

# Resolve the GC Root Symlink to the actual Nix Store Path
if [ ! -L "$GC_ROOT_PATH" ]; then
    echo "ERROR: GC Root symlink not found at $GC_ROOT_PATH. Cannot proceed."
    exit 1
fi

NIX_STORE_PATH=$(readlink "$GC_ROOT_PATH")

# Prepare the environment file
export TMPDIR="/tmp" 
ENV_SCRIPT="$TMPDIR/nix-env-$(date +%s).sh"
tail -n +5 "$NIX_STORE_PATH" > "$ENV_SCRIPT"

# Source the environment in the CURRENT shell
echo "Activating Nix environment..."
USER_HOME="$HOME"
USER_ACTUAL_SHELL="$SHELL"

# Ensure HOME is a valid absolute path
if ! is_valid_home "$USER_HOME"; then
    fallback="/Users/$(id -un)"
    if is_valid_home "$fallback"; then
        USER_HOME="$fallback"
    else
        USER_HOME="$TMPDIR"
    fi
    export HOME="$USER_HOME"
    echo "Reset HOME to $USER_HOME"
fi

if ! source "$ENV_SCRIPT"; then
    echo "ERROR: Step 4 failed - could not source Nix environment script."
    exit 1
fi
export IN_NIX_SHELL=impure

# Restore HOME
export HOME="$USER_HOME"

rm -f "$ENV_SCRIPT"

# Run the shell hook (sets up aliases, etc.)
if [ -n "$shellHook" ]; then
    eval "$shellHook"
fi

# Re-export critical variables
export NIXPKGS_ALLOW_BROKEN=1
export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1
export NIXPKGS_ALLOW_UNFREE=1
export GITHUB_PAT="$GITHUB_PAT"
export ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY"
export RIX_NIX_SHELL_ROOT="$GC_ROOT_PATH"

echo -e "\n=============================================="
echo "Entering INTERACTIVE Nix Shell for randomwalk"
echo -e "==============================================\n"

# Enter interactive shell
if [[ "$USER_ACTUAL_SHELL" == *"zsh"* ]]; then
    # For zsh users
    NIX_ZDOTDIR="$HOME/.nix-shell-zdotdir"
    mkdir -p "$NIX_ZDOTDIR"
    
    # Save Nix PATH
    export NIX_SHELL_PATH_SAVED="$PATH"
    
    # Create minimal zsh config files
    cat > "$NIX_ZDOTDIR/.zshenv" <<'ZSHENV'
if [ -n "$NIX_SHELL_PATH_SAVED" ]; then
    export PATH="$NIX_SHELL_PATH_SAVED"
fi
export IN_NIX_SHELL=impure
ZSHENV

    cat > "$NIX_ZDOTDIR/.zprofile" <<'ZPROFILE'
[ -f ~/.zprofile ] && source ~/.zprofile
if [ -n "$NIX_SHELL_PATH_SAVED" ]; then
    export PATH="$NIX_SHELL_PATH_SAVED"
fi
export IN_NIX_SHELL=impure
ZPROFILE

    cat > "$NIX_ZDOTDIR/.zshrc" <<'ZSHRC'
[ -f ~/.zshrc ] && source ~/.zshrc
if [ -n "$NIX_SHELL_PATH_SAVED" ]; then
    export PATH="$NIX_SHELL_PATH_SAVED"
fi
export IN_NIX_SHELL=impure

# Arrow key bindings
bindkey '^[[A' up-line-or-history
bindkey '^[[B' down-line-or-history
bindkey '^[[C' forward-char
bindkey '^[[D' backward-char
ZSHRC

    export ZDOTDIR="$NIX_ZDOTDIR"
    exec $USER_ACTUAL_SHELL -i
else
    # For bash users
    exec $SHELL -i
fi
