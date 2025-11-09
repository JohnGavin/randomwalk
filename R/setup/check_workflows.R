#!/usr/bin/env Rscript
# Check GitHub Actions workflow status
# Date: 2025-11-06

library(gh)
library(logger)

log_info("Checking GitHub Actions workflow status")

# Get the latest workflow runs for the current branch
tryCatch({
  runs <- gh::gh(
    "GET /repos/JohnGavin/randomwalk/actions/runs",
    branch = "feature/github-workflows-5",
    per_page = 10
  )

  if (length(runs$workflow_runs) == 0) {
    cat("No workflow runs found for this branch yet.\n")
    log_warn("No workflow runs found")
  } else {
    cat("\nRecent workflow runs:\n")
    cat(strrep("=", 80), "\n")

    for (i in seq_along(runs$workflow_runs)) {
      run <- runs$workflow_runs[[i]]
      cat(sprintf(
        "%d. %s\n   Status: %s | Conclusion: %s\n   Created: %s\n   URL: %s\n\n",
        i,
        run$name,
        run$status,
        if (is.null(run$conclusion)) "pending" else run$conclusion,
        run$created_at,
        run$html_url
      ))
    }
  }

  # Check if all completed runs passed
  completed_runs <- Filter(function(r) r$status == "completed", runs$workflow_runs)
  if (length(completed_runs) > 0) {
    all_passed <- all(sapply(completed_runs, function(r) r$conclusion == "success"))

    if (all_passed) {
      cat("\n✅ All completed workflows passed!\n")
      log_info("All workflows passed")
    } else {
      cat("\n❌ Some workflows failed. Please review the logs.\n")
      log_warn("Some workflows failed")
    }
  } else {
    cat("\n⏳ Workflows are still running or pending...\n")
    log_info("Workflows still running")
  }

}, error = function(e) {
  log_error("Failed to check workflows: {e$message}", e = e)
  cat("Error checking workflows:", e$message, "\n")
})
