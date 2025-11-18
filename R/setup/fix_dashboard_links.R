# Fix Dashboard Links in _pkgdown.yml
# Date: 2024-11-18
# Issue: Dashboard links pointing to .html instead of / (directory)
#
# This script follows the 8-step mandatory workflow:
# 1. Create GitHub issue
# 2. Create dev branch
# 3. Make changes
# 4. Run all checks locally
# 5. Push to remote (triggers GitHub Actions)
# 6. Wait for GitHub Actions
# 7. Merge via PR
# 8. Log everything (this file!)

library(gh)
library(gert)
library(usethis)

# Step 1: Create GitHub issue
issue_response <- gh::gh(
  "POST /repos/JohnGavin/randomwalk/issues",
  title = "Fix: Dashboard links in _pkgdown.yml pointing to wrong URL",
  body = "## Problem
The dashboard is deployed correctly at `/articles/dashboard/` (directory) but the links in `_pkgdown.yml` point to `/articles/dashboard.html` (file that doesn't exist), causing 404 errors when users click navbar links.

## Solution
Change all references from `articles/dashboard.html` to `articles/dashboard/` in `_pkgdown.yml`:
- Home section link (line 14)
- Navbar articles menu link (line 25)

## Expected Result
Users clicking dashboard links from the website navbar or home page will successfully access the Shinylive dashboard at https://johngavin.github.io/randomwalk/articles/dashboard/

## Root Cause
The pkgdown workflow exports the Shinylive app to a directory (`docs/articles/dashboard/`) not a single HTML file, so links must point to the directory path."
)

issue_number <- issue_response$number
cat("✓ Created issue #", issue_number, "\n", sep = "")

# Step 2: Create development branch
branch_name <- paste0("fix-issue-", issue_number, "-dashboard-links")
usethis::pr_init(branch = branch_name)
cat("✓ Created branch:", branch_name, "\n")

# Step 3: Make changes (will be done via Edit tool)
# Edit _pkgdown.yml to change:
#   Line 14: href: articles/dashboard.html  →  href: articles/dashboard/
#   Line 25: href: articles/dashboard.html  →  href: articles/dashboard/

# Step 4: After changes, commit
# gert::git_add("_pkgdown.yml")
# gert::git_commit(paste0("Fix: Dashboard links pointing to directory not .html file (#", issue_number, ")"))

# Step 5: Run all checks locally
# devtools::document()
# devtools::test()
# devtools::check()
# pkgdown::build_site()

# Step 6: Push to remote
# usethis::pr_push()

# Step 7: Wait for GitHub Actions (manual verification)

# Step 8: Merge PR
# usethis::pr_merge_main()
# usethis::pr_finish()

cat("\n=== Next Steps ===\n")
cat("1. Edit _pkgdown.yml to fix links\n")
cat("2. Commit changes\n")
cat("3. Run checks (document, test, check, build_site)\n")
cat("4. Push to remote\n")
cat("5. Wait for GitHub Actions\n")
cat("6. Merge PR\n")
