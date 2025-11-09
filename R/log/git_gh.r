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
