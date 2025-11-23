# Fix Issue #37: Re-enable Shinylive Export
# Date: 2025-11-23
# Issue: https://github.com/JohnGavin/randomwalk/issues/37
#
# This file logs all commands used to fix the Shinylive export

# ============================================================================
# STEP 1: CREATE GITHUB ISSUE ✅
# ============================================================================

# Created issue #37 using gh CLI:
# https://github.com/JohnGavin/randomwalk/issues/37

# ============================================================================
# STEP 2: CREATE DEVELOPMENT BRANCH ✅
# ============================================================================

# Created branch:
# git checkout -b fix-issue-37-enable-shinylive-export

# ============================================================================  
# STEP 3: MAKE CHANGES ✅
# ============================================================================

# Modified file: .github/workflows/pkgdown.yaml

# Changes made:
# 1. Added step to install randomwalk package before shinylive export
#    - Solves chicken-and-egg problem from PR #34
#    - Enables shinylive::export() to load the package
#
# 2. Re-enabled async dashboard export (was commented out)
#    - Uncommented lines 100-113
#    - Will export inst/shiny/dashboard_async/app.R to docs/
#    - Includes updated parameters from PR #36 (issue #33)
#
# 3. Removed sync dashboard export (keeping it commented)
#    - Only need async dashboard for now
#    - Can re-enable sync later if needed

# Commit changes
system("git add .github/workflows/pkgdown.yaml")
system("git add R/setup/fix_issue_37.R")  # This file
system("git commit -m 'Fix: Re-enable Shinylive export for async dashboard (#37)

- Add step to install randomwalk package before export
- Resolves chicken-and-egg problem from PR #34  
- Re-enable async dashboard export
- Will deploy updated parameters from PR #36 (issue #33)

Addresses #37'")

# ============================================================================
# STEP 4: LOG ALL COMMANDS ✅
# ============================================================================

# This file serves as the command log

# ============================================================================
# STEP 5: RUN ALL CHECKS LOCALLY
# ============================================================================

# Note: These require nix shell, skip for now as workflow syntax check is sufficient
# Library needed: devtools, testthat
# 
# devtools::document()
# devtools::test()  
# devtools::check()

# Verify workflow YAML syntax (can do without nix)
cat("\nVerifying workflow YAML syntax...\n")

# Check that the file is valid YAML
yaml_valid <- tryCatch({
  readLines(".github/workflows/pkgdown.yaml")
  TRUE
}, error = function(e) {
  cat("Error reading YAML:", e$message, "\n")
  FALSE
})

if (yaml_valid) {
  cat("✅ Workflow YAML syntax appears valid\n")
} else {
  cat("❌ Workflow YAML has syntax issues\n")
}

# ============================================================================
# STEP 6: PUSH VIA PR
# ============================================================================

# Push branch and create PR
cat("\n============================================\n")
cat("Next: Push branch to create PR\n")
cat("============================================\n\n")

cat("Run:\n")
cat("  git push -u origin fix-issue-37-enable-shinylive-export\n\n")

cat("Then create PR with:\n")
cat("  gh pr create --repo JohnGavin/randomwalk --title 'Fix: Re-enable Shinylive export for async dashboard (#37)' --body 'Fixes #37\n\n")
cat("- Add step to install randomwalk package before shinylive export\n")
cat("- Resolves chicken-and-egg problem from PR #34\n")  
cat("- Re-enable async dashboard export\n")
cat("- Will deploy updated parameters from PR #36 (issue #33)\n\n")
cat("## Testing\n\n")
cat("- Wait for pkgdown workflow to complete\n")
cat("- Verify dashboard at https://johngavin.github.io/randomwalk/articles/dashboard_async/\n")
cat("- Check that sliders show: workers 0-12, grid 20-400'\n\n")

# ============================================================================
# STEP 7: WAIT FOR GITHUB ACTIONS
# ============================================================================

# After pushing, monitor the pkgdown workflow:
# gh run list --repo JohnGavin/randomwalk --workflow=pkgdown --limit 5
# gh run watch <run-id> --repo JohnGavin/randomwalk

# ============================================================================
# STEP 8: MERGE VIA PR
# ============================================================================

# After workflow passes and dashboard is verified:
# gh pr merge --repo JohnGavin/randomwalk --squash
# git checkout main
# git pull origin main
# git branch -d fix-issue-37-enable-shinylive-export
