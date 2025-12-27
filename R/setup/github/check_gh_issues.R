# Check GitHub issues using R packages
# Created: 2025-11-10
# Purpose: Check for open issues on remote repo using gh R package

# Load required packages
library(gh)
library(gert)
library(usethis)

# Print package versions
cat("=== Package Versions ===\n")
cat("gh version:", as.character(packageVersion("gh")), "\n")
cat("gert version:", as.character(packageVersion("gert")), "\n")
cat("usethis version:", as.character(packageVersion("usethis")), "\n\n")

# Get repo info
repo_info <- gert::git_info()
cat("=== Repository Info ===\n")
cat("Repository:", repo_info$url, "\n")
cat("Current branch:", gert::git_branch(), "\n\n")

# List open issues
cat("=== Fetching Open Issues ===\n")
issues <- gh::gh("/repos/{owner}/{repo}/issues",
                 owner = "JohnGavin",
                 repo = "randomwalk",
                 state = "open")

if(length(issues) == 0) {
  cat("No open issues found\n")
} else {
  cat(sprintf("Found %d open issue(s):\n\n", length(issues)))
  for(i in seq_along(issues)) {
    cat(sprintf("#%d: %s\n", issues[[i]]$number, issues[[i]]$title))
    cat(sprintf("   State: %s\n", issues[[i]]$state))
    cat(sprintf("   Created: %s\n", issues[[i]]$created_at))
    cat(sprintf("   URL: %s\n\n", issues[[i]]$html_url))
  }
}

# Check git status
cat("=== Git Status ===\n")
status <- gert::git_status()
if(nrow(status) > 0) {
  cat(sprintf("%d file(s) with changes:\n", nrow(status)))
  print(status[, c("file", "status")])
} else {
  cat("Working directory clean\n")
}
