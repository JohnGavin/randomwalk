#!/usr/bin/env Rscript
# Wait for workflows to complete and create PR
# Date: 2025-11-06

library(gh)
library(logger)

log_info("Monitoring workflows and will create PR when they pass")

max_attempts <- 60  # 60 attempts * 30 seconds = 30 minutes max
attempt <- 1
all_passed <- FALSE

while (attempt <= max_attempts && !all_passed) {
  cat(sprintf("\n[Attempt %d/%d] Checking workflow status...\n", attempt, max_attempts))

  tryCatch({
    runs <- gh::gh(
      "GET /repos/JohnGavin/randomwalk/actions/runs",
      branch = "feature/github-workflows-5",
      per_page = 5
    )

    if (length(runs$workflow_runs) == 0) {
      cat("No workflow runs found.\n")
      break
    }

    # Get the latest 3 runs (should be the current push)
    latest_runs <- runs$workflow_runs[1:min(3, length(runs$workflow_runs))]

    # Check status
    in_progress <- any(sapply(latest_runs, function(r) r$status != "completed"))

    if (in_progress) {
      cat("Workflows still running...\n")
      for (run in latest_runs) {
        cat(sprintf("  - %s: %s\n", run$name, run$status))
      }
      Sys.sleep(30)
      attempt <- attempt + 1
    } else {
      # All completed, check if they passed
      all_passed <- all(sapply(latest_runs, function(r) r$conclusion == "success"))

      if (all_passed) {
        cat("\n✅ All workflows passed!\n")
        log_info("All workflows passed, creating PR")

        # Create PR
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
All GitHub Actions workflows passed successfully.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
        )

        cat("\n✅ Pull request created successfully!\n")
        cat("PR URL:", pr$html_url, "\n")
        cat("PR Number:", pr$number, "\n")
        log_info("PR created: {pr$html_url}", pr = pr)
        break
      } else {
        cat("\n❌ Some workflows failed:\n")
        for (run in latest_runs) {
          if (run$conclusion != "success") {
            cat(sprintf("  - %s: %s\n", run$name, run$conclusion))
            cat(sprintf("    URL: %s\n", run$html_url))
          }
        }
        log_error("Workflows failed, not creating PR")
        break
      }
    }
  }, error = function(e) {
    log_error("Error checking workflows: {e$message}", e = e)
    cat("Error:", e$message, "\n")
    break
  })
}

if (attempt > max_attempts) {
  cat("\n⏱️  Timeout: Workflows took too long to complete\n")
  log_warn("Timeout waiting for workflows")
}
