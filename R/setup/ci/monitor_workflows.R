# Monitor GitHub Actions workflows for PR #17
# Created: 2025-11-10
# Purpose: Check workflow status until all complete

library(gh)

cat("=== Monitoring GitHub Actions for PR #17 ===\n")
cat("Started:", as.character(Sys.time()), "\n\n")

# Get the latest workflow runs
check_workflows <- function() {
  runs <- gh::gh('/repos/{owner}/{repo}/actions/runs',
                 owner = 'JohnGavin',
                 repo = 'randomwalk',
                 branch = 'feature/fix-missing-visualizations-16',
                 per_page = 10)

  # Get the most recent run for each workflow
  latest_runs <- list()
  for(run in runs$workflow_runs) {
    workflow_name <- run$name
    if(is.null(latest_runs[[workflow_name]]) ||
       run$created_at > latest_runs[[workflow_name]]$created_at) {
      latest_runs[[workflow_name]] <- run
    }
  }

  return(latest_runs)
}

# Display status
display_status <- function(runs) {
  cat("\n--- Workflow Status ---\n")
  all_complete <- TRUE
  all_success <- TRUE

  for(name in names(runs)) {
    run <- runs[[name]]
    cat(sprintf("%-20s | Status: %-12s | Conclusion: %s\n",
                name, run$status,
                ifelse(is.null(run$conclusion), "pending", run$conclusion)))

    if(run$status != "completed") {
      all_complete <- FALSE
    }
    if(!is.null(run$conclusion) && run$conclusion != "success") {
      all_success <- FALSE
    }
  }

  cat("\n")
  return(list(complete = all_complete, success = all_success))
}

# Check current status
runs <- check_workflows()
status <- display_status(runs)

if(status$complete) {
  if(status$success) {
    cat("✅ ALL WORKFLOWS PASSED!\n")
    cat("PR #17 is ready to merge.\n")
  } else {
    cat("❌ Some workflows failed.\n")
    cat("Check the URLs above for details.\n")
  }
} else {
  cat("⏳ Workflows still running...\n")
  cat("Check status at: https://github.com/JohnGavin/randomwalk/pull/17/checks\n")
}

cat("\nCompleted:", as.character(Sys.time()), "\n")
