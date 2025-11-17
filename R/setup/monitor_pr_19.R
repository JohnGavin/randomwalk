#!/usr/bin/env Rscript
# PR #19 Monitoring Script
# Date: 2025-11-16
# Purpose: Monitor GitHub Actions status for PR #19

library(logger)
library(gh)

# Setup logging
log_file <- "R/setup/monitor_pr_19.log"
log_appender(appender_tee(log_file))
log_info("Starting PR #19 monitoring")

# PR details
owner <- "JohnGavin"
repo <- "randomwalk"
pr_number <- 19

# Get PR status
log_info("Fetching PR #{pr_number} status...")
pr_info <- gh::gh(
  "GET /repos/{owner}/{repo}/pulls/{pull_number}",
  owner = owner,
  repo = repo,
  pull_number = pr_number
)

cat("\n", strrep("=", 70), "\n", sep = "")
cat("PR #", pr_number, ": ", pr_info$title, "\n", sep = "")
cat(strrep("=", 70), "\n\n", sep = "")

cat("Status:", pr_info$state, "\n")
cat("URL:", pr_info$html_url, "\n")
cat("Base:", pr_info$base$ref, "\n")
cat("Head:", pr_info$head$ref, "\n")
cat("Mergeable:", ifelse(is.null(pr_info$mergeable), "checking...", pr_info$mergeable), "\n")
cat("Created:", pr_info$created_at, "\n")
cat("Updated:", pr_info$updated_at, "\n\n")

# Get check runs
log_info("Fetching check runs...")
checks <- gh::gh(
  "GET /repos/{owner}/{repo}/commits/{ref}/check-runs",
  owner = owner,
  repo = repo,
  ref = pr_info$head$sha
)

if (checks$total_count > 0) {
  cat("GitHub Actions Status:\n")
  cat(strrep("-", 70), "\n", sep = "")

  for (check in checks$check_runs) {
    status_icon <- switch(
      check$status,
      "completed" = if(check$conclusion == "success") "✅" else "❌",
      "in_progress" = "⏳",
      "queued" = "⏸️",
      "⚠️"
    )

    conclusion <- if(check$status == "completed") {
      paste0(" (", check$conclusion, ")")
    } else {
      ""
    }

    cat(sprintf("%s %-40s %s%s\n",
                status_icon,
                substr(check$name, 1, 40),
                check$status,
                conclusion))

    log_info("{check$name}: {check$status}{conclusion}")
  }

  cat(strrep("-", 70), "\n\n", sep = "")

  # Summary
  completed_count <- sum(sapply(checks$check_runs, function(x) x$status == "completed"))
  success_count <- sum(sapply(checks$check_runs, function(x) {
    x$status == "completed" && x$conclusion == "success"
  }))

  cat("Summary:\n")
  cat("  Total checks:", checks$total_count, "\n")
  cat("  Completed:", completed_count, "/", checks$total_count, "\n")
  cat("  Successful:", success_count, "/", checks$total_count, "\n\n")

  if (completed_count == checks$total_count && success_count == checks$total_count) {
    cat("✅ All checks passed! PR is ready to merge.\n")
    log_info("All checks passed")
  } else if (completed_count == checks$total_count) {
    cat("❌ Some checks failed. Review required.\n")
    log_warn("Some checks failed")
  } else {
    cat("⏳ Checks still running. Wait for completion.\n")
    log_info("Checks in progress")
  }
} else {
  cat("No checks found yet. Workflows may still be initializing.\n")
  log_info("No checks found")
}

cat("\n")
cat("Monitor live at:\n")
cat("  PR:", pr_info$html_url, "\n")
cat("  Actions:", paste0("https://github.com/", owner, "/", repo, "/actions"), "\n")
cat("\n", strrep("=", 70), "\n", sep = "")

log_info("Monitoring complete")

# Save status
status_summary <- list(
  pr_number = pr_number,
  state = pr_info$state,
  mergeable = pr_info$mergeable,
  total_checks = checks$total_count,
  completed_checks = if(checks$total_count > 0) {
    sum(sapply(checks$check_runs, function(x) x$status == "completed"))
  } else 0,
  successful_checks = if(checks$total_count > 0) {
    sum(sapply(checks$check_runs, function(x) {
      x$status == "completed" && x$conclusion == "success"
    }))
  } else 0,
  checked_at = Sys.time()
)

saveRDS(status_summary, "R/setup/pr_19_status.rds")
log_info("Status saved to R/setup/pr_19_status.rds")
