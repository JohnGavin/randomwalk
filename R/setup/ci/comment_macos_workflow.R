#!/usr/bin/env Rscript
# Comment out macOS in GitHub Actions workflow
# Date: 2025-11-06

# Load required packages
library(gh)
library(gert)
library(logger)

# Set up logging
log_info("Starting workflow to comment out macOS in tests-r-via-nix.yaml")

# Step 1: Create GitHub issue
log_info("Step 1: Creating GitHub issue")
tryCatch({
  issue <- gh::gh(
    "POST /repos/JohnGavin/randomwalk/issues",
    title = "Comment out macOS runner in tests-r-via-nix workflow",
    body = "The macOS runner in the tests-r-via-nix.yaml workflow should be commented out to reduce CI time and costs. Only Ubuntu runner will be used for testing.

## Changes Made
- Commented out `macos-latest` from the OS matrix
- Only `ubuntu-latest` will run the tests

## Related Files
- `.github/workflows/tests-r-via-nix.yaml`"
  )

  issue_number <- issue$number
  log_info("Created issue #{issue_number}: {issue$html_url}", issue_number = issue_number, issue = issue)
  cat("Issue created:", issue$html_url, "\n")
  cat("Issue number:", issue_number, "\n")
}, error = function(e) {
  log_error("Failed to create issue: {e$message}", e = e)
  cat("Error creating issue:", e$message, "\n")
})

# Step 2: Stage and commit changes
log_info("Step 2: Staging and committing changes")
tryCatch({
  # Add the modified workflow file
  gert::git_add(".github/workflows/tests-r-via-nix.yaml")

  # Add this script to the log
  gert::git_add("R/setup/comment_macos_workflow.R")

  # Commit the changes
  commit_msg <- paste0(
    "Comment out macOS runner in tests-r-via-nix workflow\n\n",
    "- Reduce CI time and costs by only using Ubuntu runner\n",
    "- macOS-latest commented out from matrix.os\n",
    "- Addresses issue about workflow optimization"
  )

  gert::git_commit(commit_msg)
  log_info("Changes committed successfully")
  cat("Changes committed\n")
}, error = function(e) {
  log_error("Failed to commit: {e$message}", e = e)
  cat("Error committing:", e$message, "\n")
})

# Step 3: Push to remote
log_info("Step 3: Pushing to remote repository")
tryCatch({
  gert::git_push()
  log_info("Pushed to remote successfully")
  cat("Pushed to remote\n")
}, error = function(e) {
  log_error("Failed to push: {e$message}", e = e)
  cat("Error pushing:", e$message, "\n")
})

log_info("Workflow completed. Monitor GitHub Actions for test results.")
cat("\nNext steps:\n")
cat("1. Check GitHub Actions to ensure workflows pass\n")
cat("2. Create PR to merge into main\n")
cat("3. Delete development branch after merge\n")
