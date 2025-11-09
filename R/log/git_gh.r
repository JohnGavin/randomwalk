# Git and GitHub Operations Log
# Date: 2025-11-06
# Issue: #5 - GitHub Actions workflows for CI/CD with Nix

# Load required packages
library(gert)
library(usethis)

# Add untracked files for issue #5
gert::git_add(c(
  "R/setup/WORKFLOW_SETUP_COMMANDS.md",
  "issue_number_workflows.txt",
  "push_workflows.R",
  "random_walk.code-workspace",
  "setup_workflows.R",
  "R/log/git_gh.r"
))

# Commit changes
gert::git_commit("Add GitHub Actions setup scripts and documentation for issue #5")

# Push branch to remote and create pull request
# usethis::pr_push() will push the branch and open browser to create PR
usethis::pr_push()

# ============================================================================
# Date: 2025-11-09
# Issue: #10 - Fix telemetry vignette git-info chunk data.frame error
# Branch: feature/add-telemetry-vignette-10
# ============================================================================

# The git-info chunk was creating a data.frame with mismatched row counts
# when git_info$status contained multiple lines (one per modified file).
# Fixed to count files and display as summary string.

# Check current status
# gert::git_status()

# Stage the fixed vignette file and this log file
# gert::git_add(c("vignettes/telemetry.Rmd", "R/log/git_gh.r"))

# Commit the fix
# gert::git_commit(
#   message = "Fix: Handle multi-line git status in telemetry vignette
#
# The git-info chunk was creating a data.frame with mismatched row counts
# when git_info$status contained multiple lines (one per modified file).
#
# Changed to count the number of modified files and display as a summary
# string instead of trying to fit multiple status lines into a single
# data.frame row.
#
# Fixes GitHub Actions pkgdown workflow failure.
#
# 🤖 Generated with [Claude Code](https://claude.com/claude-code)
#
# Co-Authored-By: Claude <noreply@anthropic.com>"
# )

# Push to remote
# gert::git_push()

# ============================================================================
# Date: 2025-11-09
# Issue: #14 - Convert to proper formats: telemetry.qmd and rix-generated default.nix
# Branch: feature/convert-to-proper-formats-14
# ============================================================================

# Tasks completed:
# 1. Backed up default.nix as default.R.bak
# 2. Created default.R with rix::rix() command for randomwalk
# 3. Converted telemetry.Rmd → telemetry.qmd (Quarto format)
# 4. Updated YAML header for Quarto (format, execute options)
# 5. Updated references in build_site.R and pkgdown.yaml
# 6. Verified cachix is configured in workflows (rstats-on-nix cache)

# Stage changes
# gert::git_add(c(
#   "default.R",
#   "default.R.bak",
#   "vignettes/telemetry.qmd",
#   "R/setup/build_site.R",
#   ".github/workflows/pkgdown.yaml",
#   "R/log/git_gh.r"
# ))

# Commit changes
# gert::git_commit(
#   message = "Convert to proper formats: Quarto vignette and rix-generated Nix config
#
# Issue #14: Follow context.md best practices for file formats
#
# **1. Nix Environment Setup**
# - Backed up current default.nix as default.R.bak
# - Created default.R with rix::rix() command
# - Lists all R package dependencies (logger, dplyr, targets, etc.)
# - Includes system packages (git, gh, quarto, pandoc)
# - Ready to regenerate default.nix with: Rscript default.R
#
# **2. Quarto Vignette Conversion**
# - Renamed: telemetry.Rmd → telemetry.qmd
# - Updated YAML header for Quarto format:
#   - format: html with code-fold, toc
#   - execute: echo/message/warning settings
#   - date: today (Quarto syntax)
# - Updated references in build_site.R and pkgdown.yaml
#
# **3. Cachix Verification**
# - Confirmed cachix IS configured in GitHub workflows
# - nix-builder: cachix-action@v15 with rstats-on-nix cache
# - tests-r-via-nix: cachix-action@v14
# - Speeds up CI by caching Nix builds
#
# Per context.md Section 3.1: Use Quarto (.qmd) not rmarkdown (.Rmd)
# Per user: Use default.R + rix::rix(), not manual default.nix edits
#
# Closes #14
#
# 🤖 Generated with [Claude Code](https://claude.com/claude-code)
#
# Co-Authored-By: Claude <noreply@anthropic.com>"
# )

# Push to remote
# gert::git_push()
