# Wait for workflows to complete and merge PR
library(gh)

pr_number <- 6
repo <- "JohnGavin/randomwalk"
max_wait_minutes <- 30
check_interval_seconds <- 30

cat("Waiting for GitHub Actions workflows to complete...\n")
cat(sprintf("Will check every %d seconds for up to %d minutes\n\n",
            check_interval_seconds, max_wait_minutes))

start_time <- Sys.time()
max_wait_seconds <- max_wait_minutes * 60

while (TRUE) {
  # Check elapsed time
  elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
  if (elapsed > max_wait_seconds) {
    cat("\nTimeout: Workflows did not complete within", max_wait_minutes, "minutes\n")
    quit(status = 1)
  }

  # Get PR details
  pr <- gh::gh(sprintf("GET /repos/%s/pulls/%d", repo, pr_number))

  # Get workflow runs
  runs <- gh::gh(sprintf("GET /repos/%s/actions/runs", repo),
                 event = "pull_request",
                 branch = "feature/github-workflows-5",
                 per_page = 10)

  # Filter to recent runs for this PR
  relevant_runs <- Filter(function(run) {
    run$head_sha == pr$head$sha
  }, runs$workflow_runs)

  if (length(relevant_runs) == 0) {
    cat("No workflow runs found yet, waiting...\n")
    Sys.sleep(check_interval_seconds)
    next
  }

  # Check status of all runs
  all_complete <- TRUE
  any_failed <- FALSE

  cat(sprintf("[%s] Workflow Status:\n", format(Sys.time(), "%H:%M:%S")))
  for (run in relevant_runs) {
    status <- run$status
    conclusion <- if (is.null(run$conclusion)) "pending" else run$conclusion

    cat(sprintf("  - %s: %s (%s)\n", run$name, status, conclusion))

    if (status != "completed") {
      all_complete <- FALSE
    }

    if (!is.null(run$conclusion) && run$conclusion != "success") {
      any_failed <- TRUE
    }
  }

  if (all_complete) {
    if (any_failed) {
      cat("\n❌ Some workflows failed. Not merging PR.\n")
      quit(status = 1)
    } else {
      cat("\n✅ All workflows passed successfully!\n")
      break
    }
  }

  cat(sprintf("Waiting %d seconds before next check...\n\n", check_interval_seconds))
  Sys.sleep(check_interval_seconds)
}

# All workflows passed, merge the PR
cat("\nMerging PR...\n")
merge_result <- gh::gh(
  sprintf("PUT /repos/%s/pulls/%d/merge", repo, pr_number),
  merge_method = "merge",
  commit_title = "Add GitHub Actions workflows for CI/CD with Nix (#5)",
  commit_message = "Merging PR #6 that closes issue #5"
)

cat("✅ PR merged successfully!\n")
cat("Merge commit SHA:", merge_result$sha, "\n")
cat("Merged:", merge_result$merged, "\n")
