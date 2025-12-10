# Implementation Guide: webR Binaries with r-wasm/actions
# Issue #125: Fix Shinylive vignettes with custom package support
#
# This guide documents the complete implementation of Option 2:
# Building webR binaries via GitHub Actions and hosting on GitHub Pages

# ============================================================
# COMPLETED: Step 1 - GitHub Actions Workflow
# ============================================================

# Created: .github/workflows/build-rwasm.yml
# This workflow will:
# - Trigger on releases or manual dispatch
# - Build randomwalk package as WebAssembly binary
# - Deploy CRAN-like repository to GitHub Pages at:
#   https://johngavin.github.io/randomwalk/

# ============================================================
# REMAINING: Step 2 - Update Vignette Source Files
# ============================================================

# For EACH vignette (dashboard.qmd, dashboard_async.qmd, dynamic_broadcasting.qmd):
#
# FIND this code (around line 39-43):
#   # Load required packages
#   # Shinylive will automatically detect and bundle these packages
#   library(shiny)
#   library(ggplot2)
#   library(randomwalk)
#
# REPLACE with:
#   # Install randomwalk from GitHub Pages webR repository
#   # This repository is built by .github/workflows/build-rwasm.yml
#   webr::install(
#     "randomwalk",
#     repos = c(
#       "https://johngavin.github.io/randomwalk/",  # Our webR binaries
#       "https://repo.r-wasm.org/"                   # Official webR packages
#     )
#   )
#
#   # Load packages
#   library(shiny)
#   library(ggplot2)
#   library(randomwalk)

# Exact edit commands:
library(gert)

# dashboard.qmd
old_code_dashboard <- '# Load required packages
# Shinylive will automatically detect and bundle these packages
library(shiny)
library(ggplot2)
library(randomwalk)'

new_code <- '# Install randomwalk from GitHub Pages webR repository
# This repository is built by .github/workflows/build-rwasm.yml
webr::install(
  "randomwalk",
  repos = c(
    "https://johngavin.github.io/randomwalk/",  # Our webR binaries
    "https://repo.r-wasm.org/"                   # Official webR packages
  )
)

# Load packages
library(shiny)
library(ggplot2)
library(randomwalk)'

# Apply to all three vignettes
# (Note: dashboard_async and dynamic_broadcasting have same code structure)

# ============================================================
# Step 3: Commit Changes
# ============================================================

# After updating all three vignettes:
gert::git_add(c(
  ".github/workflows/build-rwasm.yml",
  "vignettes/dashboard.qmd",
  "vignettes/dashboard_async.qmd",
  "vignettes/dynamic_broadcasting.qmd",
  "R/setup/implement_rwasm_solution.R"
))

gert::git_commit("Implement webR binaries via r-wasm/actions for #125

- Add GitHub Actions workflow to build randomwalk as WebAssembly
- Update all three Shinylive vignettes to use webr::install()
- Install from GitHub Pages repository instead of relying on webR repo
- Fixes custom package availability in Shinylive apps

The workflow will build webR binaries on release and deploy to:
https://johngavin.github.io/randomwalk/")

gert::git_push()

# ============================================================
# Step 4: Create GitHub Release to Trigger Build
# ============================================================

# Option A: Using gh package
library(gh)
gh::gh(
  "POST /repos/JohnGavin/randomwalk/releases",
  owner = "JohnGavin",
  repo = "randomwalk",
  tag_name = "v0.2.0-webr",
  name = "v0.2.0 - WebR Binary Support",
  body = "This release triggers the webR binary build workflow.

The randomwalk package will be built as WebAssembly and deployed to:
https://johngavin.github.io/randomwalk/

Shinylive vignettes can now install the package using:
```r
webr::install('randomwalk', repos = 'https://johngavin.github.io/randomwalk/')
```",
  draft = FALSE,
  prerelease = FALSE
)

# Option B: Using gh CLI
# gh release create v0.2.0-webr \
#   --title "v0.2.0 - WebR Binary Support" \
#   --notes "Triggers webR binary build workflow"

# ============================================================
# Step 5: Monitor Workflow
# ============================================================

# After creating release, monitor the workflow:
gh::gh("GET /repos/JohnGavin/randomwalk/actions/runs",
       .limit = 1)

# Wait for workflow to complete (~5-10 minutes)
# The workflow will:
# 1. Build randomwalk package for WebAssembly
# 2. Create CRAN-like repository structure
# 3. Deploy to GitHub Pages

# ============================================================
# Step 6: Verify Deployment
# ============================================================

# After workflow completes successfully:
# 1. Check GitHub Pages is enabled:
#    - Go to Settings > Pages
#    - Source should be "GitHub Actions"
#
# 2. Verify webR repository is accessible:
#    https://johngavin.github.io/randomwalk/
#
# 3. Check PACKAGES file exists:
#    https://johngavin.github.io/randomwalk/bin/emscripten/contrib/4.4/PACKAGES
#
# 4. Test in browser:
#    - Open any vignette (dashboard, dashboard_async, dynamic_broadcasting)
#    - Open JavaScript Console (F12)
#    - Watch for webr::install() downloading randomwalk
#    - Verify app loads without "package not found" errors

# ============================================================
# Step 7: Update Documentation
# ============================================================

# Update WIKI_SHINYLIVE_LESSONS_LEARNED.md with:
# - How r-wasm/actions workflow was implemented
# - How vignettes install from custom webR repository
# - Testing protocol for verifying webR binary availability

# ============================================================
# Expected Results
# ============================================================

# After completing all steps:
# ✅ GitHub Actions workflow builds webR binaries on each release
# ✅ randomwalk package available at https://johngavin.github.io/randomwalk/
# ✅ Shinylive vignettes can install randomwalk via webr::install()
# ✅ No more "package not found in webR binary repo" errors
# ✅ Apps work in browser without CORS issues
# ✅ Clean, maintainable solution that scales to future packages

# ============================================================
# Key References
# ============================================================

# - Shinylive 0.8.0 custom packages: https://tidyverse.org/blog/2024/10/shinylive-0-8-0/#bundling-custom-r-packages
# - r-wasm/actions: https://github.com/r-wasm/actions
# - GitHub Pages deployment: https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site

# ============================================================
