# Fix Three Critical Issues: 404, Shinylive, and Nix Examples
# Date: 2025-12-25
# Session log for comprehensive fixes

# ============================================================================
# ISSUE SUMMARY
# ============================================================================

# 1. 404 Error at /bin/emscripten/contrib/4.4/
#    - GitHub Pages doesn't support symlinks
#    - Fix: Replace symlink with directory copy in deploy-pages.yaml
#
# 2. Shinylive Dashboard: run_simulation not found
#    - Incorrect webR repo URL in dashboard_comprehensive.qmd
#    - Fix: Change from "https://johngavin.github.io/randomwalk/repo"
#           to "https://johngavin.github.io/randomwalk"
#
# 3. Missing Nix command-line examples in README
#    - No Nix shell usage examples in documentation
#    - Fix: Add Nix shell section to README.md

# ============================================================================
# STEP 1: CREATE GITHUB ISSUE
# ============================================================================

cat("\n=== STEP 1: Creating GitHub Issue ===\n")
cat("Timestamp:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")

library(gh)

issue_body <- "## Summary

Three critical issues identified that need fixing:

### 1. 404 Error at `/bin/emscripten/contrib/4.4/`

**Problem**: GitHub Pages returns 404 for this path which is referenced by webR package installation.

**Root Cause**: The workflow creates a symlink `4.4 -> 4.5` but GitHub Pages doesn't support symlinks.

**Location**: `.github/workflows/deploy-pages.yaml:72`

**Fix**: Replace symlink creation with directory copy:
\`\`\`yaml
cp -r docs/bin/emscripten/contrib/4.5 docs/bin/emscripten/contrib/4.4
\`\`\`

### 2. Shinylive Dashboard: `run_simulation` Function Not Found

**Problem**: Dashboard at https://johngavin.github.io/randomwalk/articles/dashboard_comprehensive.html shows error \"could not find function 'run_simulation'\" when simulation runs.

**Root Cause**: Incorrect webR repository URL in package installation code.

**Location**: `vignettes/dashboard_comprehensive.qmd:52`

**Current (Wrong)**:
\`\`\`r
repos = c(
  \"https://johngavin.github.io/randomwalk/repo\",  # ❌ Wrong path
  ...
)
\`\`\`

**Fix**:
\`\`\`r
repos = c(
  \"https://johngavin.github.io/randomwalk\",  # ✅ Correct path
  ...
)
\`\`\`

### 3. Missing Nix Command-Line Examples

**Problem**: README lacks examples showing how to run randomwalk from Nix shell.

**Location**: `README.md` Usage section (after line 94)

**Fix**: Add new subsection \"Using Nix Shell\" with command-line examples.

## Impact

- **Issue 1**: Blocks webR package installation from GitHub Pages for R 4.4 users
- **Issue 2**: Breaks interactive Shinylive dashboard functionality
- **Issue 3**: Makes it harder for users to use the Nix reproducible environment

## Implementation Plan

Following the 9-step mandatory workflow:
1. ✅ Create this issue
2. Create dev branch
3. Make all three fixes
4. Run checks (devtools::check, pkgdown::build_site)
5. Push to cachix
6. Push to GitHub
7. Wait for CI
8. Merge PR
9. Log session

## Files to Modify

- `.github/workflows/deploy-pages.yaml`
- `vignettes/dashboard_comprehensive.qmd`
- `README.md`
"

# Create the issue
tryCatch({
  issue <- gh(
    "POST /repos/{owner}/{repo}/issues",
    owner = "JohnGavin",
    repo = "randomwalk",
    title = "Fix: 404 error, Shinylive run_simulation not found, and missing Nix examples",
    body = issue_body,
    labels = list("bug", "documentation", "enhancement")
  )

  issue_number <- issue$number
  cat("✅ GitHub Issue created: #", issue_number, "\n", sep = "")
  cat("   URL:", issue$html_url, "\n")

  # Save issue number for later use
  saveRDS(issue_number, "issue_number.rds")

}, error = function(e) {
  cat("❌ Error creating issue:", conditionMessage(e), "\n")
  cat("Note: If gh auth failed, the issue needs to be created manually.\n")
  issue_number <- NA
})

cat("\n=== STEP 1 COMPLETE ===\n\n")

# ============================================================================
# STEP 2: CREATE DEVELOPMENT BRANCH
# ============================================================================

cat("\n=== STEP 2: Creating Development Branch ===\n")

library(usethis)
library(gert)

# Create branch name
if (!is.na(issue_number)) {
  branch_name <- paste0("fix-issue-", issue_number, "-critical-fixes")
} else {
  branch_name <- "fix-critical-issues-404-shinylive-nix"
}

cat("Branch name:", branch_name, "\n")

tryCatch({
  usethis::pr_init(branch = branch_name)
  cat("✅ Development branch created:", branch_name, "\n")
}, error = function(e) {
  cat("❌ Error creating branch:", conditionMessage(e), "\n")
  # Fallback to gert
  tryCatch({
    gert::git_branch_create(branch_name)
    cat("✅ Branch created via gert:", branch_name, "\n")
  }, error = function(e2) {
    cat("❌ gert also failed:", conditionMessage(e2), "\n")
  })
})

cat("\n=== STEP 2 COMPLETE ===\n\n")

# ============================================================================
# NEXT STEPS (To be executed after file modifications)
# ============================================================================

cat("\n=== NEXT STEPS ===\n")
cat("After making the file changes:\n")
cat("1. Run devtools::document()\n")
cat("2. Run devtools::check()\n")
cat("3. Run pkgdown::build_site()\n")
cat("4. Push to cachix: ../push_to_cachix.sh\n")
cat("5. Push to GitHub: usethis::pr_push()\n")
cat("6. Wait for CI to pass\n")
cat("7. Merge PR: usethis::pr_merge_main()\n")
cat("8. Clean up: usethis::pr_finish()\n")

cat("\n=== SESSION INFO ===\n")
sessionInfo()
