# Fix Issue #151: Build compatible mirai + nanonext WASM packages in CI
# Date: 2025-12-26
# Branch: main

# ============================================================================
# Problem
# ============================================================================
# After fixing all ServiceWorker issues (#148-154), the Shiny app fails to start
# due to nanonext/mirai version incompatibility:
#
# Error: package or namespace load failed for 'mirai':
#  object '.interrupt' is not exported by 'namespace:nanonext'
#
# Root cause: Version mismatch between mirai and nanonext packages
# - mirai expects nanonext to export `.interrupt`
# - The nanonext version from r-universe.dev doesn't have this export
# - Also: webR 0.5.5 doesn't support PACKAGES.rds format from r-universe

# ============================================================================
# Research Findings
# ============================================================================
# Sources:
# - https://r-lib.r-universe.dev/mirai
# - https://r-lib.r-universe.dev/nanonext
# - https://github.com/shikokuchuo/mirai
# - https://github.com/shikokuchuo/nanonext
# - https://r-wasm.github.io/rwasm/articles/github-actions.html
#
# Compatible versions for R 4.5.1 (webR 0.5.5):
# - nanonext v1.7.2 or v1.7.2.9000 (exports .interrupt)
# - mirai v2.5.3 or v2.5.3.9000 (requires nanonext >= 1.7.2)
#
# Both available as r-4.5-emscripten builds on r-lib.r-universe.dev
# nanonext v1.3.1+ has interruptible 'aio' waits
# mirai 2025 versions require nanonext >= 1.7.1 or >= 1.7.2

# ============================================================================
# Solution: Build Custom WASM Packages in GitHub Actions
# ============================================================================
# Use existing r-wasm/actions/build-rwasm@v2 action to build compatible
# versions of nanonext and mirai from GitHub alongside randomwalk package.
#
# Workflow modification:
# Before:
#   packages: "local::."
#
# After:
#   packages: |
#     github::shikokuchuo/nanonext@v1.7.2
#     github::shikokuchuo/mirai@v2.5.3
#     local::.

# ============================================================================
# Implementation
# ============================================================================
# File: .github/workflows/deploy-pages.yaml
# Updated build-rwasm action to build all three packages

# Benefits of this approach:
# 1. ✅ Uses existing GH Actions infrastructure
# 2. ✅ Builds specific compatible versions from GitHub
# 3. ✅ No need for custom r-universe repository
# 4. ✅ Packages deployed to /bin/emscripten/contrib/4.5/
# 5. ✅ Available at https://johngavin.github.io/randomwalk/bin/...
# 6. ✅ Vignettes can install from custom repo

# The r-wasm/actions/build-rwasm action:
# - Supports multiple packages from different sources
# - Syntax: "github::user/repo@ref" for specific versions
# - Creates CRAN-like repository structure
# - Works with webr::install() in Shinylive apps

# ============================================================================
# Expected Outcome
# ============================================================================
# After GitHub Actions completes:
# 1. ✅ nanonext 1.7.2 WASM package built
# 2. ✅ mirai 2.5.3 WASM package built
# 3. ✅ randomwalk WASM package built
# 4. ✅ All deployed to /bin/emscripten/contrib/4.5/
# 5. ✅ Vignettes install from johngavin.github.io/randomwalk
# 6. ✅ mirai loads successfully (has compatible nanonext)
# 7. ✅ Async parallel workers=2 functional

# Browser console should show:
# ✅ nanonext installed
# ✅ mirai loaded
# ✅ randomwalk loaded
# ✅ Async parallel processing working
# ❌ NO ".interrupt is not exported" error

# ============================================================================
# References
# ============================================================================
# GitHub Actions for r-wasm:
# - https://r-wasm.github.io/rwasm/articles/github-actions.html
# - https://github.com/r-wasm/actions
#
# Package repositories:
# - https://github.com/shikokuchuo/nanonext (nanonext source)
# - https://github.com/shikokuchuo/mirai (mirai source)
# - https://r-lib.r-universe.dev (r-universe builds)
#
# Version requirements:
# - mirai changelog: https://mirai.r-lib.org/news/index.html
# - nanonext releases: https://github.com/shikokuchuo/nanonext/releases
#
# Related documentation:
# - R Weekly 2025-W37: https://rweekly.org/2025-W37.html
# - R-universe WASM: https://ropensci.org/blog/2023/11/17/runiverse-wasm/

# ============================================================================
# Alternative Approaches Considered
# ============================================================================
# Option A: Wait for r-universe to update ❌
# - Too slow, no control over timing
#
# Option B: Disable async features temporarily ❌
# - Defeats purpose of Issue #129 (async support)
#
# Option C: Build custom WASM packages in CI ✅ CHOSEN
# - Fast, reproducible, version-controlled
# - Leverages existing GH Actions infrastructure
#
# Option D: Create custom r-universe fork ❌
# - Overcomplicated, maintenance burden

# ============================================================================
# Commit Changes
# ============================================================================
library(gert)
git_add(".github/workflows/deploy-pages.yaml")
git_add("R/dev/issues/fix_issue_151.R")

git_commit("Fix #151: Build compatible mirai + nanonext WASM packages in CI

Build nanonext v1.7.2 and mirai v2.5.3 from GitHub in the existing
deploy-pages workflow to resolve version incompatibility.

Problem:
- mirai expects .interrupt export from nanonext
- r-universe nanonext version missing this export
- Error: object '.interrupt' is not exported by 'namespace:nanonext'

Solution:
- Use r-wasm/actions/build-rwasm@v2 to build from GitHub
- nanonext@v1.7.2 (has .interrupt export)
- mirai@v2.5.3 (requires nanonext >= 1.7.2)
- Both compatible with R 4.5.1 / webR 0.5.5

Changes:
- .github/workflows/deploy-pages.yaml: Added nanonext and mirai to packages list

Expected:
- Async parallel processing (workers=2) will work
- No more nanonext compatibility errors
- Complete Shinylive functionality

Closes #151")

git_push()

# ============================================================================
# Next Steps After Deployment
# ============================================================================
# 1. Monitor GitHub Actions build
# 2. Verify packages deployed to /bin/emscripten/contrib/4.5/
# 3. Test vignettes in browser
# 4. Confirm async parallel features work
# 5. Update documentation with working examples

# ============================================================================
# Testing Commands
# ============================================================================
# Check deployed packages:
# curl https://johngavin.github.io/randomwalk/bin/emscripten/contrib/4.5/PACKAGES
# Should list: nanonext, mirai, randomwalk
#
# Check browser console:
# Should show: mirai loaded, nanonext loaded, no errors
