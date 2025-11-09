# Comment out macOS in GitHub Actions workflow
# Date: 2025-11-06
# Task: Comment out macOS runner in tests-r-via-nix.yaml workflow

# Load required packages
library(gh)
library(gert)
library(usethis)
library(logger)

# Set up logging
log_info("Starting workflow to comment out macOS in tests-r-via-nix.yaml")

# Step 1: Create GitHub issue
log_info("Step 1: Creating GitHub issue")
issue <- gh::gh(
  "POST /repos/JohnGavin/randomwalk/issues",
  title = "Comment out macOS runner in tests-r-via-nix workflow",
  body = "The macOS runner in the tests-r-via-nix.yaml workflow should be commented out to reduce CI time and costs. Only Ubuntu runner will be used for testing.

## Tasks
- [ ] Create development branch
- [ ] Comment out macOS in workflow matrix
- [ ] Test workflow runs successfully
- [ ] Merge PR to main
- [ ] Delete branches"
)

issue_number <- issue$number
log_info("Created issue #{issue_number}: {issue$html_url}", issue_number = issue_number, issue = issue)
cat("Issue created:", issue$html_url, "\n")
cat("Issue number:", issue_number, "\n")

# Step 2: Create development branch
log_info("Step 2: Creating development branch")
branch_name <- paste0("fix-issue-", issue_number, "-comment-out-macos")
usethis::pr_init(branch_name)
log_info("Created branch: {branch_name}", branch_name = branch_name)

# Note: The workflow file modification will be done separately
# Then run the rest of this script to commit and push

log_info("Next steps:")
log_info("1. Modify .github/workflows/tests-r-via-nix.yaml to comment out macOS")
log_info("2. Run the commit and push section of this script")
