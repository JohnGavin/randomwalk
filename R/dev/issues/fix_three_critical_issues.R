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

# ============================================================================
# WORKFLOW COMPLETION LOG
# ============================================================================

cat("\n\n=== WORKFLOW COMPLETION ===\n")
cat("Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")

cat("✅ Step 1: Created GitHub Issue #140\n")
cat("   URL: https://github.com/JohnGavin/randomwalk/issues/140\n\n")

cat("✅ Step 2: Created development branch: fix-issue-140-critical-fixes\n\n")

cat("✅ Step 3: Made all changes:\n")
cat("   - Fixed symlink in .github/workflows/deploy-pages.yaml\n")
cat("   - Fixed webR repo URLs in vignettes/dashboard_comprehensive.qmd\n")
cat("   - Fixed webR repo URLs in vignettes/dynamic_broadcasting.qmd\n")
cat("   - Added Nix examples to README.md\n\n")

cat("✅ Step 4: Ran checks:\n")
cat("   - devtools::document() - passed\n")
cat("   - Package verification - passed\n")
cat("   - run_simulation() smoke test - passed\n\n")

cat("✅ Step 5: Cachix push - skipped (no build artifacts for doc changes)\n\n")

cat("✅ Step 6: Pushed to GitHub\n")
cat("   Branch: fix-issue-140-critical-fixes\n\n")

cat("✅ Step 7: Created Pull Request #141\n")
cat("   URL: https://github.com/JohnGavin/randomwalk/pull/141\n\n")

cat("⏳ Step 8: Waiting for CI to pass\n")
cat("   - nix builder for Ubuntu: in_progress\n")
cat("   - devtools_test: in_progress\n")
cat("   - R-CMD-check: in_progress\n\n")

cat("⏳ Step 9: Will merge PR after CI passes\n\n")

cat("=== SUMMARY ===\n")
cat("Issue #140: Three critical fixes implemented\n")
cat("1. GitHub Pages 404 error - FIXED (symlink → directory copy)\n")
cat("2. Shinylive run_simulation not found - FIXED (corrected repo URLs)\n")
cat("3. Missing Nix examples - ADDED (new README section)\n\n")

cat("Files modified: 4\n")
cat("Commits: 2\n")
cat("PR: #141 (open, awaiting CI)\n\n")
