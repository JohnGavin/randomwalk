#!/usr/bin/env Rscript
# Create PR for macOS workflow changes
# Date: 2025-11-06

library(gh)
library(logger)

log_info("Creating PR for issue #7")

tryCatch({
  pr <- gh::gh(
    "POST /repos/JohnGavin/randomwalk/pulls",
    title = "Comment out macOS runner in tests-r-via-nix workflow (#7)",
    head = "feature/github-workflows-5",
    base = "main",
    body = "## Summary
- Commented out macOS runner from tests-r-via-nix workflow
- Reduces CI time and costs by only running tests on Ubuntu

## Changes
- Modified `.github/workflows/tests-r-via-nix.yaml` to only use `ubuntu-latest`
- macOS runner commented out from the OS matrix

## Related Issue
Closes #7

## Test Results
✅ R-tests-via-nix: Passed
✅ pkgdown: Passed

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
  )

  cat("\n✅ Pull request created successfully!\n")
  cat("PR URL:", pr$html_url, "\n")
  cat("PR Number:", pr$number, "\n")
  log_info("PR #{pr$number} created: {pr$html_url}", pr = pr)
}, error = function(e) {
  log_error("Failed to create PR: {e$message}", e = e)
  cat("Error creating PR:", e$message, "\n")
})
