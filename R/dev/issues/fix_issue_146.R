# Fix Issue #146: Upgrade webR to R 4.5.1 for nanonext/mirai support
# Date: 2025-12-25
# Branch: fix-146-upgrade-webr-r45

# ============================================================================
# Problem
# ============================================================================
# Shinylive vignettes fail with:
# - Error: there is no package called 'nanonext'
# - mirai package cannot load (requires nanonext)
# - Running on R 4.4.1 (webR default)
#
# User directive: "we should NEVER be on R 4.4. We MUST move to R 4.5 for
# EVERYTHING. nanonext and mirai on r-universe.dev for both packages"

# ============================================================================
# Solution
# ============================================================================
# Update .github/workflows/deploy-pages.yaml to use R 4.5.1 by specifying
# the webR Docker image version

# ============================================================================
# Implementation Steps
# ============================================================================

# Step 1: Create GitHub issue
library(gh)
issue <- gh("POST /repos/johngavin/randomwalk/issues",
  title = "Upgrade webR to R 4.5.1 for nanonext/mirai support",
  body = "## Problem

Shinylive vignettes fail to load `nanonext` and `mirai` packages because webR is currently using R 4.4.1.

## Solution

Upgrade to R 4.5.1 by specifying `webr-image: ghcr.io/r-wasm/webr:v0.5.8` in the build-rwasm action.

## Requirements

- R 4.5.1+ required for nanonext WebAssembly support
- nanonext and mirai packages available on r-lib.r-universe.dev
- WebR 0.5.4+ includes R 4.5.1

## References

- Issue #129: Async parallel support in WebAssembly
- https://tidyverse.org/blog/2025/07/webr-0-5-4/",
  labels = list("enhancement", "webr", "async")
)
# Created issue #146

# Step 2: Create development branch
library(usethis)
pr_init("fix-146-upgrade-webr-r45")

# Step 3: Modified file
# .github/workflows/deploy-pages.yaml:21-26
# Added: webr-image: ghcr.io/r-wasm/webr:v0.5.8  # R 4.5.1 for nanonext support

# Step 4: Commit changes
library(gert)
git_add(c(
  ".github/workflows/deploy-pages.yaml",
  "R/dev/issues/fix_issue_146.R"
))
git_commit("Fix #146: Upgrade webR to R 4.5.1 for nanonext/mirai support

- Updated deploy-pages.yaml to use webr-image: ghcr.io/r-wasm/webr:v0.5.8
- R 4.5.1 required for nanonext WebAssembly support
- nanonext/mirai available on r-lib.r-universe.dev
- Addresses user requirement: 'we should NEVER be on R 4.4'

Closes #146")

# Step 5: Push to GitHub
pr_push()

# Step 6: Monitor GitHub Actions
# Watch: https://github.com/johngavin/randomwalk/actions

# Step 7: After GH Actions pass, merge PR
# pr_merge_main()
# pr_finish()

# ============================================================================
# Expected Outcome
# ============================================================================
# After deployment:
# 1. webR builds with R 4.5.1 instead of R 4.4.1
# 2. nanonext package becomes available in WebAssembly
# 3. mirai package can load successfully
# 4. Shinylive apps can use async/parallel processing with workers=2+
# 5. Console shows: "R version 4.5.1" instead of "R version 4.4.1"

# ============================================================================
# Testing
# ============================================================================
# After deployment, verify in browser console:
# - https://johngavin.github.io/randomwalk/articles/dynamic_broadcasting.html
# - https://johngavin.github.io/randomwalk/articles/dashboard_comprehensive.html
#
# Expected console output:
# ✅ Service Worker registered
# ✅ R version 4.5.1
# ✅ mirai loaded
# ✅ nanonext loaded
# ✅ randomwalk loaded

# ============================================================================
# References
# ============================================================================
# - WebR Docker images: https://github.com/r-wasm/webr/pkgs/container/webr
# - WebR 0.5.8 release: https://tidyverse.org/blog/2025/07/webr-0-5-4/
# - r-wasm/actions docs: https://github.com/r-wasm/actions
# - nanonext r-universe: https://r-lib.r-universe.dev
# - Issue #129: Async parallel support in WebAssembly
