# Fix for Issue #92: Cachix Strategy - Selective Push
# Date: 2025-12-23
#
# PROBLEM:
# ========
# Inconsistent cachix push strategy between workflows:
# - tests-r-via-nix.yaml: Selective push (CORRECT) ✅
# - nix-builder.yaml: Pushed ALL dependencies (WRONG) ❌
#
# IMPACT:
# - Wasted johngavin cachix storage on R packages already in rstats-on-nix
# - Slower cache operations (unnecessary data transfer)
# - Defeated purpose of using rstats-on-nix as primary R package cache
#
# ROOT CAUSE:
# ===========
# nix-builder.yaml line 52 used:
#   nix-store -qR --include-outputs result | cachix push johngavin
#
# This pushes:
# - randomwalk package ✅
# - ALL R package dependencies (ggplot2, dplyr, etc.) ❌
# - System libraries ❌
#
# CORRECT STRATEGY:
# =================
#  ┌────────────────────────────────────────────────────┐
#  │ Cache Priority Order:                              │
#  ├────────────────────────────────────────────────────┤
#  │ 1. rstats-on-nix (READ-ONLY)  - All R packages   │
#  │ 2. johngavin      (READ-WRITE) - ONLY randomwalk  │
#  └────────────────────────────────────────────────────┘
#
# SOLUTION:
# =========
# Make nix-builder.yaml consistent with tests-r-via-nix.yaml:
#
# BEFORE:
#   nix-store -qR --include-outputs result | cachix push johngavin
#
# AFTER:
#   nix-store -qR --include-outputs result | \
#     grep -E 'randomwalk' | \
#     cachix push johngavin
#
# This ensures:
# ✅ Only randomwalk package pushed to johngavin cache
# ✅ R dependencies pulled from rstats-on-nix cache
# ✅ Consistent behavior across all workflows
# ✅ Optimal cache usage and storage
#
# FILES CHANGED:
# ==============
# - .github/workflows/nix-builder.yaml (lines 49-55)
#
# VERIFICATION:
# =============
# After deploying this fix, check GitHub Actions logs:
#
# Expected output:
#   copying path '/nix/store/xxx-randomwalk-0.1.0' to 'https://johngavin.cachix.org'
#
# Should NOT see paths for:
#   - /nix/store/xxx-r-ggplot2-*
#   - /nix/store/xxx-r-dplyr-*
#   - Other R packages
#
# RELATED:
# ========
# - Issue #92: CI/CD Rebuilding Environment - Not Using johngavin Cachix
# - Branch fix-issue-92-cachix-skip-push: OBSOLETE (wrong approach - pushes full dev env)
#
# CREDIT:
# =======
# Strategy clarified and validated by user - this fix implements their correct approach.
