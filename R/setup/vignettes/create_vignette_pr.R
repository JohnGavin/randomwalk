#!/usr/bin/env Rscript
# Create Pull Request for Vignette Reorganization
# Generated with Claude Code
# Date: 2025-11-16

# Setup logging
library(logger)
log_file <- "R/setup/create_vignette_pr.log"
log_appender(appender_file(log_file))
log_info("Starting PR creation for vignette reorganization")

# Load required packages
library(gert)
library(gh)

# Check current git status
log_info("Checking git status")
status <- gert::git_status()
log_info("Git status: {nrow(status)} files with changes")

# Get current branch
branch_info <- gert::git_branch_list(local = TRUE)
current_branch <- branch_info$name[branch_info$local_branch]
log_info("Current branch: {current_branch}")

# Get commit history for PR body
log_info("Getting commit history")
commits <- gert::git_log(max = 5)
latest_commit <- commits$commit[1]
log_info("Latest commit: {latest_commit}")
log_info("Commit message: {commits$message[1]}")

# Create PR title and body
pr_title <- "Move vignettes to standard location and update Shinylive dashboard"

pr_body <- "## Summary

This PR reorganizes vignettes to follow standard R package conventions and updates the Shinylive dashboard vignette with full WebAssembly support.

## Changes

### Vignette Reorganization
- ✅ Moved `telemetry.qmd` from `inst/qmd/` to `vignettes/` (standard R package location)
- ✅ Removed old `dashboard.qmd` from `inst/qmd/` (non-standard location)
- ✅ Updated `dashboard.qmd` in `vignettes/` with complete Shinylive implementation

### Dashboard Features
- Complete browser-based interactive Shiny application
- Parameter controls: grid size, walkers, neighborhood, boundary behavior
- Multiple output views: grid state, paths, statistics, raw data
- Runs entirely client-side using WebAssembly - no R server required
- Loads randomwalk package from mounted filesystem image
- Comprehensive documentation and usage examples

### Technical Details
- Uses Quarto shinylive extension for WebAssembly compilation
- Includes webR runtime and R package binaries (ggplot2, shiny, etc.)
- Vignettes now in standard `vignettes/` folder for pkgdown integration
- Dashboard will appear as article on GitHub Pages website

## Files Changed

- **vignettes/telemetry.qmd**: Moved from inst/qmd/
- **vignettes/dashboard.qmd**: Updated with full dashboard implementation
- **vignettes/dashboard.html**: Rendered output with embedded WebAssembly
- **vignettes/dashboard_files/**: Supporting assets (webR, libraries, fonts) - 229 files
- **inst/qmd/dashboard.qmd**: Removed (relocated to vignettes/)

## Statistics

- Total changes: **118,467 insertions**, **779 deletions**
- Files changed: **229 files**
- Dashboard HTML size: **50KB**

## Testing

### Local Testing
- [x] Rendered dashboard.qmd successfully with Quarto
- [x] Verified WebAssembly assets are included
- [x] Updated docs/articles/index.html with dashboard link
- [x] Updated docs/index.html navigation

### GitHub Pages Testing
- [ ] Dashboard accessible at `/articles/dashboard.html`
- [ ] WebAssembly loads correctly in browser
- [ ] Shinylive app runs without errors
- [ ] All navigation links work

## Deployment

Once merged, the dashboard will be available at:
https://johngavin.github.io/randomwalk/articles/dashboard.html

## Related Issues

Follows standard R package structure guidelines from `context.md`:
- Section 3.1: Use Quarto (.qmd) files for vignettes
- Section 3.3: Vignettes belong in vignettes/ folder
- Section 11: pkgdown website generation

🤖 Generated with [Claude Code](https://claude.com/claude-code)"

log_info("PR title: {pr_title}")
log_info("PR body length: {nchar(pr_body)} characters")

# Create pull request using gh package
log_info("Creating pull request")

tryCatch({
  # Create PR
  pr <- gh::gh(
    "POST /repos/{owner}/{repo}/pulls",
    owner = "JohnGavin",
    repo = "randomwalk",
    title = pr_title,
    body = pr_body,
    head = current_branch,
    base = "main"
  )

  pr_number <- pr$number
  pr_url <- pr$html_url

  log_info("Pull request created successfully")
  log_info("PR number: {pr_number}")
  log_info("PR URL: {pr_url}")

  # Print PR details
  cat("\n")
  cat("===========================================\n")
  cat("Pull Request Created Successfully!\n")
  cat("===========================================\n")
  cat(sprintf("PR #%d: %s\n", pr_number, pr_title))
  cat(sprintf("URL: %s\n", pr_url))
  cat(sprintf("Branch: %s -> main\n", current_branch))
  cat(sprintf("Commit: %s\n", substr(latest_commit, 1, 7)))
  cat("===========================================\n")
  cat("\n")

  # Save PR info for future reference
  pr_info <- list(
    number = pr_number,
    url = pr_url,
    title = pr_title,
    branch = current_branch,
    commit = latest_commit,
    created_at = Sys.time()
  )

  saveRDS(pr_info, "R/setup/pr_info.rds")
  log_info("PR info saved to R/setup/pr_info.rds")

}, error = function(e) {
  log_error("Failed to create pull request: {e$message}")
  cat("\nError creating pull request:\n")
  cat(e$message, "\n")
  quit(status = 1)
})

log_info("PR creation script completed successfully")
cat("\nLog saved to:", log_file, "\n")
