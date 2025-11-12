# Check status of Issue #16: Telemetry vignette missing visualizations
# Date: 2025-11-10
# Branch: feature/fix-missing-visualizations-16

library(gh)
library(gert)

# Get issue details
cat("=== Issue #16 Details ===\n")
issue_16 <- gh::gh("GET /repos/JohnGavin/randomwalk/issues/16")

cat("Title:", issue_16$title, "\n")
cat("State:", issue_16$state, "\n")
cat("Created:", issue_16$created_at, "\n")
cat("Body:\n", issue_16$body, "\n\n")

# Check current branch and status
cat("=== Git Status ===\n")
branch_info <- gert::git_branch()
cat("Current branch:", branch_info, "\n\n")

status <- gert::git_status()
if (nrow(status) > 0) {
  cat("Modified/untracked files:\n")
  print(status[, c("file", "status")])
} else {
  cat("Working directory clean\n")
}

cat("\n=== Recent Commits on This Branch ===\n")
commits <- gert::git_log(max = 5)
print(commits[, c("commit", "author", "message", "time")])
