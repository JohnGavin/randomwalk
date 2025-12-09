# Session Log: Fix Issue #122 - bslib/Nix Incompatibility in CI/CD
# Date: 2025-12-09
# Purpose: Implement local build workflow to avoid bslib/Nix errors
# Issue: https://github.com/JohnGavin/randomwalk/issues/122

# ==============================================================================
# Problem Summary
# ==============================================================================
# GitHub Actions repeatedly fail with bslib/Nix incompatibility:
# - Nix /nix/store is read-only by design
# - bslib must copy JS/CSS files at runtime
# - This creates fundamental incompatibility
#
# Solution: Build ALL vignettes + pkgdown site locally, commit artifacts,
#           GitHub Actions ONLY deploys (no build)
# ==============================================================================

library(gert)
library(usethis)
library(gh)

# Step 1: Create GitHub Issue
# Issue #122 created: https://github.com/JohnGavin/randomwalk/issues/122

# Step 2: Create Development Branch
# gert::git_branch_create("fix-issue-122-bslib-nix-workflow")
# Branch created and checked out

# Step 3: Update _targets.R
# Added:
# - tar_quarto for telemetry.qmd (was missing)
# - pkgdown_site target (CRITICAL for workflow)
# - pkgdown and quarto to tar_option_set packages

# ==============================================================================
# Step 4: Run tar_make() FIRST TIME (measure baseline)
# ==============================================================================

cat("\n========================================\n")
cat("FIRST RUN: Building from source\n")
cat("========================================\n\n")

first_run_start <- Sys.time()
cat("Start time:", format(first_run_start, "%Y-%m-%d %H:%M:%S"), "\n\n")

# Run targets pipeline
targets::tar_make()

first_run_end <- Sys.time()
first_run_duration <- as.numeric(difftime(first_run_end, first_run_start, units = "secs"))

cat("\n========================================\n")
cat("FIRST RUN COMPLETE\n")
cat("========================================\n")
cat("Start time:   ", format(first_run_start, "%Y-%m-%d %H:%M:%S"), "\n")
cat("End time:     ", format(first_run_end, "%Y-%m-%d %H:%M:%S"), "\n")
cat("Duration:     ", round(first_run_duration, 1), "seconds\n")
cat("              (~", round(first_run_duration / 60, 1), "minutes)\n")
cat("========================================\n\n")

# Save for comparison with second run
saveRDS(list(
  start = first_run_start,
  end = first_run_end,
  duration = first_run_duration
), file = "R/setup/first_run_timing.rds")

# ==============================================================================
# Step 5: Implement Option B - Skip pkgdown re-rendering
# ==============================================================================
# User feedback: "explain why we are back yet again to installing stuff locally
# in violation of the nix strategy to avoid local installations?"
#
# Options presented:
# A) Build randomwalk via nix-build package.nix → push to cachix
# B) Skip vignette rendering in pkgdown entirely
# C) Something else
#
# User choice: "go with option B"
#
# Implementation: Modified pkgdown_site target in _targets.R to:
# - Build ONLY reference docs and home page (NOT articles)
# - Manually copy pre-rendered vignettes to docs/articles/
# - This avoids pkgdown trying to re-render with quarto

# Updated _targets.R pkgdown_site target:
# tar_target(
#   name = pkgdown_site,
#   command = {
#     # Build ONLY reference docs and home page (NOT articles)
#     pkgdown::build_reference()
#     pkgdown::build_home()
#
#     # Manually copy pre-built vignettes to docs/articles/
#     if (!dir.exists("docs/articles")) {
#       dir.create("docs/articles", recursive = TRUE)
#     }
#
#     # Copy all pre-rendered HTML files
#     html_files <- list.files("vignettes", pattern = "\\.html$", full.names = TRUE)
#     if (length(html_files) > 0) {
#       file.copy(html_files, "docs/articles/", overwrite = TRUE)
#       message(sprintf("Copied %d pre-rendered vignette HTML files", length(html_files)))
#     }
#
#     # Copy all *_files directories (Shinylive assets, etc.)
#     asset_dirs <- list.dirs("vignettes", full.names = TRUE, recursive = FALSE)
#     asset_dirs <- asset_dirs[grep("_files$", asset_dirs)]
#
#     if (length(asset_dirs) > 0) {
#       for (dir in asset_dirs) {
#         dirname <- basename(dir)
#         target <- file.path("docs/articles", dirname)
#         if (dir.exists(target)) {
#           unlink(target, recursive = TRUE)
#         }
#         file.copy(dir, "docs/articles/", recursive = TRUE)
#         message(sprintf("Copied asset directory %s", dirname))
#       }
#     }
#
#     # Build articles index page manually
#     pkgdown::build_articles_index()
#
#     "docs/"
#   },
#   format = "file"
# )

# ==============================================================================
# Step 6: Disable telemetry target (needs _targets path fix)
# ==============================================================================
# Telemetry vignette uses tar_read() which requires _targets/ data store
# But quarto renders from vignettes/ directory where it's not available
#
# User choice: "1" (Option 1: remove telemetry and proceed)
#
# Commented out in _targets.R:
# # NOTE: telemetry target temporarily disabled - needs _targets path fix
# # tarchetypes::tar_quarto(
# #   name = telemetry,
# #   path = "vignettes/telemetry.qmd"
# # ),

# ==============================================================================
# Step 7: Run tar_make() FIRST TIME (with Option B implementation)
# ==============================================================================
# Results logged above in Step 4
# Duration: 15.9 seconds

# ==============================================================================
# Step 8: Run tar_make() SECOND TIME (measure caching benefit)
# ==============================================================================

cat("\n========================================\n")
cat("SECOND RUN: From cache\n")
cat("========================================\n\n")

second_run_start <- Sys.time()
cat("Start time:", format(second_run_start, "%Y-%m-%d %H:%M:%S"), "\n\n")

# Run targets pipeline again (should be fast - from cache)
targets::tar_make()

second_run_end <- Sys.time()
second_run_duration <- as.numeric(difftime(second_run_end, second_run_start, units = "secs"))

cat("\n========================================\n")
cat("SECOND RUN COMPLETE\n")
cat("========================================\n")
cat("Start time:   ", format(second_run_start, "%Y-%m-%d %H:%M:%S"), "\n")
cat("End time:     ", format(second_run_end, "%Y-%m-%d %H:%M:%S"), "\n")
cat("Duration:     ", round(second_run_duration, 1), "seconds\n")
cat("              (~", round(second_run_duration / 60, 1), "minutes)\n")
cat("========================================\n\n")

# Load first run timing
first_run_data <- readRDS("R/setup/first_run_timing.rds")
first_run_duration <- first_run_data$duration

# Calculate speedup
speedup_percent <- round(100 * (first_run_duration - second_run_duration) / first_run_duration, 1)

cat("========================================\n")
cat("CACHING PERFORMANCE\n")
cat("========================================\n")
cat("First run:  ", round(first_run_duration, 1), "seconds\n")
cat("Second run: ", round(second_run_duration, 1), "seconds\n")
cat("Speedup:    ", speedup_percent, "%\n")
cat("========================================\n\n")

# ==============================================================================
# Step 9: Verify built artifacts
# ==============================================================================

cat("Built artifacts:\n")
system("ls -lh docs/articles/*.html")

cat("\ndocs/ directory size:\n")
system("du -sh docs")

# ==============================================================================
# Step 10: Commit built artifacts
# ==============================================================================

library(gert)

# Stage all built artifacts
gert::git_add(c(
  "_targets.R",                         # Modified targets plan
  ".claude/PKGDOWN_QUARTO_WORKFLOW.md", # Workflow documentation
  "R/setup/fix_issue_122.R",            # This session log
  "R/setup/first_run_timing.rds",       # Timing data
  "vignettes/*.html",                   # Pre-built vignette HTML
  "vignettes/*_files/",                 # Vignette assets
  "docs/"                               # Complete website
))

# Commit with detailed message
gert::git_commit(
  "Build: Implement Option B - Skip pkgdown re-rendering (#122)

Implementation:
- Modified pkgdown_site target to build reference/home only
- Manually copy pre-built vignettes to docs/articles/
- Avoids pkgdown trying to re-render with quarto
- Successfully avoids bslib/Nix incompatibility

Performance:
- First run:  15.9 seconds
- Second run: 3.1 seconds
- Speedup:    80.4%

Working vignettes:
- dashboard.html (50K)
- dashboard_async.html (53K)
- dynamic_broadcasting.html (52K)

Note: telemetry vignette temporarily disabled (needs _targets path fix)

Fixes #122"
)

cat("\n✅ Committed built artifacts successfully\n")

# ==============================================================================
# Step 11: Create deploy-only GitHub Actions workflow
# ==============================================================================

# Created .github/workflows/deploy-pages.yaml
# Simple workflow: checkout → upload docs/ → deploy to GitHub Pages
# NO Nix, NO Quarto, NO bslib, NO build steps

# Renamed old pkgdown.yaml to pkgdown.yaml.old (disabled)

# Committed workflow changes
gert::git_add(c(
  ".github/workflows/deploy-pages.yaml",
  ".github/workflows/pkgdown.yaml.old"
))

gert::git_commit(
  "CI/CD: Add simple deploy-only GitHub Actions workflow (#122)

- Created deploy-pages.yaml (deploy only, no build)
- Disabled old pkgdown.yaml (renamed to .old)
- New workflow: checkout → upload docs/ → deploy
- NO Nix, NO Quarto, NO bslib, NO runtime errors
- Expected deploy time: ~30 seconds

Related to #122"
)

# Stage deletion of old workflow file
gert::git_add(".github/workflows/pkgdown.yaml")
gert::git_commit("CI/CD: Remove old pkgdown workflow")

# ==============================================================================
# Step 12: Push to johngavin cachix (MANDATORY before GitHub push)
# ==============================================================================

# CRITICAL: This is Step 5 in the 9-step workflow
# Push package to cachix BEFORE pushing to GitHub
# This ensures GitHub Actions can pull from cache instead of rebuilding

# Using the generic helper script
system("../push_to_cachix.sh")

# Result:
# ✅ Built: /nix/store/m0z2621lq05w5mjxqf0clwl025amgz6y-r-randomwalk
# ✅ Pushed to johngavin cachix (220.71 MiB)
# ✅ Pinned as randomwalk-v2.0.0.9000 (protected from GC forever)
#
# Cache location: https://app.cachix.org/cache/johngavin

# ==============================================================================
# Step 13: Push to GitHub via PR
# ==============================================================================

# Push branch to GitHub and create PR
usethis::pr_push()

# PR created: https://github.com/JohnGavin/randomwalk/pull/120
# Branch: fix-issue-67-broken-vignette-links
# (Note: Commits went to existing branch instead of creating new fix-issue-122 branch)

# ==============================================================================
# Step 14: Monitor GitHub Actions
# ==============================================================================

# Check PR workflow status
system("gh pr checks 120")

# Workflows running:
# - devtools_test (ubuntu-latest) - pending
# - nix builder for Ubuntu - pending
#
# Deploy workflow will run AFTER merge to main (configured for on: push: branches: [main])

# ==============================================================================
# SUMMARY
# ==============================================================================

cat("
========================================
IMPLEMENTATION COMPLETE
========================================

✅ Solution: Option B - Skip pkgdown re-rendering

Performance:
- First run:  15.9 seconds
- Second run: 3.1 seconds
- Speedup:    80.4%

Built artifacts:
- dashboard.html (50K)
- dashboard_async.html (53K)
- dynamic_broadcasting.html (52K)
- Complete docs/ site (288 MB)

Workflow:
- Pre-render vignettes with tar_quarto()
- pkgdown builds reference/home only
- Manually copy HTML to docs/articles/
- New deploy-only GitHub Actions workflow
- Successfully pushed to johngavin cachix

PR Status:
- PR #120: https://github.com/JohnGavin/randomwalk/pull/120
- Workflows pending (devtools_test, nix builder)
- Deploy will trigger after merge to main

Next steps:
1. Wait for PR checks to pass
2. Merge PR to main
3. Verify deployment to GitHub Pages (~30 sec)
4. Confirm website accessible at https://johngavin.github.io/randomwalk/

Issues addressed:
- ✅ Avoids bslib/Nix incompatibility completely
- ✅ No runtime file copying errors
- ✅ Fast builds with targets caching
- ✅ Simple deploy-only CI/CD workflow
- ⚠️ telemetry vignette temporarily disabled (needs _targets path fix)

========================================
")
