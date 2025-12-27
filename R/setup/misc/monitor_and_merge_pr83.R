# Monitor PR #83 CI/CD and Auto-Merge When Passing
# Created: 2025-12-05
# Purpose: Automatically merge PR #83 once all CI/CD checks pass

library(gh)
library(logger)

log_appender(appender_console)
log_threshold(INFO)

pr_number <- 83
max_attempts <- 30  # 30 minutes max
check_interval <- 60  # Check every 60 seconds

log_info("Starting CI/CD monitor for PR #{pr_number}")
log_info("Will check every {check_interval} seconds for up to {max_attempts} attempts")

for (attempt in 1:max_attempts) {
  log_info("Attempt {attempt}/{max_attempts}: Checking PR #{pr_number} status...")

  # Get PR status
  tryCatch({
    # Run gh pr checks and capture output
    result <- system2("gh", args = c("pr", "checks", as.character(pr_number)),
                     stdout = TRUE, stderr = TRUE)
    exit_code <- attr(result, "status")

    if (is.null(exit_code)) exit_code <- 0

    log_info("gh pr checks exit code: {exit_code}")

    if (exit_code == 0) {
      # All checks passed!
      log_info("✅ All CI/CD checks PASSED for PR #{pr_number}!")
      log_info("Merging PR #{pr_number}...")

      # Merge the PR
      merge_result <- system2("gh",
                             args = c("pr", "merge", as.character(pr_number),
                                     "--squash", "--delete-branch"),
                             stdout = TRUE, stderr = TRUE)

      log_info("Merge result: {paste(merge_result, collapse = '\n')}")
      log_info("✅ PR #{pr_number} successfully merged and branch deleted!")

      # Success - exit
      quit(status = 0)

    } else if (exit_code == 1) {
      # Checks failed
      log_error("❌ CI/CD checks FAILED for PR #{pr_number}")
      log_error("Output: {paste(result, collapse = '\n')}")
      log_error("Manual intervention required - check GitHub Actions logs")
      quit(status = 1)

    } else if (exit_code == 8) {
      # Still pending
      log_info("⏳ CI/CD checks still PENDING for PR #{pr_number}")
      log_info("Waiting {check_interval} seconds before next check...")
      Sys.sleep(check_interval)

    } else {
      # Unknown status
      log_warn("⚠️ Unknown exit code {exit_code} for PR #{pr_number}")
      log_warn("Output: {paste(result, collapse = '\n')}")
      Sys.sleep(check_interval)
    }

  }, error = function(e) {
    log_error("Error checking PR status: {e$message}")
    Sys.sleep(check_interval)
  })
}

# Timeout reached
log_warn("⏰ Timeout reached after {max_attempts} attempts ({max_attempts * check_interval / 60} minutes)")
log_warn("PR #{pr_number} CI/CD still not complete - manual check required")
quit(status = 2)
