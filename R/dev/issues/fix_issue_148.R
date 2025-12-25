# Fix Issue #148: Upgrade Shinylive assets to 0.10.7 for webR 0.5.5 (R 4.5.1)
# Date: 2025-12-25
# Branch: fix-148-upgrade-shinylive-assets

# ============================================================================
# Problem
# ============================================================================
# After fixing build workflow (#146) to use webR 0.5.8 for package building,
# vignettes still showed R 4.4.1 in browser because the RUNTIME webR version
# comes from Shinylive assets, not from the build workflow.
#
# Current setup:
# - shinylive R package: 0.3.0
# - shinylive assets: v0.9.1
# - Runtime webR: 0.4.x with R 4.4.1 ❌
#
# Browser console showed:
# "R version 4.4.1 (2024-06-14)"
# "Error: there is no package called 'nanonext'"

# ============================================================================
# Root Cause Analysis
# ============================================================================
# The webR runtime version is determined by Shinylive assets version, which is
# bundled in the rendered HTML, NOT by the build-rwasm workflow configuration.
#
# Build workflow (#146): webR 0.5.8 ✅ (for building packages)
# Runtime (browser):     webR 0.4.x ❌ (from Shinylive assets v0.9.1)

# ============================================================================
# Solution
# ============================================================================
# Use SHINYLIVE_ASSETS_VERSION environment variable to force download of
# Shinylive assets 0.10.7 which includes webR 0.5.5 with R 4.5.1.
#
# This allows upgrading the runtime webR without modifying the Nix environment
# or upgrading the shinylive R package.

# ============================================================================
# Implementation Steps
# ============================================================================

# Step 1: Create GitHub issue
library(gh)
issue <- gh("POST /repos/johngavin/randomwalk/issues",
  title = "Upgrade Shinylive assets to 0.10.7 for webR 0.5.5 (R 4.5.1) runtime",
  body = "...",  # (see issue #148 for full text)
  labels = list("enhancement", "webr", "shinylive")
)
# Created issue #148

# Step 2: Create development branch
library(usethis)
pr_init("fix-148-upgrade-shinylive-assets")

# Step 3: Re-render vignettes with SHINYLIVE_ASSETS_VERSION=0.10.7
# Working directory: /Users/johngavin/docs_gh/randomwalk/vignettes

# Render dynamic_broadcasting.qmd
system("SHINYLIVE_ASSETS_VERSION=0.10.7 quarto render articles/dynamic_broadcasting.qmd")
# Output: ℹ Downloading shinylive assets v0.10.7
#         ✔ Downloading shinylive assets v0.10.7 [15.7s]
#         ✔ Unzipping shinylive assets to '/Users/johngavin/Library/Caches/shinylive' [2s]
#         Output created: dynamic_broadcasting.html

# Render dashboard_comprehensive.qmd
system("SHINYLIVE_ASSETS_VERSION=0.10.7 quarto render articles/dashboard_comprehensive.qmd")
# Output: Output created: dashboard_comprehensive.html

# Step 4: Copy rendered files to docs/articles/
system("cp articles/dynamic_broadcasting.html ../docs/articles/")
system("cp articles/dashboard_comprehensive.html ../docs/articles/")
system("rm -rf ../docs/articles/dynamic_broadcasting_files ../docs/articles/dashboard_comprehensive_files")
system("cp -r articles/dynamic_broadcasting_files articles/dashboard_comprehensive_files ../docs/articles/")

# Step 5: Verify Shinylive version in HTML
# Check that HTML references shinylive-0.10.7:
# <script src="dynamic_broadcasting_files/libs/quarto-contrib/shinylive-0.10.7/shinylive/load-shinylive-sw.js">

# Step 6: Commit changes
library(gert)
git_add(c(
  "docs/articles/dynamic_broadcasting.html",
  "docs/articles/dashboard_comprehensive.html",
  "docs/articles/dynamic_broadcasting_files/",
  "docs/articles/dashboard_comprehensive_files/",
  "vignettes/articles/dynamic_broadcasting.html",
  "vignettes/articles/dashboard_comprehensive.html",
  "vignettes/articles/dynamic_broadcasting_files/",
  "vignettes/articles/dashboard_comprehensive_files/",
  "R/dev/issues/fix_issue_148.R"
))

git_commit("Fix #148: Upgrade Shinylive assets to 0.10.7 (webR 0.5.5, R 4.5.1)

- Re-rendered vignettes with SHINYLIVE_ASSETS_VERSION=0.10.7
- Runtime webR upgraded from 0.4.x (R 4.4.1) to 0.5.5 (R 4.5.1)
- Shinylive assets downloaded: v0.10.7
- nanonext/mirai packages should now be available at runtime

Changes:
- docs/articles/dynamic_broadcasting.html (Shinylive 0.10.7)
- docs/articles/dashboard_comprehensive.html (Shinylive 0.10.7)
- Associated asset directories with new Shinylive version

Closes #148")

# Step 7: Push to GitHub
pr_push()

# Step 8: After GH Actions pass, merge PR
# pr_merge_main()
# pr_finish()

# ============================================================================
# Expected Outcome
# ============================================================================
# After deployment, browser console should show:
#
# Before (Issue #148):
# ❌ R version 4.4.1 (2024-06-14)
# ❌ Error fetching .../contrib/4.4/PACKAGES.rds
# ❌ Error: there is no package called 'nanonext'
#
# After (Fix #148):
# ✅ R version 4.5.1 (2024-06-14)
# ✅ Loading packages from .../contrib/4.5/
# ✅ mirai loaded
# ✅ nanonext loaded
# ✅ Async parallel workers=2 functional

# ============================================================================
# Technical Details
# ============================================================================
# Shinylive Assets Version Mapping:
# - v0.9.1:  webR 0.4.x with R 4.4.1 (old)
# - v0.10.5: webR 0.5.5 with R 4.5.1 (upgrade announcement)
# - v0.10.7: webR 0.5.5+ with R 4.5.1 (latest, used here)
#
# Package Building vs Runtime:
# - Build (#146):   webr-image: ghcr.io/r-wasm/webr:v0.5.8
# - Runtime (#148): SHINYLIVE_ASSETS_VERSION=0.10.7
#
# Both are required:
# - Build workflow creates /bin/emscripten/contrib/4.5/ directory
# - Runtime uses webR 0.5.5 to access those packages

# ============================================================================
# References
# ============================================================================
# - Issue #146: Upgrade webR build to R 4.5.1 ✅
# - Issue #148: Upgrade Shinylive runtime to R 4.5.1 ✅
# - https://github.com/posit-dev/shinylive/releases/tag/v0.10.7
# - https://github.com/posit-dev/shinylive/releases/tag/v0.10.5
# - https://tidyverse.org/blog/2025/07/webr-0-5-4/
# - https://github.com/r-wasm/webr/releases

# ============================================================================
# Verification
# ============================================================================
# Test URLs after deployment:
# - https://johngavin.github.io/randomwalk/articles/dynamic_broadcasting.html
# - https://johngavin.github.io/randomwalk/articles/dashboard_comprehensive.html
#
# Check browser DevTools Console for:
# 1. ServiceWorker registration: ✅ Service Worker registered
# 2. R version: R version 4.5.1 (not 4.4.1)
# 3. Package loading: ✅ nanonext loaded, ✅ mirai loaded
# 4. No errors about missing nanonext package
