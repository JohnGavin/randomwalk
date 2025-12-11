# Session Log: Fix Issue #127 - Replace webr::mount() with webr::install()
# Date: 2025-12-11
# Issue: https://github.com/JohnGavin/randomwalk/issues/127
# Branch: fix-issue-127-webr-install
# Related: Issue #125 (previous Shinylive fix)

# ============================================================
# PROBLEM STATEMENT
# ============================================================

# Shinylive dashboards fail to load randomwalk package with error:
# "Requested package randomwalk not found in webR binary repo"
#
# Root cause: webr::mount() code is being stripped during pkgdown deployment
#
# Evidence:
# 1. Source .qmd files have webr::mount() with GitHub Releases URL
# 2. Built vignette HTML changes URL to relative path ../wasm/library.data
# 3. Deployed pkgdown HTML completely removes webr::mount() code
# 4. library(randomwalk) executes without package being mounted first → error

# ============================================================
# INVESTIGATION
# ============================================================

# Check current vignette source
# cat vignettes/dynamic_broadcasting.qmd | head -50
#
# Check built vignette HTML
# grep -A 10 "webr::mount" vignettes/dynamic_broadcasting.html
#
# Check deployed pkgdown HTML
# curl https://johngavin.github.io/randomwalk/articles/dynamic_broadcasting.html | \
#   grep -A 10 "webr::mount"
#
# Result: webr::mount() completely missing from deployed HTML!

# Compare to working v1.0.0 release
# git show v1.0.0:vignettes/dashboard.qmd | grep -A 10 "webr::"

# Check webR documentation for modern patterns
# https://docs.r-wasm.org/webr/latest/packages.html
# https://quarto-webr.thecoatlessprofessor.com/demos/qwebr-custom-repository.html
#
# Findings:
# - Modern approach: webr::install() with custom repos
# - More reliable than webr::mount()
# - Survives build process transformations
# - Works with GitHub Pages as CRAN-like repository

# ============================================================
# SOLUTION IMPLEMENTED
# ============================================================

library(usethis)
library(gert)

# Step 1: Create GitHub issue #127
# gh::gh(
#   'POST /repos/JohnGavin/randomwalk/issues',
#   title = 'Fix: Replace webr::mount() with webr::install() for reliable package loading',
#   body = '...' # See issue for full content
# )
# Result: https://github.com/JohnGavin/randomwalk/issues/127

# Step 2: Create development branch
# usethis::pr_init('fix-issue-127-webr-install')

# Step 3: Update all vignette .qmd files
#
# BEFORE (webr::mount() - gets stripped):
# webr::mount(
#   mountpoint = "/randomwalk-lib",
#   source = "https://github.com/JohnGavin/randomwalk/releases/latest/download/library.data"
# )
# .libPaths(c("/randomwalk-lib", .libPaths()))
# library(randomwalk)
#
# AFTER (webr::install() - survives deployment):
# webr::install(
#   "randomwalk",
#   repos = "https://johngavin.github.io/randomwalk/"
# )
# library(shiny)
# library(randomwalk)

# Files updated:
# - vignettes/dashboard.qmd
# - vignettes/dynamic_broadcasting.qmd
# - vignettes/dashboard_async.qmd
# - inst/shiny/dashboard/app.R
# - inst/shiny/dashboard_dynamic/app.R
# - inst/shiny/dashboard_async/app.R

# Step 4: Update cross-project WIKI documentation
# Updated: /Users/johngavin/docs_gh/claude_rix/WIKI_SHINYLIVE_LESSONS_LEARNED.md
# - Added Issue #127 section
# - Documented webr::install() vs webr::mount() differences
# - Updated best practices
# - Added cross-links to randomwalk wiki
# - Version 2.0

# Step 5: Commit changes (this session log included in PR)
# gert::git_add(c(
#   "vignettes/dashboard.qmd",
#   "vignettes/dynamic_broadcasting.qmd",
#   "vignettes/dashboard_async.qmd",
#   "inst/shiny/dashboard/app.R",
#   "inst/shiny/dashboard_dynamic/app.R",
#   "inst/shiny/dashboard_async/app.R",
#   "R/setup/fix_issue_127.R"
# ))
#
# gert::git_commit("Fix #127: Replace webr::mount() with webr::install()
#
# - Update all vignettes to use webr::install() approach
# - Install from GitHub Pages repo (CORS-enabled)
# - Survives pkgdown deployment transformations
# - Simpler, more reliable pattern
# - See: https://github.com/JohnGavin/randomwalk/issues/127
# ")

# ============================================================
# KEY DIFFERENCES: webr::mount() vs webr::install()
# ============================================================

# webr::mount():
# - Loads pre-built filesystem image
# - Requires library.data file from GitHub Releases
# - CORS issues with cross-origin requests
# - Gets stripped during pkgdown deployment
# - 10-15 lines of code + path manipulation
# - Older approach

# webr::install():
# - Downloads and installs package like CRAN
# - Works with GitHub Pages as custom repository
# - No CORS issues (GitHub Pages has proper headers)
# - Survives pkgdown rendering transformations
# - 3-5 lines of code
# - Modern recommended pattern (official docs)

# ============================================================
# TESTING PLAN
# ============================================================

# After PR merge and deployment:
# 1. Open each vignette in browser:
#    - https://johngavin.github.io/randomwalk/articles/dashboard.html
#    - https://johngavin.github.io/randomwalk/articles/dynamic_broadcasting.html
#    - https://johngavin.github.io/randomwalk/articles/dashboard_async.html
#
# 2. Open JavaScript console (F12)
#
# 3. Verify NO errors:
#    ✅ Should see: webr::install() downloading randomwalk
#    ✅ Should see: Package randomwalk loaded successfully
#    ❌ Should NOT see: "Requested package randomwalk not found"
#    ❌ Should NOT see: CORS policy errors
#
# 4. Test interactivity:
#    - Click "Run Simulation" button
#    - Verify grid, statistics, and plots display
#    - Test multiple parameter combinations
#
# 5. Document results per AGENTS.md protocol

# ============================================================
# CROSS-PROJECT UPDATES
# ============================================================

# Updated claude_rix WIKI:
# /Users/johngavin/docs_gh/claude_rix/WIKI_SHINYLIVE_LESSONS_LEARNED.md
# - Version 2.0
# - Added Issue #127 comprehensive section
# - Updated best practices with webr::install() pattern
# - Added cross-links to randomwalk project
#
# Commit message:
# "docs: Update WIKI with Issue #127 webr::install() pattern"
#
# Repository: https://github.com/JohnGavin/claude_rix (if/when public)

# ============================================================
# KEY LESSONS LEARNED
# ============================================================

# 1. **pkgdown Transformations Can Break Code**
#    - Build processes can transform or strip Shinylive code
#    - What works in source may fail in deployment
#    - Use patterns that survive transformations

# 2. **Modern Documentation Over Old Patterns**
#    - webr::install() is the current recommended approach
#    - Always check official docs, not just Stack Overflow
#    - Verify patterns against latest documentation

# 3. **GitHub Pages as webR Repository**
#    - Can serve webR packages with proper CORS headers
#    - Works as custom CRAN-like repository
#    - More reliable than GitHub Releases

# 4. **Test Deployed HTML, Not Just Source**
#    - Verify actual deployed URLs
#    - Check browser JavaScript console
#    - Don't assume source changes propagate correctly

# 5. **Cross-Project Documentation is Critical**
#    - Maintain centralized WIKI for all projects
#    - Cross-link issues and documentation
#    - Share lessons learned across projects

# ============================================================
# REFERENCES
# ============================================================

# - Issue #127: https://github.com/JohnGavin/randomwalk/issues/127
# - Issue #125: https://github.com/JohnGavin/randomwalk/issues/125 (previous Shinylive fix)
# - webR Packages: https://docs.r-wasm.org/webr/latest/packages.html
# - Quarto webR Custom Repo: https://quarto-webr.thecoatlessprofessor.com/demos/qwebr-custom-repository.html
# - r-wasm/actions: https://github.com/r-wasm/actions/
# - WIKI: /Users/johngavin/docs_gh/claude_rix/WIKI_SHINYLIVE_LESSONS_LEARNED.md
# - AGENTS.md: https://github.com/JohnGavin/randomwalk/blob/main/AGENTS.md

# ============================================================
# END OF SESSION LOG
# ============================================================
