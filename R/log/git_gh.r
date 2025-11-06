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
