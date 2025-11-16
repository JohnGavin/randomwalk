#!/usr/bin/env Rscript
# Commit telemetry fix
# Date: 2025-11-16
# Purpose: Commit and push the telemetry_summary target fix

library(logger)
library(gert)

# Setup logging
log_file <- "R/setup/commit_telemetry_fix.log"
log_appender(appender_tee(log_file))
log_info("Starting commit process for telemetry fix")

# Set working directory
repo_path <- "/Users/johngavin/docs_gh/claude_rix/random_walk"
setwd(repo_path)

# Check current status
status <- gert::git_status()
log_info("Current git status:")
print(status)

# Add the modified _targets.R file
log_info("Adding _targets.R to staging area")
gert::git_add("_targets.R")

# Also add the fix scripts for documentation
log_info("Adding fix scripts to staging area")
gert::git_add("R/setup/fix_telemetry_target.R")
gert::git_add("R/setup/fix_telemetry_target.log")
gert::git_add("R/setup/commit_telemetry_fix.R")

# Create commit message
commit_msg <- "Fix telemetry vignette: add missing telemetry_summary target

- Added telemetry_summary target to _targets.R
- Target collects pipeline metadata (time, memory, status)
- Fixes pkgdown workflow failure in PR #19
- Formatted data for display in telemetry.qmd vignette

Resolves pkgdown build error:
  Error: target telemetry_summary not found

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

log_info("Creating commit")
commit_info <- gert::git_commit(commit_msg)
log_info("Commit created: {commit_info$commit}")

# Push to remote
log_info("Pushing to remote")
gert::git_push(
  remote = "origin",
  refspec = "refs/heads/fix/shinylive-dashboard",
  repo = repo_path,
  verbose = TRUE
)
log_info("Successfully pushed to origin/fix/shinylive-dashboard")

# Display summary
cat("\n", strrep("=", 70), "\n", sep = "")
cat("✅ Telemetry Fix Committed and Pushed\n")
cat(strrep("=", 70), "\n\n", sep = "")
cat("Commit:", commit_info$commit, "\n")
cat("Branch: fix/shinylive-dashboard\n")
cat("Files changed:\n")
cat("  - _targets.R (added telemetry_summary target)\n")
cat("  - R/setup/fix_telemetry_target.R\n")
cat("  - R/setup/fix_telemetry_target.log\n")
cat("  - R/setup/commit_telemetry_fix.R\n\n")
cat("Next: Monitor GitHub Actions for PR #19\n")
cat("  https://github.com/JohnGavin/randomwalk/pull/19\n")
cat(strrep("=", 70), "\n", sep = "")

log_info("Commit process completed successfully")
