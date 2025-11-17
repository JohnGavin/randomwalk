#!/usr/bin/env Rscript
# PR Creation Script using gh, gert, usethis
# Date: 2025-11-16
# Purpose: Create PR for vignette reorganization and Shinylive dashboard updates
# Issue: Vignette standardization and dashboard deployment

library(logger)
library(gert)
library(gh)

# Setup logging
log_file <- "R/setup/create_vignette_pr_gh.log"
log_appender(appender_tee(log_file))
log_info("Starting PR creation process")

# Set working directory to repository root
repo_path <- "/Users/johngavin/docs_gh/claude_rix/random_walk"
setwd(repo_path)
log_info("Working directory: {getwd()}")

# Get repository information
repo_info <- gert::git_info()
log_info("Current branch: {repo_info$shorthand}")
log_info("Upstream: {repo_info$upstream}")

# Check git status
status <- gert::git_status()
log_info("Git status - Modified files: {nrow(status[status$status == 'modified',])}")
log_info("Git status - Untracked files: {nrow(status[status$status == 'new',])}")

# Read PR body from file
pr_body_file <- "R/setup/pr_body.md"
if (!file.exists(pr_body_file)) {
  log_error("PR body file not found: {pr_body_file}")
  stop("PR body file missing")
}
pr_body <- readLines(pr_body_file, warn = FALSE) |> paste(collapse = "\n")
log_info("PR body loaded from {pr_body_file}")

# PR details
pr_title <- "Move vignettes to standard location and update Shinylive dashboard"
base_branch <- "main"
head_branch <- "fix/shinylive-dashboard"

log_info("PR Title: {pr_title}")
log_info("Base branch: {base_branch}")
log_info("Head branch: {head_branch}")

# Check if branch is pushed to remote
remote_branches <- gert::git_branch_list(repo = repo_path)
branch_on_remote <- any(remote_branches$name == paste0("origin/", head_branch))

if (!branch_on_remote) {
  log_warn("Branch {head_branch} not found on remote")
  log_info("Pushing branch to remote...")

  tryCatch({
    gert::git_push(
      remote = "origin",
      refspec = paste0("refs/heads/", head_branch),
      repo = repo_path,
      verbose = TRUE
    )
    log_info("Successfully pushed {head_branch} to origin")
  }, error = function(e) {
    log_error("Failed to push branch: {e$message}")
    stop("Branch push failed")
  })
} else {
  log_info("Branch {head_branch} already exists on remote")
}

# Get repository owner and name from remote URL
remote_url <- gert::git_remote_list(repo = repo_path)$url[1]
log_info("Remote URL: {remote_url}")

# Extract owner/repo from GitHub URL
repo_match <- regmatches(remote_url, regexec("github\\.com[:/]([^/]+)/([^.]+)", remote_url))[[1]]
if (length(repo_match) < 3) {
  log_error("Could not parse repository from remote URL: {remote_url}")
  stop("Invalid remote URL")
}
owner <- repo_match[2]
repo_name <- repo_match[3]
log_info("Repository: {owner}/{repo_name}")

# Check if PR already exists
log_info("Checking for existing PRs...")
tryCatch({
  existing_prs <- gh::gh(
    "GET /repos/{owner}/{repo}/pulls",
    owner = owner,
    repo = repo_name,
    state = "open",
    head = paste0(owner, ":", head_branch)
  )

  if (length(existing_prs) > 0) {
    pr_number <- existing_prs[[1]]$number
    pr_url <- existing_prs[[1]]$html_url
    log_warn("PR already exists: #{pr_number}")
    log_info("PR URL: {pr_url}")
    cat("\n✅ PR already exists!\n")
    cat("PR #", pr_number, "\n")
    cat("URL:", pr_url, "\n")
    quit(save = "no", status = 0)
  }
}, error = function(e) {
  log_warn("Error checking existing PRs: {e$message}")
})

# Create PR using gh package
log_info("Creating pull request...")
tryCatch({
  pr_response <- gh::gh(
    "POST /repos/{owner}/{repo}/pulls",
    owner = owner,
    repo = repo_name,
    title = pr_title,
    body = pr_body,
    head = head_branch,
    base = base_branch
  )

  pr_number <- pr_response$number
  pr_url <- pr_response$html_url

  log_info("✅ Successfully created PR #{pr_number}")
  log_info("PR URL: {pr_url}")

  # Print summary
  cat("\n", strrep("=", 60), "\n", sep = "")
  cat("✅ Pull Request Created Successfully!\n")
  cat(strrep("=", 60), "\n\n", sep = "")
  cat("PR #:", pr_number, "\n")
  cat("URL:", pr_url, "\n")
  cat("Title:", pr_title, "\n")
  cat("Base:", base_branch, "\n")
  cat("Head:", head_branch, "\n\n")
  cat("Next steps:\n")
  cat("1. Open PR in browser:", pr_url, "\n")
  cat("2. Wait for GitHub Actions to complete\n")
  cat("3. Review and merge when checks pass\n")
  cat("4. Dashboard will be live at:\n")
  cat("   https://johngavin.github.io/randomwalk/articles/dashboard.html\n")
  cat("\n", strrep("=", 60), "\n", sep = "")

  # Also save PR details to file
  pr_details <- list(
    number = pr_number,
    url = pr_url,
    title = pr_title,
    base = base_branch,
    head = head_branch,
    created_at = Sys.time()
  )
  saveRDS(pr_details, "R/setup/pr_details.rds")
  log_info("PR details saved to R/setup/pr_details.rds")

}, error = function(e) {
  log_error("Failed to create PR: {e$message}")
  cat("\n❌ Error creating PR:\n")
  cat(e$message, "\n")
  cat("\nYou can create the PR manually at:\n")
  cat(paste0("https://github.com/", owner, "/", repo_name, "/pull/new/", head_branch), "\n")
  stop("PR creation failed")
})

log_info("PR creation process completed successfully")
