# Commit and push Shiny dashboard feature
# Following r-package-workflow guidelines

library(gert)
library(gh)
library(usethis)
library(logger)

# Setup logging
log_file <- "R/setup/commit_dashboard_feature.log"
logger::log_appender(logger::appender_file(log_file))
logger::log_info("Starting dashboard feature commit workflow")

# =============================================================================
# STEP 1: Create feature branch
# =============================================================================

branch_name <- "feature/shiny-dashboard"
logger::log_info("Creating branch: {branch_name}")

# Check current branch
current_branch <- gert::git_branch()
logger::log_info("Current branch: {current_branch}")

if (current_branch != "main") {
  logger::log_warn("Not on main branch, switching to main first")
  gert::git_branch_checkout("main")
}

# Create and checkout feature branch
tryCatch({
  gert::git_branch_create(branch_name)
  logger::log_info("Created new branch: {branch_name}")
}, error = function(e) {
  logger::log_info("Branch may already exist, checking out: {branch_name}")
  gert::git_branch_checkout(branch_name)
})

# =============================================================================
# STEP 2: Stage files
# =============================================================================

logger::log_info("Staging files")

files_to_add <- c(
  # Core Shiny module
  "R/shiny_modules.R",

  # Vignette
  "inst/qmd/dashboard.qmd",

  # Tests
  "tests/testthat/test-shiny_modules.R",

  # Updated dependencies
  "DESCRIPTION",
  "default.R",

  # Documentation
  "NAMESPACE",
  "man/run_dashboard.Rd",
  "man/sim_input_server.Rd",
  "man/sim_input_ui.Rd",
  "man/sim_output_server.Rd",
  "man/sim_output_ui.Rd",
  "man/plot_grid.Rd"
)

gert::git_add(files_to_add)
logger::log_info("Staged {length(files_to_add)} files")

# Check status
status <- gert::git_status()
logger::log_info("Files changed: {nrow(status)}")
print(status)

# =============================================================================
# STEP 3: Commit changes
# =============================================================================

commit_msg <- "Add interactive Shiny dashboard for random walk simulations

Features:
- Modular Shiny architecture (input/output modules)
- Interactive parameter controls with dynamic validation
- Multiple output views: grid state, walker paths, statistics, raw data
- Complete separation of GUI code from simulation logic
- Comprehensive shinytest2 test suite (15 tests)
- Detailed dashboard vignette with usage examples

Files added:
- R/shiny_modules.R: Module functions and main app
- inst/qmd/dashboard.qmd: Dashboard documentation vignette
- tests/testthat/test-shiny_modules.R: Comprehensive test suite

Dependencies updated:
- Added shiny, shinytest2 to DESCRIPTION and default.R

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

commit_sha <- gert::git_commit(commit_msg)
logger::log_info("Committed: {commit_sha}")

# =============================================================================
# STEP 4: Push to remote
# =============================================================================

logger::log_info("Pushing to remote...")

# Push and set upstream
gert::git_push(set_upstream = TRUE)
logger::log_info("Pushed to remote")

# =============================================================================
# STEP 5: Create Pull Request
# =============================================================================

logger::log_info("Creating pull request...")

# Get repo info
repo_info <- gh::gh("GET /repos/{owner}/{repo}",
                    owner = "JohnGavin",
                    repo = "randomwalk")

pr_body <- "## Summary

This PR adds a comprehensive interactive Shiny dashboard for exploring random walk simulations.

## Features

- **Modular Architecture**: Clean separation between input controls, output displays, and simulation logic
- **Interactive Controls**: Dynamic parameter validation (max walkers updates with grid size)
- **Multiple Output Views**:
  - Grid State: Final simulation grid with black pixels
  - Walker Paths: Trajectories and termination points
  - Statistics: Detailed metrics and summary tables
  - Raw Data: Walker-level information
- **Professional UI**: Bootstrap styling with progress indicators and status messages
- **Comprehensive Tests**: 15 test cases using shinytest2
- **Complete Documentation**: Detailed vignette with architecture, examples, and extension guidelines

## Files Changed

### New Files
- `R/shiny_modules.R` - Shiny module functions and main dashboard app
- `inst/qmd/dashboard.qmd` - Comprehensive dashboard vignette
- `tests/testthat/test-shiny_modules.R` - Test suite (15 tests)

### Modified Files
- `DESCRIPTION` - Added shinytest2 to Suggests
- `default.R` - Added shinytest2 to r_pkgs
- `NAMESPACE` - Exported new functions
- `man/*.Rd` - Generated documentation files

## Testing

All tests pass locally:
- Unit tests for UI components
- Server logic validation
- Module integration tests
- Input validation tests
- Error handling tests

## Usage

```r
library(randomwalk)

# Launch dashboard
run_dashboard()

# Or with options
run_dashboard(options = list(port = 3838), launch.browser = TRUE)
```

## Architecture

The dashboard follows best practices with complete module independence:
- GUI code is fully separated from simulation logic
- Modules are reusable and composable
- Simulation functions work identically with or without the dashboard
- Easy to extend with new features

## Documentation

See the new vignette for complete details:
- Architecture overview
- Usage examples
- Parameter explanations
- Extension guidelines
- Integration with targets pipeline

🤖 Generated with [Claude Code](https://claude.com/claude-code)"

pr <- gh::gh("POST /repos/{owner}/{repo}/pulls",
             owner = "JohnGavin",
             repo = "randomwalk",
             title = "Add interactive Shiny dashboard",
             body = pr_body,
             head = branch_name,
             base = "main")

pr_number <- pr$number
pr_url <- pr$html_url

logger::log_info("Created PR #{pr_number}: {pr_url}")
cat("\n✅ Pull Request created!\n")
cat("URL:", pr_url, "\n")
cat("Number:", pr_number, "\n")

# =============================================================================
# STEP 6: Wait for workflows to complete
# =============================================================================

logger::log_info("Waiting for GitHub Actions to start...")
Sys.sleep(15)  # Give workflows time to start

logger::log_info("Monitoring GitHub Actions...")

check_count <- 0
max_checks <- 60  # Max 30 minutes (60 * 30 seconds)

repeat {
  check_count <- check_count + 1

  # Get workflow runs for this branch
  runs <- gh::gh("/repos/{owner}/{repo}/actions/runs",
                 owner = "JohnGavin",
                 repo = "randomwalk",
                 branch = branch_name,
                 per_page = 10)

  cat("\n=== GitHub Actions Status (Check {check_count}) ===\n")

  if (length(runs$workflow_runs) == 0) {
    logger::log_info("No workflows found yet, waiting...")
    Sys.sleep(30)
    next
  }

  all_complete <- TRUE
  all_success <- TRUE

  for (run in runs$workflow_runs) {
    status_str <- sprintf("%-30s | Status: %-12s | Conclusion: %s",
                          run$name,
                          run$status,
                          ifelse(is.null(run$conclusion), "pending", run$conclusion))
    cat(status_str, "\n")

    if (run$status != "completed") {
      all_complete <- FALSE
    }

    if (!is.null(run$conclusion) && run$conclusion != "success") {
      all_success <- FALSE
    }
  }

  if (all_complete) {
    if (all_success) {
      logger::log_info("All workflows completed successfully!")
      cat("\n✅ All workflows passed!\n")
      break
    } else {
      logger::log_error("Some workflows failed!")
      cat("\n❌ Some workflows failed. Please check GitHub Actions.\n")
      cat("PR URL:", pr_url, "\n")
      stop("Workflows failed")
    }
  }

  if (check_count >= max_checks) {
    logger::log_warn("Timeout waiting for workflows")
    cat("\n⚠️  Timeout waiting for workflows. Check status manually.\n")
    cat("PR URL:", pr_url, "\n")
    stop("Workflow timeout")
  }

  logger::log_info("Waiting 30 seconds before next check...")
  Sys.sleep(30)
}

# =============================================================================
# STEP 7: Merge PR
# =============================================================================

logger::log_info("All workflows passed! Merging PR...")

merge_result <- gh::gh("PUT /repos/{owner}/{repo}/pulls/{number}/merge",
                       owner = "JohnGavin",
                       repo = "randomwalk",
                       number = pr_number,
                       commit_title = "Merge pull request: Add interactive Shiny dashboard",
                       merge_method = "merge")

logger::log_info("PR merged successfully!")
cat("\n✅ PR merged to main!\n")

# =============================================================================
# STEP 8: Switch back to main and clean up
# =============================================================================

logger::log_info("Switching back to main branch...")
gert::git_branch_checkout("main")

logger::log_info("Pulling latest changes...")
gert::git_pull()

logger::log_info("Deleting local feature branch...")
gert::git_branch_delete(branch_name)

# =============================================================================
# COMPLETE!
# =============================================================================

logger::log_info("Workflow complete!")
cat("\n🎉 All done!\n")
cat("✅ Dashboard feature added\n")
cat("✅ Tests passed\n")
cat("✅ PR merged to main\n")
cat("✅ Local branch cleaned up\n")
cat("\nPR URL:", pr_url, "\n")
