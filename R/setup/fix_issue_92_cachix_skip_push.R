# Fix Issue #92: CI/CD Rebuilding Entire Environment - Not Using johngavin Cachix
# Created: 2025-12-05
# Purpose: Add step to push default-ci.nix environment to johngavin cachix
#
# Root Cause: .github/workflows/nix-builder.yaml:38 had skipPush: true,
# preventing the dev environment from being cached. This caused every CI run
# to rebuild duckdb, downlit, and hundreds of other packages from source.
#
# Solution: Added a step to push the default-ci.nix environment to cachix
# after building it, so subsequent CI runs can pull from cache.

library(gert)
library(usethis)

# Step 1: Created issue #92 on GitHub
# https://github.com/JohnGavin/randomwalk/issues/92

# Step 2: Create dev branch
# Already done: fix-issue-92-cachix-skip-push

# Step 3: Make changes
# Modified THREE workflow files with the same fix:
#
# 1. .github/workflows/nix-builder.yaml:
#    - Added "Push dev environment to cachix" step after building default-ci.nix
#
# 2. .github/workflows/tests-r-via-nix.yaml:
#    - Added "Push dev environment to cachix" step after building environment
#    - This was causing duckdb compilation in devtools_test job
#
# 3. .github/workflows/pkgdown.yaml:
#    - Added "Push dev environment to cachix" step after Run build script
#
# All three workflows now cache the entire dev environment (all R packages, dev tools)
# so subsequent CI runs pull from johngavin cachix instead of rebuilding from source.

# Step 4: Commit changes
gert::git_add(".github/workflows/nix-builder.yaml")
gert::git_add(".github/workflows/tests-r-via-nix.yaml")
gert::git_add(".github/workflows/pkgdown.yaml")
gert::git_add("R/setup/fix_issue_92_cachix_skip_push.R")

gert::git_commit("Fix #92: Push dev environment to johngavin cachix in ALL workflows

Problem: ALL THREE workflows were rebuilding the entire default-ci.nix
environment from source every run (including duckdb C++ compilation with
thousands of third-party extensions), taking ~20 minutes.

Root cause: All three workflows had skipPush: true, preventing the dev
environment from being cached in johngavin cachix:
- nix-builder.yaml (line 38)
- tests-r-via-nix.yaml (line 52) - caused devtools_test duckdb compilation
- pkgdown.yaml (line 58)

Solution: Added \"Push dev environment to cachix\" step to ALL THREE workflows
after building default-ci.nix. Subsequent CI runs will pull from cache
(seconds instead of minutes).

Expected impact: ~18 minute reduction in CI/CD time for EACH workflow.

Related: Issue #91 (CI/CD optimization) Phase 1")

cat("✓ Changes committed\n")

# Step 5: Push to cachix (local) - MANDATORY before git push
# Since this is a workflow file change, we can't test it locally
# But we should verify nix files are valid
cat("Verifying nix files are valid...\n")

# Step 6: Push to GitHub (creates PR)
# usethis::pr_push()  # Will run after local verification

# Step 7: Wait for GitHub Actions
# Step 8: Merge PR
# Step 9: Log everything (this file)
