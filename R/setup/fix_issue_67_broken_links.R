# Session Log: Fix Issue #67 - Broken Vignette Links on Pkgdown Site
# Date: 2025-12-01
# Issues: #67 (broken links), #68 (three dashboard versions)
#
# CRITICAL: This log documents ALL R commands used to fix the issues
# For reproducibility and audit trail

# =============================================================================
# ISSUE #67: Broken vignette/article links on pkgdown site
# =============================================================================
# Problems:
# 1. https://johngavin.github.io/randomwalk/articles/dashboard.html → 404
# 2. https://johngavin.github.io/randomwalk/articles/dashboard_async.html → 404
# 3. Async simulation link from home page broken
#
# Root Cause:
# - pkgdown workflow only built articles INDEX, not actual HTML files
# - No Shinylive export for sync dashboard (which works in WebR)
# - Async dashboard export disabled (can't work in WebR due to nanonext)

# =============================================================================
# RELATED: Fix default.nix syntax errors (nix parser chokes on quotes)
# =============================================================================
# File: /Users/johngavin/docs_gh/rix.setup/default.nix
# Problem: Comments containing quote characters (",' ,`) cause parse errors
# Solution: Replaced all quotes in comments with angle brackets < >
# Lines fixed: 4-6, 10-11, 15, 16, 220-221, 224-225, 230, 269

# =============================================================================
# CHANGES MADE
# =============================================================================

# 1. Fixed default.nix syntax (done via Edit tool)
# 2. Updated .github/workflows/pkgdown.yaml:
#    - Added sync dashboard Shinylive export (lines 93-113)
#    - Changed pkgdown::build_articles_index() to pkgdown::build_articles()
#    - Documented why async dashboard export is disabled
# 3. Updated vignettes/dashboard_async.qmd:
#    - Added WebR/browser limitation warning
#    - Provided local installation instructions
#    - Removed misleading "runs in browser" claims

# =============================================================================
# GIT WORKFLOW (following CLAUDE.md mandatory workflow)
# =============================================================================

library(gert)
library(usethis)
library(gh)

# Step 0: MANDATORY - Push to johngavin cachix BEFORE committing to git
# This ensures GitHub Actions can pull from cache instead of rebuilding
# Run this in the nix shell from the project directory:
# ../push_to_cachix.sh
#
# The generic script (located in parent directory) automatically:
# - Detects package name from DESCRIPTION (randomwalk)
# - Finds package in nix store
# - Pushes to johngavin cachix along with btw
#
# OR manually:
# nix-store -qR --include-outputs $(nix-instantiate default-ci.nix) | grep -E 'randomwalk|btw' | cachix push johngavin

# Step 1: GitHub issues already created
# - Issue #67: Fix broken vignette links
# - Issue #68: Enhancement for three dashboard versions

# Step 2: Create development branch
usethis::pr_init("fix-issue-67-broken-vignette-links")

# Step 3: Stage changes
gert::git_add(c(
  ".github/workflows/pkgdown.yaml",  # Build articles + export sync dashboard
  "vignettes/dashboard_async.qmd",   # Updated WebR limitation docs
  "R/setup/fix_issue_67_broken_links.R"  # This session log
))

# Step 4: Commit changes
gert::git_commit("Fix #67: Build vignettes and export sync dashboard

PROBLEM:
- Vignette links returned 404 errors on pkgdown site
- pkgdown workflow only built articles INDEX, not HTML files
- Sync dashboard not exported to Shinylive (should work in WebR)
- Async dashboard link broken (can't work in WebR due to nanonext)

SOLUTION:
1. Changed pkgdown::build_articles_index() to build_articles()
   - Now builds actual HTML files for all vignettes
2. Added sync dashboard Shinylive export
   - Works in WebR (no crew/nanonext dependencies)
   - Mirrors what GitHub Actions does for deployment
3. Updated dashboard_async.qmd documentation
   - Clear warning about WebR/browser limitations
   - Installation instructions for local use
4. Fixed default.nix syntax errors
   - Removed all quotes from comments (Nix parser issue)

FILES CHANGED:
- .github/workflows/pkgdown.yaml (build articles, export sync dashboard)
- vignettes/dashboard_async.qmd (document WebR limitations)
- ../rix.setup/default.nix (syntax fixes for Nix parser)

RELATED ISSUES:
- #68: Enhancement for three dashboard versions (sync, pre-nanonext, nanonext)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>")

# Step 5: Push and create PR
usethis::pr_push()

# Step 6: Monitor GitHub Actions
# After pushing, check workflows at:
# https://github.com/JohnGavin/randomwalk/actions

# Commands to check workflow status:
# gh::gh("GET /repos/JohnGavin/randomwalk/actions/runs", per_page = 5)

# Step 7: After GitHub Actions pass, merge PR
# usethis::pr_merge_main()
# usethis::pr_finish()

# =============================================================================
# VERIFICATION STEPS
# =============================================================================

# After PR merged and GitHub Actions complete:
# 1. Check https://johngavin.github.io/randomwalk/articles/dashboard.html
# 2. Check https://johngavin.github.io/randomwalk/articles/dashboard_async.html
# 3. Verify sync dashboard works in browser
# 4. Verify async dashboard docs explain local-only requirement

# =============================================================================
# NOTES
# =============================================================================

# Cachix authentication:
# - Verified working with quick test
# - Auth token: eyJhbGci...F2Q (configured in ~/.config/cachix/cachix.dhall)
# - Can push to johngavin cache
# - Workflow will automatically push randomwalk and btw packages

# WebR/Shinylive limitations:
# - crew + nanonext require native C libraries (libnng, libmbedtls)
# - WebR can only load pre-compiled WebAssembly binaries
# - Therefore: async dashboard (with crew) CANNOT work in browser
# - Sync dashboard DOES work in browser (no native dependencies)

# Session info
cat("Session log created:", Sys.time(), "\n")
cat("Branch: fix-issue-67-broken-vignette-links\n")
cat("Issues: #67, #68\n")
