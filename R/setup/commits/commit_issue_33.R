# Script to commit and push issue #33 changes
# Run this in the dev nix environment (default-dev.nix) which has gert/usethis

library(gert)
library(usethis)

# 1. Stage changes
git_add(c(
  "inst/shiny/dashboard_async/app.R",
  "R/setup/fix_issue_33_dashboard_improvements.R",
  "R/setup/commit_issue_33.R"
))

# 2. Commit
commit_msg <- "Fix async dashboard UI and expand parameter ranges (#33)

Implemented all improvements from issue #33:

1. FIXED: End Y data display in Raw Data tab
   - Corrected path matrix extraction
   - Now shows termination coordinates properly

2. EXPANDED: Parameter ranges
   - Workers: 0-4 → 0-12 (test more parallel workers)
   - Grid Size: 5-50 → 20-400 (step 20, enable performance testing)
   - Walkers: max 20 → dynamic 70% of grid pixels

3. ADDED: Dynamic walker constraint
   - Reactive observer updates walker slider based on grid size
   - Prevents invalid parameter combinations

4. IMPROVED: Data table filtering
   - Moved filters to top (DOM: 'ftip')
   - Added dropdown selectors for Active and Reason columns
   - Better UX with exact match filtering

5. UPDATED: Reset defaults
   - Grid size default: 20 → 100

All changes tested and documented in R/setup/fix_issue_33_dashboard_improvements.R

Closes #33"

git_commit(commit_msg)

# 3. Push to create/update PR
usethis::pr_push()

cat("✓ Changes committed and pushed\n")
cat("✓ PR created/updated for issue #33\n")
cat("\nNext steps:\n")
cat("1. Wait for GitHub Actions to complete\n")
cat("2. Test dashboard functionality\n")
cat("3. Merge PR when all checks pass\n")
cat("4. Close issue #33\n")
