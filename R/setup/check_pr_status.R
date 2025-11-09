# Check PR status and workflows
library(gh)

# Get PR details
pr <- gh::gh("GET /repos/JohnGavin/randomwalk/pulls/6")

cat("PR #6 Status:\n")
cat("State:", pr$state, "\n")
cat("Mergeable:", pr$mergeable, "\n")
cat("Merged:", pr$merged, "\n")

# Get workflow runs for this PR
runs <- gh::gh("GET /repos/JohnGavin/randomwalk/actions/runs",
               event = "pull_request",
               branch = "feature/github-workflows-5")

cat("\nWorkflow Runs:\n")
if (length(runs$workflow_runs) > 0) {
  for (run in runs$workflow_runs) {
    cat(sprintf("- %s: %s (conclusion: %s)\n",
                run$name,
                run$status,
                ifelse(is.null(run$conclusion), "pending", run$conclusion)))
  }
} else {
  cat("No workflow runs found yet\n")
}

# Check commit status
commit_sha <- pr$head$sha
statuses <- gh::gh(sprintf("GET /repos/JohnGavin/randomwalk/commits/%s/status", commit_sha))

cat("\nCommit Status:\n")
cat("State:", statuses$state, "\n")
cat("Total checks:", statuses$total_count, "\n")
